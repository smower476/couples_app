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
                root.initialQuizzes = [quiz]
                console.log("Quiz data:",
                            root.initialQuizzes) // ✅ Now runs after data is ready
            })
        }
    }
    function getNewQuestion(callback, apikey) {
        CallAPI.getQuizzQuestionAndAnswer(function (question, answers) {
            console.log("Got all answers", answers)
            callback({
                         "question": question,
                         "options": answers
                     })
        }, root.apiKey_)
    }

    function getNewQuiz(callback) {
        let quiz = {
            "id": 1,
            "title": "Check",
            "questions": []
        }
        let completedQuestions = 0
        for (var i = 0; i < 5; i++) {
            getNewQuestion(function (newQuestion) {
                quiz.questions.push(newQuestion)
                completedQuestions++
                // Once all questions are added, call the callback
                if (completedQuestions === 5) {
                    console.log("New Quiz:", quiz)
                    callback(quiz)
                }
            })
        }
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
                Layout.preferredHeight: root.currentQuiz ? questionColumn.height + 32 : 0
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
                    spacing: 16

                    Text {
                        text: "Question " + (root.currentQuestionIndex + 1) + " of "
                              + (root.currentQuiz ? root.currentQuiz.questions.length : 0)
                        font.pixelSize: 16
                        color: "#9ca3af" // gray-400
                    }

                    Text {
                        text: root.currentQuiz ? root.currentQuiz.questions[root.currentQuestionIndex].question : ""
                        font.pixelSize: 20
                        color: "white"
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 12
                        columnSpacing: 12

                        Repeater {
                            model: root.currentQuiz ? root.currentQuiz.questions[root.currentQuestionIndex].options : []

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 60
                                radius: 4

                                property bool isSelected: {
                                    if (!root.currentQuiz)
                                        return false
                                    if (!root.quizResponses[root.currentQuiz.id])
                                        return false
                                    return root.quizResponses[root.currentQuiz.id][root.currentQuestionIndex] === modelData
                                }

                                color: isSelected ? "#ec4899" : "#4b5563" // pink-600 or gray-600

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    font.pixelSize: 14
                                    color: "white"
                                    wrapMode: Text.Wrap
                                    horizontalAlignment: Text.AlignHCenter
                                    width: parent.width - 20
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
