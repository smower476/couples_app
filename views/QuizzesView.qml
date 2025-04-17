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

    // Component initialization logic
    Component.onCompleted: {
        // Only fetch new quiz if not already completed
        if (root.jwtToken && !root.quizCompleted) {
            fetchDailyQuiz();
        } else {
            console.log("QuizzesView: JWT token not available or quiz already completed.");
        }
    }

    // Connections to react to property changes on this component (root)
    Connections {
        target: root

        function onJwtTokenChanged() {
            console.log("QuizzesView: jwtToken changed. Fetching quiz if not completed.");
            if (root.jwtToken && !root.quizCompleted) {
                fetchDailyQuiz();
            } else {
                console.log("QuizzesView: jwtToken cleared or quiz already completed.");
            }
        }
    }

    // Function to fetch and process the daily quiz
    function fetchDailyQuiz() {
        console.log("QuizzesView: Fetching daily quiz with token:", root.jwtToken);
        getNewQuiz(function (quizContent) {
            if (quizContent && quizContent.quiz_content && quizContent.quiz_content.length > 0) {
                var transformedQuiz = {
                    id: quizContent.quiz_content[0].content_id || "daily_quiz_" + new Date().getTime(),
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
                console.log("Transformed Quiz:", JSON.stringify(transformedQuiz));
                root.quizFetched(transformedQuiz);
            } else {
                console.error("Failed to process quiz content or quiz_content is empty:", quizContent);
                root.quizFetched(null);
            }
        });
    }

    function getNewQuiz(callback) {
        CallAPI.getDailyQuizId(root.jwtToken, function(success, quizId) {
            if (success) {
                console.log("Daily Quiz ID:", quizId);
                CallAPI.getQuizContent(root.jwtToken, quizId, function(success, quizContent) {
                    if (success) {
                        console.log("Quiz content:", quizContent);
                        callback(quizContent);
                    } else {
                        console.error("Failed to get quiz content:", quizContent);
                    }
                });
            } else {
                console.error("Failed to get daily quiz ID:", quizId);
            }
        });
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        contentWidth: parent.width
        clip: true

        // The entire ScrollView is only visible when NOT in completed state
        visible: !root.quizCompleted

        ColumnLayout {
            width: parent.width
            spacing: 16

            // Header
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                color: "transparent"

                Text {
                    anchors.centerIn: parent
                    text: root.quizData ? root.quizData.title : "🤔 Loading Quiz..."
                    font.pixelSize: 24
                    font.bold: true
                    color: "white"
                }
            }

            // Quiz question (visible when a quiz is loaded AND not completed)
            Rectangle {
                Layout.fillWidth: true
                Layout.margins: 16
                Layout.fillHeight: true
                color: "#1f1f1f"
                radius: 8
                visible: root.quizData !== null && !root.quizCompleted

                ColumnLayout {
                    id: questionColumn
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 16
                    }

                    Text {
                        text: "Question " + (root.questionIndex + 1) + " of "
                              + (root.quizData ? root.quizData.questions.length : 0)
                        font.pixelSize: 16
                        color: "#9ca3af"
                    }

                    Item {
                        Layout.fillHeight: true
                    }

                    Text {
                        text: root.quizData ? root.quizData.questions[root.questionIndex].question : ""
                        font.pixelSize: 20
                        color: "white"
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 24
                        Repeater {
                            model: root.quizData ? root.quizData.questions[root.questionIndex].options : []

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: Math.min(answerText.implicitHeight + 20, 100)
                                Layout.maximumHeight: 100
                                radius: 4

                                property bool isSelected: {
                                    if (!root.quizData || !root.responses) return false;
                                    var quizResponseObj = root.responses.find(r => r.id === root.quizData.id);
                                    if (!quizResponseObj || !quizResponseObj.questions) return false;
                                    var questionResponse = quizResponseObj.questions[root.questionIndex];
                                    if (!questionResponse) return false;
                                    var selectedAnswer = Object.values(questionResponse)[0];
                                    return selectedAnswer === modelData;
                                }

                                color: isSelected ? "#ec4899" : "#4b5563"

                                Text {
                                    id: answerText
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        top: parent.top
                                        margins: 10
                                    }
                                    text: modelData
                                    font.pixelSize: 14
                                    color: "white"
                                    wrapMode: Text.Wrap
                                    width: parent.width - 20
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (root.quizData) {
                                            root.quizResponse(root.quizData.questions[root.questionIndex].question, modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Bottom padding
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 20
            }
        }
    }

    // Quiz Completion View - This is NOT a popup anymore, but a full view
    Rectangle {
        id: quizCompletedView
        anchors.fill: parent
        color: "#121212" // Dark background matching app theme
        
        // Visible when quiz is completed, hidden otherwise
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

                // List of Questions and Answers
                // Instead of ListView, use a Repeater for better layout control
                Repeater {
                    id: resultsRepeater
                    model: root.completedQuizData ? root.completedQuizData.questions : []
                    
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: resultContentColumn.height + 20 // Add padding to height
                        color: "#1f1f1f" // gray-800
                        radius: 5
                        Layout.bottomMargin: 10

                        property var questionAnswerPair: modelData
                        property string questionText: Object.keys(questionAnswerPair)[0] || "Question"
                        property string answerText: Object.values(questionAnswerPair)[0] || "No answer provided"

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
                                text: "Q: " + parent.parent.questionText
                                font.pixelSize: 14
                                color: "#e5e7eb" // gray-200
                                wrapMode: Text.Wrap
                            }
                            
                            Text {
                                width: parent.width
                                text: "A: " + parent.parent.answerText
                                font.pixelSize: 14
                                color: "white"
                                font.bold: true
                                wrapMode: Text.Wrap
                                topPadding: 4
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

