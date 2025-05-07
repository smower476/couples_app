pragma ComponentBehavior: Bound
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Basic 6.2

Item {
    id: root
    width: parent.width
    height: parent.height
    
    property var quizData: null
    property int questionIndex: 0
    property var currentQuizAnswers: []
    property var partnerGuesses: []
    property string quizPhase: "answeringSelf"
    
    signal answerSelected(int questionIndex, int answerIndex, bool isLastQuestion)
    signal guessSelected(int questionIndex, int guessIndex, bool isLastQuestion)
    
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
                if (root.quizPhase === "answeringSelf") return root.quizData.title;
                return "🤔 Guess Partner's Answers";
            }
            font.pixelSize: 24
            font.bold: true
            color: "white"
        }
    }

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
            color: root.quizPhase === "answeringSelf" ? "#9ca3af" : "#f0abfc"
        }
    }

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
            height: questionText.implicitHeight + 40
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

    Rectangle {
        id: answerContainer
        width: parent.width
        color: "transparent"
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            bottomMargin: 20
        }
        height: Math.min(answerColumn.implicitHeight + 20, parent.height * 0.6)

        ColumnLayout {
            id: answerColumn
            anchors {
                fill: parent
                margins: 10
            }
            spacing: 12

            Repeater {
                model: root.quizData ? root.quizData.questions[root.questionIndex].options : []
                id: repeater

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(answerText.implicitHeight + 24, 80)
                    Layout.maximumHeight: 80
                    radius: 12
                    color: "#1f1f1f"
                    Layout.alignment: Qt.AlignHCenter
                    id: rectangle
                    required property string modelData
                    required property int index
                    property string _modelData: modelData
                    property int _index: index
                    property bool isSelected: {
                        if (!root.quizData || !root.currentQuizAnswers) return false;
                        if (root.quizPhase === "answeringSelf") {
                            return root.currentQuizAnswers[root.questionIndex] === _index + 1;
                        } else {
                            return root.partnerGuesses[root.questionIndex] === _index + 1;
                        }
                    }

                    Rectangle {
                        id: answerBorder
                        anchors.fill: parent
                        z: -1
                        radius: 14
                        gradient: Gradient {
                            GradientStop {
                                position: 0.0
                                color: rectangle.isSelected ? "#ec4899" : "#4b5563" 
                            }
                            GradientStop {
                                position: 1.0
                                color: rectangle.isSelected ? "#db2777" : "#374151"
                            }
                        }
                        anchors.margins: -2
                    }

                    Text {
                        id: answerText
                        anchors {
                            fill: parent
                            margins: 12
                        }
                        text: rectangle._modelData
                        font.pixelSize: 16
                        font.bold: rectangle.isSelected
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
                                const isLastQuestion = (currentQIndex === numQuestions - 1);

                                if (root.quizPhase === "answeringSelf") {
                                    root.currentQuizAnswers[currentQIndex] = selectedAnswerIndex;
                                    root.answerSelected(currentQIndex, selectedAnswerIndex, isLastQuestion);
                                } else {
                                    root.partnerGuesses[currentQIndex] = selectedAnswerIndex;
                                    root.guessSelected(currentQIndex, selectedAnswerIndex, isLastQuestion);
                                }
                            }
                        }
                    }
                }
            }

            Item {
                Layout.preferredHeight: 5
            }
        }
    }
}