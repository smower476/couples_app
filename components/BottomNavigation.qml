import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: bottomNav
    width: parent.width
    height: 60
    color: "#1f1f1f"  // gray-800
    
    // Signal when a tab is selected
    signal tabSelected(string tabName)
    
    // Current active tab
    property string activeTab: "hub"
    
    RowLayout {
        anchors.fill: parent
        spacing: 0
        
        // Hub tab
        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4
                
                Image {
                    Layout.alignment: Qt.AlignHCenter
                    source: bottomNav.activeTab === "hub" ? "qrc:/images/archive-active.svg" : "qrc:/images/archive.svg"
                    sourceSize.width: 24
                    sourceSize.height: 24
                }
                
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Hub"
                    font.pixelSize: 12
                    color: bottomNav.activeTab === "hub" ? "#ec4899" : "#9ca3af"
                }
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    bottomNav.activeTab = "hub"
                    tabSelected("hub")
                }
            }
        }
        
        // Quizzes tab
        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4
                
                Image {
                    Layout.alignment: Qt.AlignHCenter
                    source: bottomNav.activeTab === "quizzes" ? "qrc:/images/help-circle-active.svg" : "qrc:/images/help-circle.svg"
                    sourceSize.width: 24
                    sourceSize.height: 24
                }
                
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Quizzes"
                    font.pixelSize: 12
                    color: bottomNav.activeTab === "quizzes" ? "#ec4899" : "#9ca3af"
                }
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    bottomNav.activeTab = "quizzes"
                    tabSelected("quizzes")
                }
            }
        }
        
        // Daily Q tab
        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4
                
                Image {
                    Layout.alignment: Qt.AlignHCenter
                    source: bottomNav.activeTab === "daily-question" ? "qrc:/images/message-circle-active.svg" : "qrc:/images/message-circle.svg"
                    sourceSize.width: 24
                    sourceSize.height: 24
                }
                
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Daily Q"
                    font.pixelSize: 12
                    color: bottomNav.activeTab === "daily-question" ? "#ec4899" : "#9ca3af"
                }
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    bottomNav.activeTab = "daily-question"
                    tabSelected("daily-question")
                }
            }
        }
        
        // Date Ideas tab
        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4
                
                Image {
                    Layout.alignment: Qt.AlignHCenter
                    source: bottomNav.activeTab === "date-ideas" ? "qrc:/images/calendar-active.svg" : "qrc:/images/calendar.svg"
                    sourceSize.width: 24
                    sourceSize.height: 24
                }
                
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Date Ideas"
                    font.pixelSize: 12
                    color: bottomNav.activeTab === "date-ideas" ? "#ec4899" : "#9ca3af"
                }
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    bottomNav.activeTab = "date-ideas"
                    tabSelected("date-ideas")
                }
            }
        }
        
        // Linker tab
        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4
                
                Image {
                    Layout.alignment: Qt.AlignHCenter
                    source: bottomNav.activeTab === "linker" ? "qrc:/images/heart-active.svg" : "qrc:/images/heart.svg"
                    sourceSize.width: 24
                    sourceSize.height: 24
                }
                
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Linker"
                    font.pixelSize: 12
                    color: bottomNav.activeTab === "linker" ? "#ec4899" : "#9ca3af"
                }
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    bottomNav.activeTab = "linker"
                    tabSelected("linker")
                }
            }
        }
    }
}