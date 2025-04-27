import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Basic 6.2 // For Popup
import "CallAPI.js" as CallAPI

Item {
    id: root
    width: parent.width
    height: parent.height

    // Properties passed from main.qml
    property var quizData: null
    property int questionIndex: 0
    property var responses: []
    property var currentQuizAnswers: [] // To store selected answer indices (1-based) for self
    property var partnerGuesses: []     // To store selected answer indices (1-based) for partner guess

    // Internal properties
    property string quizPhase: "answeringSelf" // "answeringSelf", "guessingPartner"
    property string apiKey_: ""
    property string jwtToken: ""

    // Properties for completion state
    property bool quizCompleted: false
    property var completedQuizData: null

    // Signals
    signal quizFetched(var quizData)
    signal quizResponse(string question, string response)
    signal completionAcknowledged()

    // Connections to react to property changes on this component (root)
    Connections {
        target: root

        function onJwtTokenChanged() {
            //console.log("QuizzesView: jwtToken changed. Fetching quiz if not completed.");
            if (root.jwtToken && !root.quizCompleted) {
                fetchDailyQuiz();
            } else {
                //console.log("QuizzesView: jwtToken cleared or quiz already completed.");
            }
        }
    }

    // Function to fetch and process the daily quiz
    function fetchDailyQuiz() {
        //console.log("QuizzesView: Fetching daily quiz with token:", root.jwtToken);
        getNewQuiz(function (quizContent, quizId) {
            if (quizContent && quizContent.quiz_content && quizContent.quiz_content.length > 0) {
                var transformedQuiz = {
                    id: quizId || "daily_quiz_" + new Date().getTime(),
                    title: quizContent.quiz_name || "Daily Quiz",
                    questions: quizContent.quiz_content.map((item, index) => {
                        return {
                            question: item.content_data,
                            options: item.answers.map(ans => ans.answer_content),
                            _answers: item.answers,
                            _content_id: item.content_id
                        };
                    })
                };
                //console.log("Transformed Quiz:", JSON.stringify(transformedQuiz));
                root.quizFetched(transformedQuiz);
                // Initialize answer arrays with placeholders
                const numQuestions = transformedQuiz.questions.length;
                root.currentQuizAnswers = new Array(numQuestions).fill(0);
                root.partnerGuesses = new Array(numQuestions).fill(0);
                root.quizPhase = "answeringSelf"; // Reset phase on new quiz
            } else {
                //console.error("Failed to process quiz content or quiz_content is empty:", quizContent);
                root.quizFetched(null);
            }
        });
    }

    function getNewQuiz(callback) {
        CallAPI.getDailyQuizId(root.jwtToken, function(success, quizId) {
            if (success) {
                //console.log("Daily Quiz ID:", quizId);
                if (quizId === "done") {
                    //console.log("Quiz already completed today.");
                    root.quizCompleted = true;
                    // Fetch completed quiz data if already done
                    fetchCompletedQuizResults();
                    return;
                }
                CallAPI.getQuizContent(root.jwtToken, quizId, function(success, quizContent) {
                    if (success) {
                        //console.log("Quiz content:", quizContent);
                        callback(quizContent, quizId);
                    } else {
                        //console.error("Failed to get quiz content:", quizContent);
                    }
                });
            } else {
                //console.error("Failed to get daily quiz ID:", quizId);
            }
        });
    }

    function fetchCompletedQuizResults() {
        if (!root.jwtToken) {
            //console.error("Cannot fetch completed quiz results: JWT token is missing.");
            return;
        }
        CallAPI.getAnsweredQuizzes(root.jwtToken, function(success, answeredQuizzes) {
            if (success && answeredQuizzes.length > 0) {
                // Use the last answered quiz
                const lastAnsweredQuiz = answeredQuizzes[answeredQuizzes.length - 1];
                const completedQuizId = lastAnsweredQuiz.id || lastAnsweredQuiz.quiz_id;
                const quizName = lastAnsweredQuiz.quiz_name || "Completed Quiz Results";
                // Fetch the content of the completed quiz
                CallAPI.getQuizContent(root.jwtToken, completedQuizId, function(success, quizContent) {
                    if (success && quizContent && quizContent.quiz_content) {
                        // Helper to decode base10 answer to array of 1-based indices
                        // Now expects 'itemCount' which could be questionCount or questionCount * 2
                        function decodeAnswers(encoded, itemCount) {
                            let encoded_num = parseInt(encoded, 10);
                            if (isNaN(encoded_num)) {
                                //console.error("decodeAnswers: Invalid encoded value", encoded);
                                return new Array(itemCount).fill(0); // Return array of 0s on error
                            }
                            let bin = encoded_num.toString(2);
                            const expectedBits = itemCount * 2;
                            // Pad with leading zeros to ensure 2 bits per item
                            while (bin.length < expectedBits) {
                                bin = "0" + bin;
                            }
                            // Truncate if too long (shouldn't happen with correct padding)
                            if (bin.length > expectedBits) {
                                bin = bin.substr(bin.length - expectedBits);
                            }
                            console.log("DEBUG: decodeAnswers - encoded:", encoded, "binary:", bin, "itemCount:", itemCount);
                            let arr = [];
                            for (let i = 0; i < itemCount; ++i) {
                                let bits = bin.substr(i * 2, 2);
                                arr.push(parseInt(bits, 2) + 1); // 1-based index
                            }
                            return arr;
                        }

                        const questionCount = quizContent.quiz_content.length;
                        let selfAnswers = [];
                        let partnerAnswers = [];
                        let yourGuesses = []; // Array to hold decoded guesses about partner's answers
                        let partnerGuessesAboutSelf = []; // Array to hold partner's guesses about your answers
                        let partnerCorrectGuesses = 0; // Counter for partner's correct guesses about your answers
                        let yourCorrectGuesses = 0; // Counter for your correct guesses about partner's answers

                        // Decode combined self answers and guesses from self_answer field
                        //console.log("DEBUG: self_answer (raw combined):", lastAnsweredQuiz.self_answer);
                        if (lastAnsweredQuiz.self_answer) {
                            // Decode expecting data for questionCount * 2 items
                            const combinedDecoded = decodeAnswers(lastAnsweredQuiz.self_answer, questionCount * 2);
                            // Split into self answers (first half) and guesses (second half)
                            selfAnswers = combinedDecoded.slice(0, questionCount);
                            yourGuesses = combinedDecoded.slice(questionCount);
                        } else {
                            // If no self_answer, fill both with 0s
                            selfAnswers = new Array(questionCount).fill(0);
                            yourGuesses = new Array(questionCount).fill(0);
                        }
                        //console.log("DEBUG: self_answer (decoded):", JSON.stringify(selfAnswers));
                        //console.log("DEBUG: your_guesses (decoded):", JSON.stringify(yourGuesses));

                        // Decode combined partner answers and guesses from partner_answer field
                        //console.log("DEBUG: partner_answer (raw combined):", lastAnsweredQuiz.partner_answer);
                        let partnerDidntAnswer = lastAnsweredQuiz.partner_answer === null || lastAnsweredQuiz.partner_answer === "null" || lastAnsweredQuiz.partner_answer === undefined;
                        if (!partnerDidntAnswer) {
                            // Decode expecting data for questionCount * 2 items
                            const partnerCombinedDecoded = decodeAnswers(lastAnsweredQuiz.partner_answer, questionCount * 2);
                            // Split into partner answers (first half) and partner guesses about self (second half)
                            partnerAnswers = partnerCombinedDecoded.slice(0, questionCount);
                            partnerGuessesAboutSelf = partnerCombinedDecoded.slice(questionCount);
                        } else {
                            // If no partner_answer, fill both with 0s
                            partnerAnswers = new Array(questionCount).fill(0);
                            partnerGuessesAboutSelf = new Array(questionCount).fill(0);
                        }
                        //console.log("DEBUG: partner_answer (decoded):", JSON.stringify(partnerAnswers));
                        //console.log("DEBUG: partner_guesses_about_self (decoded):", JSON.stringify(partnerGuessesAboutSelf));

                        // We no longer need a separate 'didNotGuess' flag based on a separate field,
                        // as guesses are now part of the main answer field.
                        // We determine if a guess exists by checking the decoded yourGuesses array.

                        const transformedResults = {
                            id: completedQuizId,
                            title: quizName,
                            totalQuestions: questionCount, // Store total questions
                            correctGuesses: 0, // Initialize score
                            questions: quizContent.quiz_content.map((question, index) => {
                                const questionText = question.content_data;

                                // Get self answer text
                                const selfIdx = (selfAnswers.length > index) ? selfAnswers[index] - 1 : -1;
                                const selfText = (selfIdx >= 0 && question.answers[selfIdx])
                                    ? question.answers[selfIdx].answer_content
                                    : "No answer";

                                // Get partner's actual answer text
                                const partnerIdx = (!partnerDidntAnswer && partnerAnswers.length > index) ? partnerAnswers[index] - 1 : -1;
                                const partnerText = partnerDidntAnswer
                                    ? "Partner didn't answer"
                                    : ((partnerIdx >= 0 && question.answers[partnerIdx])
                                        ? question.answers[partnerIdx].answer_content
                                        : "No answer");

                                // Get your guess text (using decoded yourGuesses array)
                                let yourGuessText = "No guess"; // Default
                                const yourGuessValue = (yourGuesses.length > index) ? yourGuesses[index] : 0; // Get the decoded guess (1-4, or 0 if missing)
                                if (yourGuessValue > 0) { // Check if a valid guess (1-4) exists
                                    const yourGuessIdx = yourGuessValue - 1;
                                    if (yourGuessIdx >= 0 && question.answers[yourGuessIdx]) {
                                        yourGuessText = question.answers[yourGuessIdx].answer_content;
                                    }
                                    // If yourGuessIdx is invalid, yourGuessText remains "No guess"
                                }

                                // Get partner's guess about your answer text
                                let partnerGuessAboutSelfText = "No guess"; // Default
                                const partnerGuessValue = (partnerGuessesAboutSelf.length > index) ? partnerGuessesAboutSelf[index] : 0; // Get the decoded guess (1-4, or 0 if missing)
                                const partnerGuessed = partnerGuessValue > 0;
                                if (partnerGuessed) { // Check if a valid guess (1-4) exists
                                    const partnerGuessIdx = partnerGuessValue - 1;
                                    if (partnerGuessIdx >= 0 && question.answers[partnerGuessIdx]) {
                                        partnerGuessAboutSelfText = question.answers[partnerGuessIdx].answer_content;
                                    }
                                    // If partnerGuessIdx is invalid, partnerGuessAboutSelfText remains "No guess"
                                }


                                // Check if partner's guess about your answer was correct
                                let partnerGuessCorrect = false;
                                // Ensure partner answered, a valid guess exists, and arrays have data for this index
                                if (!partnerDidntAnswer && partnerGuessValue > 0 && selfAnswers.length > index && partnerGuessesAboutSelf.length > index) {
                                    partnerGuessCorrect = (selfAnswers[index] === partnerGuessesAboutSelf[index]);
                                    if (partnerGuessCorrect) {
                                        partnerCorrectGuesses++; // Increment partner's overall score
                                    }
                                }

                                // Check if your guess about partner's answer was correct
                                let yourGuessCorrect = false;
                                // Ensure partner answered, a valid guess exists, and arrays have data for this index
                                if (!partnerDidntAnswer && yourGuessValue > 0 && partnerAnswers.length > index && yourGuesses.length > index) {
                                    yourGuessCorrect = (yourGuesses[index] === partnerAnswers[index]);
                                    if (yourGuessCorrect) {
                                        yourCorrectGuesses++; // Increment your overall score
                                    }
                                }


                                return {
                                    question: questionText,
                                    self: selfText,
                                    partner: partnerText,
                                    yourGuess: yourGuessText, // Your guess about partner's answer
                                    yourGuessCorrect: yourGuessCorrect, // Was your guess about partner's answer correct?
                                    partnerGuessAboutSelf: partnerGuessAboutSelfText, // Partner's guess about your answer
                                    partnerGuessCorrect: partnerGuessCorrect // Was partner's guess about your answer correct?
                                };
                            })
                        };
                        // Add final scores to the results object
                        transformedResults.partnerCorrectGuesses = partnerCorrectGuesses; // How many of your answers your partner guessed correctly
                        transformedResults.yourCorrectGuesses = yourCorrectGuesses; // How many of partner's answers you guessed correctly

                        root.completedQuizData = transformedResults;
                        //console.log("Fetched and transformed completed quiz data:", JSON.stringify(root.completedQuizData, null, 2));
                    } else {
                        //console.error("Failed to fetch content for completed quiz:", quizContent);
                        root.completedQuizData = null;
                    }
                });
            } else {
                //console.error("Failed to fetch completed quizzes or no answered quizzes found:", answeredQuizzes);
                root.completedQuizData = null;
            }
        });
    }

    // Main content area - modified to use Item instead of ScrollView for more control
    Item {
        id: mainContentArea
        anchors.fill: parent
        visible: !root.quizCompleted

        // Header
        Rectangle {
            id: quizHeader
            width: parent.width
            height: 60
            color: "transparent"
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }

            Text {
                anchors.centerIn: parent
                text: {
                    if (!root.quizData) return "🤔 Loading Quiz...";
                    if (root.quizPhase === "answeringSelf") return root.quizData.title;
                    return "🤔 Guess Partner's Answers"; // Title for guessing phase
                }
                font.pixelSize: 24
                font.bold: true
                color: "white"
            }
        }

        // Question progress
        Rectangle {
            id: questionProgress
            width: parent.width
            height: 30
            color: "transparent"
            anchors {
                top: quizHeader.bottom
                left: parent.left
                right: parent.right
            }

            Text {
                anchors.centerIn: parent
                text: {
                    const totalQuestions = root.quizData ? root.quizData.questions.length : 0;
                    const currentQ = root.questionIndex + 1;
                    if (root.quizPhase === "answeringSelf") {
                        return "Question " + currentQ + " of " + totalQuestions;
                    } else {
                        return "Guessing Partner: Question " + currentQ + " of " + totalQuestions;
                    }
                }
                font.pixelSize: 16
                color: root.quizPhase === "answeringSelf" ? "#9ca3af" : "#f0abfc" // Different color for guessing phase
            }
        }

        // Temporary Quiz ID display
        Text {
            id: quizIdDisplay
            anchors {
                centerIn: parent
            }
            horizontalAlignment: Text.AlignHCenter
            color: "yellow"
            font.pixelSize: 14
            text: root.quizData ? "Quiz ID: " + root.quizData.id : ""
        }

        // Question container with scrolling for long questions
        ScrollView {
            id: questionScrollView
            anchors {
                top: questionProgress.bottom
                left: parent.left
                right: parent.right
                bottom: answerContainer.top
                leftMargin: 16
                rightMargin: 16
                topMargin: 10
                bottomMargin: 10
            }
            clip: true
            contentWidth: width

            Rectangle {
                width: questionScrollView.width
                height: questionText.implicitHeight + 40 // Add some padding
                color: "#1f1f1f"
                radius: 8

                Text {
                    id: questionText
                    anchors {
                        fill: parent
                        margins: 20
                    }
                    text: {
                        if (!root.quizData) return "";
                        const baseQuestion = root.quizData.questions[root.questionIndex].question;
                        if (root.quizPhase === "answeringSelf") {
                            return baseQuestion;
                        } else {
                            // Add prompt for guessing phase
                            return "What do you think your partner answered?\n\n" + baseQuestion;
                        }
                    }
                    font.pixelSize: 20
                    color: "white"
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        // Answer container - positioned at the bottom for easy thumb reach
        Rectangle {
            id: answerContainer
            width: parent.width
            color: "transparent"
            // Fixed at the bottom of the screen
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                bottomMargin: 20
            }
            // Dynamic height based on content
            height: Math.min(answerColumn.implicitHeight + 20, parent.height * 0.6)

            ColumnLayout {
                id: answerColumn
                anchors {
                    fill: parent
                    margins: 10
                }
                spacing: 12 // Reduced spacing for more compact layout

                Repeater {
                    model: root.quizData ? root.quizData.questions[root.questionIndex].options : []

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(answerText.implicitHeight + 24, 80) // Slightly taller for easier tapping
                        Layout.maximumHeight: 80
                        radius: 12 // Increased radius to match DateIdeasView
                        color: "#1f1f1f" // gray-800
                        Layout.alignment: Qt.AlignHCenter // Center in the list

                        property bool isSelected: {
                            if (!root.quizData || !root.currentQuizAnswers) return false;
                            // Check if the stored answer index for this question matches this option's index + 1
                            if (root.quizPhase === "answeringSelf") {
                                return root.currentQuizAnswers[root.questionIndex] === index + 1;
                            } else {
                                return root.partnerGuesses[root.questionIndex] === index + 1;
                            }
                        }

                        // Colored border based on selection status
                        Rectangle {
                            id: answerBorder
                            anchors.fill: parent
                            z: -1
                            radius: 14 // Slightly larger than parent for border effect
                            gradient: Gradient {
                                GradientStop {
                                    position: 0.0
                                    color: isSelected ? "#ec4899" : "#4b5563" // pink-600 : gray-600
                                }
                                GradientStop {
                                    position: 1.0
                                    color: isSelected ? "#db2777" : "#374151" // pink-700 : gray-700
                                }
                            }
                            anchors.margins: -2 // Creates border effect
                        }

                        Text {
                            id: answerText
                            anchors {
                                fill: parent
                                margins: 12 // Increased padding for answer text
                            }
                            text: modelData
                            font.pixelSize: 16 // Slightly larger text
                            font.bold: isSelected // Bold when selected
                            color: "white"
                            wrapMode: Text.Wrap
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (root.quizData) {
                                    const numQuestions = root.quizData.questions.length;
                                    const currentQIndex = root.questionIndex;
                                    const selectedAnswerIndex = index + 1;

                                    if (root.quizPhase === "answeringSelf") {
                                        // Store self answer
                                        root.currentQuizAnswers[currentQIndex] = selectedAnswerIndex;
                                        //console.log("Self answer for Q", currentQIndex, ":", selectedAnswerIndex);

                                        // Check if this was the last question for self
                                        if (currentQIndex === numQuestions - 1) {
                                            // Transition to guessing phase
                                            root.quizPhase = "guessingPartner";
                                            root.questionIndex = 0; // Reset for guessing
                                            //console.log("Transitioning to guessing phase");
                                        } else {
                                            // Move to next question for self
                                            root.questionIndex++;
                                        }
                                    } else { // quizPhase === "guessingPartner"
                                        // Store partner guess
                                        root.partnerGuesses[currentQIndex] = selectedAnswerIndex;
                                        //console.log("Partner guess for Q", currentQIndex, ":", selectedAnswerIndex);

                                        // Check if this was the last question for guessing
                                        if (currentQIndex === numQuestions - 1) {
                                            // All guesses are done, submit both sets of answers
                                            //console.log("All guesses complete. Submitting quiz.");
                                            //console.log("Self Answers:", JSON.stringify(root.currentQuizAnswers));
                                            //console.log("Partner Guesses:", JSON.stringify(root.partnerGuesses));

                                            // *** TODO: Update CallAPI.answerQuiz to accept partnerGuesses ***
                                            CallAPI.answerQuiz(root.jwtToken, root.quizData.id, root.currentQuizAnswers, root.partnerGuesses, function(success, response) {
                                                if (success) {
                                                    //console.log("Quiz submitted successfully:", response);
                                                    // Fetch completed quiz results after successful submission
                                                    fetchCompletedQuizResults(); // This might need updates too
                                                    root.quizCompleted = true; // Show completion view
                                                } else {
                                                    //console.error("Failed to submit quiz:", response);
                                                    // Handle submission failure (e.g., show an error message)
                                                }
                                            });
                                        } else {
                                            // Move to next question for guessing
                                            root.questionIndex++;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Spacer to push items up from bottom navigation
                Item {
                    Layout.preferredHeight: 5
                }
            }
        }
    }

    // Quiz Completion View
    Rectangle {
        id: quizCompletedView
        anchors.fill: parent
        color: "#121212"
        visible: root.quizCompleted

        // Border to match the app styling
        Rectangle {
            anchors.fill: parent
            anchors.margins: 10
            color: "transparent"
            border.color: "#ec4899" // Pink border
            border.width: 1
            radius: 10
        }

        ScrollView {
            anchors.fill: parent
            anchors.margins: 20
            contentWidth: parent.width - 40
            clip: true

            ColumnLayout {
                width: parent.width
                spacing: 15

                // Header
                Text {
                    Layout.fillWidth: true
                    text: "🎉 Congratulations! 🎉"
                    font.pixelSize: 24
                    font.bold: true
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    Layout.fillWidth: true
                    text: "You've completed the Daily Quiz!"
                    font.pixelSize: 16
                    color: "#d1d5db" // gray-300
                    horizontalAlignment: Text.AlignHCenter
                }

                // Quiz Title (if available)
                Text {
                    Layout.fillWidth: true
                    text: root.completedQuizData ? root.completedQuizData.title : "Quiz Results"
                    font.pixelSize: 20
                    font.bold: true
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    visible: root.completedQuizData && root.completedQuizData.title
                    Layout.topMargin: 10
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: "#4b5563" // gray-600
                    Layout.topMargin: 10
                    Layout.bottomMargin: 10
                }

                // Results List Header
                Text {
                    Layout.fillWidth: true
                    text: "Quiz Results:" // Changed header
                    font.pixelSize: 18
                    font.bold: true
                    color: "white"
                }

                // List of Questions and Answers (show both self and partner)
                Repeater {
                    id: resultsRepeater
                    model: root.completedQuizData ? root.completedQuizData.questions : []

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: resultContentColumn.height + 20
                        color: "#1f1f1f"
                        radius: 5
                        Layout.bottomMargin: 10

                        property var questionObj: modelData

                        Column {
                            id: resultContentColumn
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: 10
                            }
                            spacing: 4

                            Text {
                                width: parent.width
                                text: "Q: " + (questionObj.question || "")
                                font.pixelSize: 14
                                color: "#e5e7eb"
                                wrapMode: Text.Wrap
                            }

                            Text {
                                width: parent.width
                                text: "You: " + (questionObj.self || "No answer")
                                font.pixelSize: 14
                                color: "white"
                                font.bold: true
                                wrapMode: Text.Wrap
                                topPadding: 4
                            }

                            Text {
                                width: parent.width
                                text: "Partner: " + (questionObj.partner || "No answer")
                                font.pixelSize: 14
                                color: "#ec4899"
                                font.bold: true
                                wrapMode: Text.Wrap
                                topPadding: 2
                            }
                            // Add display for partner's guess about your answer and correctness
                            Text {
                                width: parent.width
                                text: "Your Guess: " + (questionObj.yourGuess || "No guess") // Display partner's guess about your answer
                                font.pixelSize: 14
                                color: {
                                    // Color based on whether partner's guess about your answer was correct
                                    if (!questionObj.yourGuess || questionObj.yourGuess === "No guess") return "#9ca3af"; // Gray if no guess
                                    return questionObj.guessCorrect ? "#4ade80" : "#f87171"; // Green if correct, Red if incorrect
                                }
                                font.bold: true
                                wrapMode: Text.Wrap
                                topPadding: 2
                                visible: questionObj.hasOwnProperty('yourGuess') // Only show if partner guess data is available
                            }
                            // Add display for partner's guess about your answer and correctness
                            Text {
                                width: parent.width
                                text: "Partners Guess: " + (questionObj.partnerGuessAboutSelf || "No guess") // Display partner's guess about your answer
                                font.pixelSize: 14
                                color: {
                                    // Color based on whether partner's guess about your answer was correct
                                    if (!questionObj.partnerGuessAboutSelf || questionObj.partnerGuessAboutSelf === "No guess") return "#9ca3af"; // Gray if no guess
                                    return questionObj.partnerGuessCorrect ? "#4ade80" : "#f87171"; // Green if correct, Red if incorrect
                                }
                                font.bold: true
                                wrapMode: Text.Wrap
                                topPadding: 2
                                visible: questionObj.hasOwnProperty('partnerGuessAboutSelf') // Only show if partner guess data is available
                            }
                        }
                    }
                }

                // Add overall score display
                Text {
                    id: scoreText
                    Layout.fillWidth: true
                    text: {
                        if (root.completedQuizData && root.completedQuizData.hasOwnProperty('yourCorrectGuesses') && root.completedQuizData.hasOwnProperty('partnerCorrectGuesses') && root.completedQuizData.hasOwnProperty('totalQuestions')) {
                           const total = root.completedQuizData.totalQuestions;
                           const yourScore = root.completedQuizData.yourCorrectGuesses;
                           const partnerScore = root.completedQuizData.partnerCorrectGuesses;
                           return "Your Guesses Correct: " + yourScore + "/" + total + "\nPartner's Guesses Correct: " + partnerScore + "/" + total;
                        }
                        return ""; // Don't show if data isn't ready
                    }
                    font.pixelSize: 16
                    color: "#a5b4fc" // Indigo-300
                    horizontalAlignment: Text.AlignHCenter
                    Layout.topMargin: 15
                    visible: text !== "" // Only show when score is calculated
                }

                // Fallback text when there are no answers to display
                Text {
                    Layout.fillWidth: true
                    text: "No answers available."
                    font.pixelSize: 14
                    color: "#9ca3af" // gray-400
                    horizontalAlignment: Text.AlignHCenter
                    visible: !root.completedQuizData || root.completedQuizData.questions.length === 0
                }

                // Additional encouraging text
                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 20
                    text: "Come back tomorrow for a new quiz!"
                    font.pixelSize: 16
                    color: "#ec4899" // Pink text
                    horizontalAlignment: Text.AlignHCenter
                }

                // Bottom padding
                Item { Layout.preferredHeight: 20 }
            }
        }
    }
}

