import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root

    property string dailyQuestion: "Yo momma?"
    property string userResponse: "answer"
    property string partnerAnswer: "    answer"

    signal switchToDifferentView(string view)

    anchors.fill: parent

    Rectangle {
        id: mainRectangle

        anchors.fill: parent
        color: "#121212" // Dark background

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 15
            anchors.rightMargin: 15
            spacing: 15

            // Header
            Text {
                Layout.fillWidth: true
                text: "💬 Daily Connection"
                font.pixelSize: 24
                font.bold: true
                color: "white"
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                Layout.fillWidth: true
                text: "Thank you for answering today's question!"
                font.pixelSize: 16
                color: "#d1d5db" // Light gray text like other views
                horizontalAlignment: Text.AlignHCenter
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: "#4b5563" // Gray divider like other views
                Layout.topMargin: 10
                Layout.bottomMargin: 10
            }

            // Question box
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: questionText.implicitHeight + 40
                color: "#1f1f1f" // Dark gray box like question views
                radius: 8

                Text {
                    id: questionText

                    text: root.dailyQuestion
                    font.pixelSize: 18
                    color: "white"
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    anchors {
                        fill: parent
                        margins: 20
                    }

                }

            }

            // Show waiting message if partner hasn't answered yet
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                color: "#1f1f1f"
                radius: 8
                visible: root.partnerAnswer === ""

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 10

                    Text {
                        text: "⏳"
                        font.pixelSize: 24
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "Waiting for your partner's response..."
                        font.pixelSize: 16
                        color: "#a5b4fc" // Light purple text
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                    }

                }

            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: "#4b5563" // Gray divider like other views
                Layout.topMargin: 10
                Layout.bottomMargin: 10
                visible: root.partnerAnswer !== ""
            }

            // Show answers side by side when both have responded
                ScrollView {
                    id: answersScrollView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.partnerAnswer !== ""
                    clip: true  // Changed to true for proper clipping
                    
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded
                    
                    ColumnLayout {
                        width: answersScrollView.width
                        spacing: 15
                        // Remove the anchors.fill as it can cause clipping issues
                        // Instead use width to match parent and add bottom padding
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.topMargin: 10
                        anchors.leftMargin: 15
                        anchors.rightMargin: 15

                        // Your answer
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: yourAnswerText.implicitHeight + 60 // Increased height for better padding
                            color: "#1f1f1f"
                            radius: 8

                            Rectangle {
                                id: yourAnswerBorder
                                anchors.fill: parent
                                z: -1
                                radius: 10
                                color: "transparent"
                                border.color: "#ec4899"
                                border.width: 2
                                anchors.margins: -2
                            }

                            ColumnLayout {
                                spacing: 10
                                anchors {
                                    fill: parent
                                    margins: 20 // Increased margins
                                    topMargin: 15 // Slightly less on top
                                    bottomMargin: 25 // More on bottom
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "You:"
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: "#ec4899" // Pink text for headers
                                }

                                Text {
                                    id: yourAnswerText
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter // Center vertically
                                    text: root.userResponse
                                    font.pixelSize: 16
                                    color: "white"
                                    wrapMode: Text.Wrap
                                }
                            }
                        }

                        // Partner's answer
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: partnerAnswerText.implicitHeight + 60 // Increased height for better padding
                            color: "#1f1f1f"
                            radius: 10

                            Rectangle {
                                id: partnerAnswerBorder
                                anchors.fill: parent
                                z: -1
                                radius: 10
                                color: "transparent"
                                border.color: "#a5b4fc" // Light purple border
                                border.width: 2
                                anchors.margins: -2
                            }

                            ColumnLayout {
                                spacing: 10
                                anchors {
                                    fill: parent
                                    margins: 20 // Increased margins
                                    topMargin: 15 // Slightly less on top
                                    bottomMargin: 25 // More on bottom
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "Partner:"
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: "#a5b4fc" // Light purple text
                                }

                                Text {
                                    id: partnerAnswerText
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter // Center vertically
                                    text: root.partnerAnswer
                                    font.pixelSize: 16
                                    color: "white"
                                    wrapMode: Text.Wrap
                                }
                            }
                        }

                        // Add bottom padding item to prevent clipping at the end
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 30  // Add extra space at the bottom
                        }
                    }
                }

            // Spacer - increased to push content up a bit
            Item {
                Layout.fillHeight: true
            }

            // Return to hub button
            Button {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 20
                text: "Back to Hub"
                onClicked: root.switchToDifferentView("hub")

                background: Rectangle {
                    implicitWidth: 200
                    implicitHeight: 50
                    radius: 25

                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: "#ec4899"
                        }

                        GradientStop {
                            position: 1
                            color: "#db2777"
                        }

                    }

                }

                contentItem: Text {
                    text: parent.text
                    font.pixelSize: 16
                    font.bold: true
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

            }

            // Bottom padding
            Item {
                Layout.preferredHeight: 20
            }

        }

    }

}
