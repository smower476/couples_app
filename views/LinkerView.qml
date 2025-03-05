import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    width: parent.width
    height: parent.height
    
    // Properties
    property bool partnerLinked: false
    property string inviteCode: ""
    
    // Signals
    signal linkPartner()
    
    ColumnLayout {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            margins: 16
        }
        spacing: 20
        
        // Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            color: "transparent"
            
            Text {
                anchors.centerIn: parent
                text: root.partnerLinked ? "💕 Connected" : "🔗 Link Your Partner"
                font.pixelSize: 24
                font.bold: true
                color: "white"
            }
        }
        
        // Content depends on linked status
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            // Not linked UI
            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width
                spacing: 20
                visible: !root.partnerLinked
                
                // Input field
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    Layout.maximumWidth: 300
                    Layout.alignment: Qt.AlignHCenter
                    color: "#1f1f1f" // gray-800
                    radius: 8
                    
                    TextField {
                        id: inviteCodeField
                        anchors.fill: parent
                        anchors.margins: 4
                        placeholderText: "Enter partner's invite code"
                        horizontalAlignment: TextInput.AlignHCenter
                        color: "white"
                        background: null
                        
                        onTextChanged: {
                            root.inviteCode = text
                        }
                    }
                }
                
                // Link button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    Layout.maximumWidth: 300
                    Layout.alignment: Qt.AlignHCenter
                    color: "#ec4899" // pink-600
                    radius: 8
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Link Partner 💑"
                        font.pixelSize: 16
                        font.bold: true
                        color: "white"
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (root.inviteCode.trim() !== "") {
                                root.linkPartner()
                            }
                        }
                    }
                }
                
                // Your invite code
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 100
                    Layout.maximumWidth: 300
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 40
                    color: "#1f1f1f" // gray-800
                    radius: 8
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        
                        Text {
                            text: "Your invite code:"
                            font.pixelSize: 14
                            color: "#9ca3af" // gray-400
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        Text {
                            text: "LOVE-2025"
                            font.pixelSize: 24
                            font.bold: true
                            color: "#ec4899" // pink-600
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        Text {
                            text: "Share this with your partner"
                            font.pixelSize: 12
                            color: "#9ca3af" // gray-400
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }
            
            // Linked UI
            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width
                spacing: 20
                visible: root.partnerLinked
                
                Image {
                    source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='100' height='100' viewBox='0 0 24 24' fill='none' stroke='%23ec4899' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z'/></svg>"
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 100
                }
                
                Text {
                    text: "Connected with Sarah"
                    font.pixelSize: 24
                    font.bold: true
                    color: "white"
                    Layout.alignment: Qt.AlignHCenter
                }
                
                Text {
                    text: "You're now linked! Share moments, take quizzes, and grow together."
                    font.pixelSize: 16
                    color: "#9ca3af" // gray-400
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    Layout.maximumWidth: 300
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}