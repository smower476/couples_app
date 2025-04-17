import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    width: parent.width
    height: parent.height

    // Property to receive the completed quiz data from main.qml
    // Expected format: { id: "quizId", title: "Quiz Title", questions: [{ "Question 1": "Answer 1"}, {"Question 2": "Answer 2"}] }
    property var completedQuizResponses: null

    // Signal emitted when the user wants to dismiss this view
    signal resultsDismissed()

    ScrollView {
        anchors.fill: parent
        contentWidth: parent.width
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 20
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 20
            }

            // Header
            Text {
                Layout.fillWidth: true
                text: "🎉 Congratulations! 🎉"
                font.pixelSize: 28
                font.bold: true
                color: "white"
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                Layout.fillWidth: true
                text: "You've completed the Daily Quiz!"
                font.pixelSize: 18
                color: "#d1d5db" // gray-300
                horizontalAlignment: Text.AlignHCenter
            }

            // Quiz Title (if available)
            Text {
                Layout.fillWidth: true
                text: completedQuizResponses ? completedQuizResponses.title : "Quiz Results"
                font.pixelSize: 22
                font.bold: true
                color: "white"
                horizontalAlignment: Text.AlignHCenter
                visible: completedQuizResponses && completedQuizResponses.title
                topPadding: 10
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
                font.pixelSize: 20
                font.bold: true
                color: "white"
            }

            // List of Questions and Answers
            ListView {
                id: resultsListView
                Layout.fillWidth: true
                // Calculate height based on content or set a reasonable height
                Layout.preferredHeight: Math.min(contentHeight, root.height * 0.5) // Limit height
                clip: true
                model: completedQuizResponses ? completedQuizResponses.questions : [] // Array of { "Q": "A" } objects

                delegate: ColumnLayout {
                    width: resultsListView.width
                    spacing: 8

                    property var questionAnswerPair: modelData // The { "Q": "A" } object
                    property string questionText: Object.keys(questionAnswerPair)[0]
                    property string answerText: Object.values(questionAnswerPair)[0]

                    Rectangle {
                        Layout.fillWidth: true
                        color: "#1f1f1f" // gray-800
                        radius: 5

                        ColumnLayout {
                            width: parent.width
                            anchors.fill: parent // Make layout fill the rectangle
                            anchors.margins: 10 // Apply padding via margins

                            Text {
                                Layout.fillWidth: true
                                text: "Q: " + questionText
                                font.pixelSize: 16
                                color: "#e5e7eb" // gray-200
                                wrapMode: Text.Wrap
                            }
                            Text {
                                Layout.fillWidth: true
                                text: "A: " + answerText
                                font.pixelSize: 16
                                color: "white"
                                font.bold: true
                                wrapMode: Text.Wrap
                                topPadding: 4
                            }
                        }
                    }
                }

                ScrollIndicator.vertical: ScrollIndicator { }
            }

            // Spacer to push button down
            Item { Layout.fillHeight: true }

            // Done Button
            Button {
                id: doneButton
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                text: "Done"
                font.pixelSize: 18
                highlighted: true // Use accent color

                background: Rectangle {
                    color: doneButton.down ? "#d03ca0" : "#ec4899" // pink-600 / darker pink
                    radius: 8
                }

                onClicked: {
                    root.resultsDismissed() // Emit the signal
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