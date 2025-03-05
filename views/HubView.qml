import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    width: parent.width
    height: parent.height
    
    // Properties
    property var quizResponses: ({})
    property var dailyResponses: []
    property var dateIdeasHistory: []
    property var initialQuizzes: []
    
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
                    text: "📊 Relationship Hub"
                    font.pixelSize: 24
                    font.bold: true
                    color: "white"
                }
            }
            
            // Quiz History Section
            Rectangle {
                Layout.fillWidth: true
                Layout.margins: 16
                Layout.preferredHeight: quizHistoryColumn.height + 32
                color: "#1f1f1f" // gray-800
                radius: 8
                
                ColumnLayout {
                    id: quizHistoryColumn
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 16
                    }
                    spacing: 8
                    
                    Text {
                        text: "🤔 Quiz History"
                        font.pixelSize: 18
                        font.bold: true
                        color: "white"
                    }
                    
                    // Quiz history items
                    Repeater {
                        model: Object.keys(root.quizResponses)
                        
                        delegate: ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            
                            property var quizId: modelData
                            property var quiz: root.initialQuizzes.find(q => q.id == quizId)
                            property var responses: root.quizResponses[quizId]
                            
                            Text {
                                text: quiz ? quiz.title : "Unknown Quiz"
                                font.pixelSize: 16
                                color: "#ec4899" // pink-500
                            }
                            
                            Repeater {
                                model: responses ? Object.keys(responses) : []
                                
                                delegate: Text {
                                    Layout.fillWidth: true
                                    text: {
                                        const questionIndex = parseInt(modelData);
                                        const question = quiz ? quiz.questions[questionIndex].question : "Unknown";
                                        return question + ": " + responses[modelData];
                                    }
                                    font.pixelSize: 14
                                    color: "white"
                                    wrapMode: Text.Wrap
                                }
                            }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 1
                                color: "#4b5563" // gray-600
                                visible: index < Object.keys(root.quizResponses).length - 1
                            }
                        }
                    }
                    
                    Text {
                        text: Object.keys(root.quizResponses).length === 0 ? "No quiz history yet" : ""
                        font.pixelSize: 14
                        color: "#9ca3af" // gray-400
                        visible: Object.keys(root.quizResponses).length === 0
                    }
                }
            }
            
            // Daily Questions Section
            Rectangle {
                Layout.fillWidth: true
                Layout.margins: 16
                Layout.preferredHeight: dailyQuestionsColumn.height + 32
                color: "#1f1f1f" // gray-800
                radius: 8
                
                ColumnLayout {
                    id: dailyQuestionsColumn
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 16
                    }
                    spacing: 8
                    
                    Text {
                        text: "❓ Daily Questions"
                        font.pixelSize: 18
                        font.bold: true
                        color: "white"
                    }
                    
                    // Daily questions history
                    Repeater {
                        model: root.dailyResponses
                        
                        delegate: ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            
                            Text {
                                text: modelData.date
                                font.pixelSize: 14
                                color: "#ec4899" // pink-500
                            }
                            
                            Text {
                                text: modelData.question
                                font.pixelSize: 16
                                color: "white"
                                wrapMode: Text.Wrap
                            }
                            
                            Text {
                                text: modelData.response
                                font.pixelSize: 14
                                color: "#9ca3af" // gray-400
                                wrapMode: Text.Wrap
                            }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 1
                                color: "#4b5563" // gray-600
                                visible: index < root.dailyResponses.length - 1
                            }
                        }
                    }
                    
                    Text {
                        text: root.dailyResponses.length === 0 ? "No daily questions answered yet" : ""
                        font.pixelSize: 14
                        color: "#9ca3af" // gray-400
                        visible: root.dailyResponses.length === 0
                    }
                }
            }
            
            // Date Ideas History Section
            Rectangle {
                Layout.fillWidth: true
                Layout.margins: 16
                Layout.preferredHeight: dateIdeasColumn.height + 32
                color: "#1f1f1f" // gray-800
                radius: 8
                
                ColumnLayout {
                    id: dateIdeasColumn
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 16
                    }
                    spacing: 8
                    
                    Text {
                        text: "🌟 Date Ideas History"
                        font.pixelSize: 18
                        font.bold: true
                        color: "white"
                    }
                    
                    // Date ideas history
                    Repeater {
                        model: root.dateIdeasHistory
                        
                        delegate: ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            
                            Text {
                                text: modelData.date
                                font.pixelSize: 14
                                color: "#ec4899" // pink-500
                            }
                            
                            Text {
                                text: modelData.idea + " - " + modelData.response
                                font.pixelSize: 16
                                color: "white"
                                wrapMode: Text.Wrap
                            }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 1
                                color: "#4b5563" // gray-600
                                visible: index < root.dateIdeasHistory.length - 1
                            }
                        }
                    }
                    
                    Text {
                        text: root.dateIdeasHistory.length === 0 ? "No date ideas rated yet" : ""
                        font.pixelSize: 14
                        color: "#9ca3af" // gray-400
                        visible: root.dateIdeasHistory.length === 0
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