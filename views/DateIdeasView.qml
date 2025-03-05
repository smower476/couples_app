import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    width: parent.width
    height: parent.height
    
    // Properties
    property var dateIdeas: []
    property int currentIndex: 0
    
    // Signals
    signal dateIdeaResponse(string response)
    
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
                text: "🌟 Date Idea Picker"
                font.pixelSize: 24
                font.bold: true
                color: "white"
            }
        }
        
        // Current date idea
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 200
            
            Text {
                anchors.centerIn: parent
                text: root.dateIdeas.length > 0 ? root.dateIdeas[root.currentIndex] : ""
                font.pixelSize: 48
                color: "white"
                horizontalAlignment: Text.AlignHCenter
            }
        }
        
        // Buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: 16
            
            // Yes button
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                color: "#16a34a" // green-600
                radius: 8
                
                Text {
                    anchors.centerIn: parent
                    text: "Yes 👍"
                    font.pixelSize: 16
                    font.bold: true
                    color: "white"
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.dateIdeaResponse("yes")
                    }
                }
            }
            
            // Maybe button
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                color: "#d97706" // yellow-600
                radius: 8
                
                Text {
                    anchors.centerIn: parent
                    text: "Maybe 🤔"
                    font.pixelSize: 16
                    font.bold: true
                    color: "white"
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.dateIdeaResponse("maybe")
                    }
                }
            }
            
            // No button
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                color: "#dc2626" // red-600
                radius: 8
                
                Text {
                    anchors.centerIn: parent
                    text: "No 👎"
                    font.pixelSize: 16
                    font.bold: true
                    color: "white"
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.dateIdeaResponse("no")
                    }
                }
            }
        }
        
        // Spacer
        Item {
            Layout.fillHeight: true
        }
    }
}