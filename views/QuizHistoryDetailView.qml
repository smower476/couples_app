import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Basic 6.2 // For Popup
import "CallAPI.js" as CallAPI // Import CallAPI

Item {
    id: root
    width: parent.width
    height: parent.height
    // color: "#121212" // Background color

    // Property to receive the raw answered quiz data item from the list
    property var rawAnsweredQuizData: null
    // Property to store the transformed data for display
    property var transformedQuizData: null
    // Property to receive the JWT token
    property string jwtToken: ""

    // Connections to react to property changes
    Connections {
        target: root
        function onRawAnsweredQuizDataChanged() {
            console.log("QuizHistoryDetailView: rawAnsweredQuizData changed. Re-fetching data.");
            fetchAndTransformQuizData();
        }
        function onJwtTokenChanged() {
            console.log("QuizHistoryDetailView: jwtToken changed. Re-fetching data if raw data exists.");
            if (root.rawAnsweredQuizData) { // Only refetch if we have quiz data
                fetchAndTransformQuizData();
            }
        }
    }

    // Helper to decode base10 answer to array of 1-based indices
    // Expects 'itemCount' which could be questionCount or questionCount * 2
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
        //console.log("DEBUG: decodeAnswers - encoded:", encoded, "binary:", bin, "itemCount:", itemCount);
        let arr = [];
        for (let i = 0; i < itemCount; ++i) {
            let bits = bin.substr(i * 2, 2);
            arr.push(parseInt(bits, 2) + 1); // 1-based index
        }
        return arr;
    }

    // Function to fetch quiz content and transform answered quiz data for display
    function fetchAndTransformQuizData() {
        console.log("QuizHistoryDetailView: fetchAndTransformQuizData called.");
        console.log("QuizHistoryDetailView: rawAnsweredQuizData:", JSON.stringify(root.rawAnsweredQuizData));
        if (!root.jwtToken || !root.rawAnsweredQuizData || !root.rawAnsweredQuizData.id) {
            console.error("QuizHistoryDetailView: Cannot fetch/transform data. Missing token or raw data.");
            root.transformedQuizData = null; // Ensure data is null if prerequisites are missing
            return;
        }

        const completedQuizId = root.rawAnsweredQuizData.id;
        const quizName = root.rawAnsweredQuizData.quiz_name || "Completed Quiz Results";
        console.log("QuizHistoryDetailView: Fetching content for quiz ID:", completedQuizId, "with token:", root.jwtToken);

        CallAPI.getQuizContent(root.jwtToken, completedQuizId, function(success, quizContent) {
            console.log("QuizHistoryDetailView: CallAPI.getQuizContent callback received. Success:", success);
            console.log("QuizHistoryDetailView: Received quizContent:", JSON.stringify(quizContent));
            if (success && quizContent && quizContent.quiz_content) {
                const questionCount = quizContent.quiz_content.length;
                console.log("QuizHistoryDetailView: Quiz content fetched successfully. Question count:", questionCount);
                let selfAnswers = [];
                let partnerAnswers = [];
                let yourGuesses = []; // Array to hold decoded guesses about partner's answers
                let partnerGuessesAboutSelf = []; // Array to hold partner's guesses about your answers
                let partnerCorrectGuesses = 0; // Counter for partner's correct guesses about your answers
                let yourCorrectGuesses = 0; // Counter for your correct guesses about partner's answers

                // Decode combined self answers and guesses from self_answer field
                console.log("DEBUG: self_answer (raw combined):", root.rawAnsweredQuizData.self_answer);
                if (root.rawAnsweredQuizData.self_answer !== null && root.rawAnsweredQuizData.self_answer !== undefined) {
                     // Decode expecting data for questionCount * 2 items
                    const combinedDecoded = decodeAnswers(root.rawAnsweredQuizData.self_answer, questionCount * 2);
                    // Split into self answers (first half) and guesses (second half)
                    selfAnswers = combinedDecoded.slice(0, questionCount);
                    yourGuesses = combinedDecoded.slice(questionCount);
                } else {
                    // If no self_answer, fill both with 0s
                    selfAnswers = new Array(questionCount).fill(0);
                    yourGuesses = new Array(questionCount).fill(0);
                }
                console.log("DEBUG: self_answer (decoded):", JSON.stringify(selfAnswers));
                console.log("DEBUG: your_guesses (decoded):", JSON.stringify(yourGuesses));


                // Decode combined partner answers and guesses from partner_answer field
                console.log("DEBUG: partner_answer (raw combined):", root.rawAnsweredQuizData.partner_answer);
                let partnerDidntAnswer = root.rawAnsweredQuizData.partner_answer === null || root.rawAnsweredQuizData.partner_answer === "null" || root.rawAnsweredQuizData.partner_answer === undefined;
                if (!partnerDidntAnswer) {
                    // Decode expecting data for questionCount * 2 items
                    const partnerCombinedDecoded = decodeAnswers(root.rawAnsweredQuizData.partner_answer, questionCount * 2);
                    // Split into partner answers (first half) and partner guesses about self (second half)
                    partnerAnswers = partnerCombinedDecoded.slice(0, questionCount);
                    partnerGuessesAboutSelf = partnerCombinedDecoded.slice(questionCount);
                } else {
                    // If no partner_answer, fill both with 0s
                    partnerAnswers = new Array(questionCount).fill(0);
                    partnerGuessesAboutSelf = new Array(questionCount).fill(0);
                }
                console.log("DEBUG: partner_answer (decoded):", JSON.stringify(partnerAnswers));
                console.log("DEBUG: partner_guesses_about_self (decoded):", JSON.stringify(partnerGuessesAboutSelf));


                // Calculate correctness
                let userGuessCorrect = new Array(questionCount).fill(false);
                let partnerGuessCorrect = new Array(questionCount).fill(false);

                for (let i = 0; i < questionCount; i++) {
                    // Check if your guess about partner's answer was correct
                    if (!partnerDidntAnswer && yourGuesses[i] > 0 && partnerAnswers[i] > 0) {
                        userGuessCorrect[i] = (yourGuesses[i] === partnerAnswers[i]);
                        if (userGuessCorrect[i]) {
                            yourCorrectGuesses++;
                        }
                    }

                    // Check if partner's guess about your answer was correct
                     if (!partnerDidntAnswer && partnerGuessesAboutSelf[i] > 0 && selfAnswers[i] > 0) {
                        partnerGuessCorrect[i] = (selfAnswers[i] === partnerGuessesAboutSelf[i]);
                        if (partnerGuessCorrect[i]) {
                            partnerCorrectGuesses++;
                        }
                    }
                }


                const transformedResults = {
                    id: completedQuizId,
                    title: quizName,
                    totalQuestions: questionCount,
                    quiz_content: quizContent.quiz_content, // Include the original quiz content structure
                    user_answer_decoded: selfAnswers, // Your answers
                    partner_answer_decoded: partnerAnswers, // Partner's answers
                    user_guess_decoded: yourGuesses, // Your guesses about partner
                    partner_guess_decoded: partnerGuessesAboutSelf, // Partner's guesses about you
                    user_guess_correct: userGuessCorrect, // Correctness of your guesses
                    partner_guess_correct: partnerGuessCorrect, // Correctness of partner's guesses
                    yourCorrectGuesses: yourCorrectGuesses, // Total correct guesses you made
                    partnerCorrectGuesses: partnerCorrectGuesses // Total correct guesses partner made
                };

                console.log("QuizHistoryDetailView: Transformed completed quiz data:", JSON.stringify(transformedResults, null, 2));
                root.transformedQuizData = transformedResults; // Set the transformed data
                console.log("QuizHistoryDetailView: root.transformedQuizData set.");

            } else {
                console.error("QuizHistoryDetailView: Failed to fetch quiz content for details or content is empty:", quizContent);
                root.transformedQuizData = null; // Clear data on failure
                console.log("QuizHistoryDetailView: root.transformedQuizData set to null.");
            }
        });
    }


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
                text: "📊 Quiz Results" // Changed header for history view
                font.pixelSize: 24
                font.bold: true
                color: "white"
                horizontalAlignment: Text.AlignHCenter
            }

            // Quiz Title (if available)
            Text {
                Layout.fillWidth: true
                text: root.transformedQuizData ? root.transformedQuizData.title || "Quiz Results" : "Loading Results..." // Use transformed data
                font.pixelSize: 20
                font.bold: true
                color: "white"
                horizontalAlignment: Text.AlignHCenter
                visible: root.transformedQuizData // Only show if data is available
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
                text: "Answers:" // Changed header
                font.pixelSize: 18
                font.bold: true
                color: "white"
            }

            // List of Questions and Answers (show both self and partner)
            Repeater {
                id: resultsRepeater
                model: root.transformedQuizData ? root.transformedQuizData.quiz_content : [] // Use quiz_content from transformed data

                delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: resultContentColumn.height + 20
                    color: "#1f1f1f"
                    radius: 5
                    Layout.bottomMargin: 10

                    property var questionObj: modelData // Each item in quiz_content

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
                            text: "Q: " + (questionObj.content_data || "") // Use content_data for question text
                            font.pixelSize: 14
                            color: "#e5e7eb"
                            wrapMode: Text.Wrap
                        }

                        // Display self answer (needs decoding from user_answer)
                        Text {
                            width: parent.width
                            text: "You: " + (root.transformedQuizData && root.transformedQuizData.user_answer_decoded && index < root.transformedQuizData.user_answer_decoded.length
                                            ? (root.transformedQuizData.user_answer_decoded[index] > 0 && questionObj.answers[root.transformedQuizData.user_answer_decoded[index] - 1]
                                                ? questionObj.answers[root.transformedQuizData.user_answer_decoded[index] - 1].answer_content
                                                : "No answer")
                                            : "Loading...")
                            font.pixelSize: 14
                            color: "white"
                            font.bold: true
                            wrapMode: Text.Wrap
                            topPadding: 4
                        }
 
                        // Display partner answer (needs decoding from partner_answer)
                        Text {
                            width: parent.width
                            text: "Partner: " + (root.transformedQuizData && root.transformedQuizData.partner_answer_decoded && index < root.transformedQuizData.partner_answer_decoded.length
                                            ? (root.transformedQuizData.partner_answer_decoded[index] > 0 && questionObj.answers[root.transformedQuizData.partner_answer_decoded[index] - 1]
                                                ? questionObj.answers[root.transformedQuizData.partner_answer_decoded[index] - 1].answer_content
                                                : "No answer")
                                            : "Loading...")
                            font.pixelSize: 14
                            color: "#ec4899"
                            font.bold: true
                            wrapMode: Text.Wrap
                            topPadding: 2
                        }
 
                        // Display your guess about partner's answer (needs decoding from user_answer)
                        Text {
                            width: parent.width
                            text: "Your Guess: " + (root.transformedQuizData && root.transformedQuizData.user_guess_decoded && index < root.transformedQuizData.user_guess_decoded.length
                                            ? (root.transformedQuizData.user_guess_decoded[index] > 0 && questionObj.answers[root.transformedQuizData.user_guess_decoded[index] - 1]
                                                ? questionObj.answers[root.transformedQuizData.user_guess_decoded[index] - 1].answer_content
                                                : "No guess")
                                            : "Loading...")
                            font.pixelSize: 14
                            color: {
                                // Color based on whether your guess about partner's answer was correct
                                if (!root.transformedQuizData || !root.transformedQuizData.user_guess_correct || index >= root.transformedQuizData.user_guess_correct.length) return "#9ca3af"; // Gray if no data
                                return root.transformedQuizData.user_guess_correct[index] ? "#4ade80" : "#f87171"; // Green if correct, Red if incorrect
                            }
                            font.bold: true
                            wrapMode: Text.Wrap
                            topPadding: 2
                            visible: root.transformedQuizData && root.transformedQuizData.user_guess_decoded // Only show if guess data is available
                        }
 
                        // Display partner's guess about your answer (needs decoding from partner_answer)
                        Text {
                            width: parent.width
                            text: "Partner's Guess: " + (root.transformedQuizData && root.transformedQuizData.partner_guess_decoded && index < root.transformedQuizData.partner_guess_decoded.length
                                            ? (root.transformedQuizData.partner_guess_decoded[index] > 0 && questionObj.answers[root.transformedQuizData.partner_guess_decoded[index] - 1]
                                                ? questionObj.answers[root.transformedQuizData.partner_guess_decoded[index] - 1].answer_content
                                                : "No guess")
                                            : "Loading...")
                            font.pixelSize: 14
                            color: {
                                // Color based on whether partner's guess about your answer was correct
                                if (!root.transformedQuizData || !root.transformedQuizData.partner_guess_correct || index >= root.transformedQuizData.partner_guess_correct.length) return "#9ca3af"; // Gray if no data
                                return root.transformedQuizData.partner_guess_correct[index] ? "#4ade80" : "#f87171"; // Green if correct, Red if incorrect
                            }
                            font.bold: true
                            wrapMode: Text.Wrap
                            topPadding: 2
                            visible: root.transformedQuizData && root.transformedQuizData.partner_guess_decoded // Only show if guess data is available
                        }
                    }
                }
            }
 
            // Add overall score display
            Text {
                id: scoreText
                Layout.fillWidth: true
                text: {
                    if (root.transformedQuizData && root.transformedQuizData.hasOwnProperty('yourCorrectGuesses') && root.transformedQuizData.hasOwnProperty('partnerCorrectGuesses') && root.transformedQuizData.hasOwnProperty('totalQuestions')) {
                       const total = root.transformedQuizData.totalQuestions;
                       const yourScore = root.transformedQuizData.yourCorrectGuesses;
                       const partnerScore = root.transformedQuizData.partnerCorrectGuesses;
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
                visible: !root.transformedQuizData || !root.transformedQuizData.quiz_content || root.transformedQuizData.quiz_content.length === 0
            }
 
            // Back button (optional, depending on navigation structure)
            Button {
                Layout.alignment: Qt.AlignCenter
                Layout.topMargin: 20
                text: "Back to Hub"
                onClicked: {
                    window.currentView = "hub"; // Change view to hub
                }
            }
 
            // Bottom padding
            Item { Layout.preferredHeight: 20 }
        }
    }
 
    Component.onCompleted: {
        //console.log("QuizHistoryDetailView: Component onCompleted. Raw data:", JSON.stringify(root.rawAnsweredQuizData));
        fetchAndTransformQuizData();
    }
}