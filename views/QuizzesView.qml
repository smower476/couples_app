import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "CallAPI.js" as CallAPI

Item {
    id: root
    width: parent.width
    height: parent.height

    // Properties
    property var initialQuizzes: []
    property var currentQuiz: null
    property int currentQuizIndex: 0
    property int currentQuestionIndex: 0
    property var quizResponses: ({})
    property string apiKey_: ""

    // Signals
    signal startQuiz(var quiz)
    signal quizResponse(string question, string response)

    API_Key {
        onSendAPISIG: function (apiKey) {
            root.apiKey_ = apiKey
            getNewQuiz(function (quiz) {
                root.initialQuizzes = [quiz];  // Push quiz into the array
                console.log("Quiz pushed:", JSON.stringify(root.initialQuizzes));  // Check if quiz is valid and pushed
                getNewQuiz(function (quiz2) {
                    root.initialQuizzes = root.initialQuizzes.concat([quiz2]);
                    console.log("Second quiz pushed:", JSON.stringify(root.initialQuizzes));  // Check if second quiz is valid and pushed

                    // Manually trigger the update after the data is pushed
                });
                // Manually trigger the update after the data is pushed
            });


        }
    }

    function getNewQuestion(callback, apikey) {
        CallAPI.getQuizzQuestionAndAnswer(function (question, answers) {
            callback({
                         "question": question,
                         "options": answers
                     })
        }, root.apiKey_)
    }

    function getNewQuiz(callback) {
        // Fetch the title first before proceeding
        CallAPI.fetchRandomWords(2, root.apiKey_, function(q) {
            let title = q[0];
            console.log("Title:", title);

            let quiz = {
                "id": root.currentQuizIndex,
                "title": title,  // Now title is set
                "questions": []
            };

            let completedQuestions = 0;

            for (var i = 0; i < 5; i++) {
                getNewQuestion(function(newQuestion) {
                    quiz.questions.push(newQuestion);
                    completedQuestions++;

                    // Once all questions are added, call the callback
                    if (completedQuestions === 5) {
                        callback(quiz);
                    }
                });
            }
            root.currentQuizIndex++;
        });
    }


    ScrollView {
        id: scrollView
        anchors.fill: parent
        contentWidth: parent.width
        clip: true

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
                    text: "🤔 Relationship Quizzes"
                    font.pixelSize: 24
                    font.bold: true
                    color: "white"
                    visible: !root.currentQuiz
                }

                Text {
                    anchors.centerIn: parent
                    text: root.currentQuiz ? root.currentQuiz.title : ""
                    font.pixelSize: 24
                    font.bold: true
                    color: "white"
                    visible: root.currentQuiz !== null
                }
            }

            // Quiz list (visible when no quiz is selected)
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: quizListColumn.height
                visible: !root.currentQuiz

                ColumnLayout {
                    id: quizListColumn
                    width: parent.width
                    spacing: 16

                    Repeater {
                        id: quizListRepeater
                        model: root.initialQuizzes

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.margins: 16
                            height: quizItemColumn.height + 32
                            color: "#1f1f1f" // gray-800
                            radius: 8

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.startQuiz(modelData)
                            }

                            ColumnLayout {
                                id: quizItemColumn
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                    margins: 16
                                }
                                spacing: 8

                                Text {
                                    text: modelData.title
                                    font.pixelSize: 18
                                    font.bold: true
                                    color: "white"
                                }

                                Text {
                                    text: "Tap to start quiz"
                                    font.pixelSize: 14
                                    color: "#9ca3af" // gray-400
                                }
                            }
                        }
                    }
                }
            }

            // Quiz question (visible when a quiz is selected)
            Rectangle {
                Layout.fillWidth: true
                Layout.margins: 16
                // Layout.preferredHeight removed, let it fill height
                Layout.fillHeight: true // Make the question container fill available vertical space
                color: "#1f1f1f" // gray-800
                radius: 8
                visible: root.currentQuiz !== null

                ColumnLayout {
                    id: questionColumn
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 16
                    }

                    Text {
                        text: "Question " + (root.currentQuestionIndex + 1) + " of "
                              + (root.currentQuiz ? root.currentQuiz.questions.length : 0)
                        font.pixelSize: 16
                        color: "#9ca3af" // gray-400
                    }

                    Item {
                        Layout.fillHeight: true
                    }

                    Text {
                        text: root.currentQuiz ? root.currentQuiz.questions[root.currentQuestionIndex].question : ""
                        font.pixelSize: 20
                        color: "white"
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }

                    ColumnLayout { // Changed from GridLayout
                        Layout.fillWidth: true
                        Layout.fillHeight: true // Make the answers layout fill vertical space
                        spacing: 24 // Increased spacing to spread items out more
                        Repeater {
                            model: root.currentQuiz ? root.currentQuiz.questions[root.currentQuestionIndex].options : []

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                // Adjust preferred height based on the Text element's implicit height
                                Layout.preferredHeight: Math.min(answerText.implicitHeight + 20, 100) // +20 for top/bottom margins
                                Layout.maximumHeight: 100 // Keep the maximum height constraint
                                radius: 4

                                property bool isSelected: {
                                    if (!root.currentQuiz)
                                        return false
                                    if (!root.quizResponses[root.currentQuiz.id])
                                        return false
                                    return root.quizResponses[root.currentQuiz.id][root.currentQuestionIndex] === modelData
                                }

                                color: isSelected ? "#ec4899" : "#4b5563" // pink-600 or gray-600

                                // Replaced ScrollView with Text directly to test wrapping
                                Text {
                                    id: answerText // Use the id referenced in Layout.preferredHeight
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        top: parent.top
                                        margins: 10 // Apply padding directly
                                    }
                                    text: modelData
                                    font.pixelSize: 14
                                    color: "white"
                                    wrapMode: Text.Wrap // Enable wrapping
                                    width: parent.width - 20 // Constrain width to parent Rectangle minus margins
                                    horizontalAlignment: Text.AlignHCenter // Center the text horizontally
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.quizResponse(root.currentQuiz.questions[root.currentQuestionIndex].question, modelData)
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
}

