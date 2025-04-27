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
    property var currentQuizAnswers: [] // To store selected answer indices (1-based)

    // Internal properties
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
                // Initialize currentQuizAnswers array with placeholders
                root.currentQuizAnswers = new Array(transformedQuiz.questions.length).fill(0);
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
                        function decodeAnswers(encoded, questionCount) {
                            let encoded_num = parseInt(encoded, 10);
                            let bin = encoded_num.toString(2);
                            // Pad with leading zeros to ensure 2 bits per question
                            while (bin.length < questionCount * 2) {
                                bin = "0" + bin;
                            }
                            let arr = [];
                            for (let i = 0; i < questionCount; ++i) {
                                let bits = bin.substr(i * 2, 2);
                                arr.push(parseInt(bits, 2) + 1);
                            }
                            return arr;
                        }

                        const questionCount = quizContent.quiz_content.length;
                        let selfAnswers = [];
                        let partnerAnswers = [];
                        //console.log("DEBUG: self_answer (int):", typeof(lastAnsweredQuiz.self_answer));
                        selfAnswers = decodeAnswers(lastAnsweredQuiz.self_answer, questionCount);
                        //console.log("DEBUG: self_answer (int):", typeof(selfAnswers));
        
                        //console.log("DEBUG: partner_answer (int):", lastAnsweredQuiz.partner_answer);
                        // If partner_answer is null or "null", fill with "Partner didn't answer"
                        let partnerDidntAnswer = lastAnsweredQuiz.partner_answer === null || lastAnsweredQuiz.partner_answer === "null";
                        if (!partnerDidntAnswer) {
                            partnerAnswers = decodeAnswers(lastAnsweredQuiz.partner_answer, questionCount);
                        }

                        const transformedResults = {
                            id: completedQuizId,
                            title: quizName,
                            questions: quizContent.quiz_content.map((question, index) => {
                                const questionText = question.content_data;
                                const selfIdx = (selfAnswers.length > index) ? selfAnswers[index] - 1 : -1;
                                const partnerIdx = (!partnerDidntAnswer && partnerAnswers.length > index) ? partnerAnswers[index] - 1 : -1;
                                const selfText = (selfIdx >= 0 && question.answers[selfIdx])
                                    ? question.answers[selfIdx].answer_content
                                    : "No answer";
                                const partnerText = partnerDidntAnswer
                                    ? "Partner didn't answer"
                                    : ((partnerIdx >= 0 && question.answers[partnerIdx])
                                        ? question.answers[partnerIdx].answer_content
                                        : "No answer");
                                return {
                                    question: questionText,
                                    self: selfText,
                                    partner: partnerText
                                };
                            })
                        };
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
                text: root.quizData ? root.quizData.title : "🤔 Loading Quiz..."
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
                text: "Question " + (root.questionIndex + 1) + " of " +
                      (root.quizData ? root.quizData.questions.length : 0)
                font.pixelSize: 16
                color: "#9ca3af"
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
                    text: root.quizData ? root.quizData.questions[root.questionIndex].question : ""
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
                            return root.currentQuizAnswers[root.questionIndex] === index + 1;
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
                                    // Store the 1-based index of the selected answer
                                    root.currentQuizAnswers[root.questionIndex] = index + 1;
                                    //console.log("Selected answer for question", root.questionIndex, ":", root.currentQuizAnswers[root.questionIndex]);

                                    // Check if all questions have been answered
                                    if (root.currentQuizAnswers.every(answer => answer !== 0)) {
                                        //console.log("All questions answered. Submitting quiz.");
                                        CallAPI.answerQuiz(root.jwtToken, root.quizData.id, root.currentQuizAnswers, function(success, response) {
                                            if (success) {
                                                //console.log("Quiz submitted successfully:", response);
                                                // Fetch completed quiz results after successful submission
                                                fetchCompletedQuizResults();
                                                root.quizCompleted = true; // Show completion view
                                            } else {
                                                //console.error("Failed to submit quiz:", response);
                                                // Handle submission failure (e.g., show an error message)
                                            }
                                        });
                                    } else {
                                        // Move to the next question if not all answered
                                        if (root.questionIndex < root.quizData.questions.length - 1) {
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
                    text: "Your Answers:"
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
                        }
                    }
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

