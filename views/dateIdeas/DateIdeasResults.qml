import "../CallAPI.js" as CallAPI
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// Results list view (review mode)
Item {
    id: root

    property var responsesList: [] // List of responses to display
    property bool isVisible: false // Track visibility of the component

    width: parent.width
    height: parent.height
    property string jwtToken: ""

    // Auto-refresh when component becomes visible
    onIsVisibleChanged: {
        if (isVisible && root.jwtToken && root.jwtToken !== "") {
            console.log("DateIdeasResults became visible, refreshing data");
            root.getDateIdeasAnswers();
        }
    }

    // Initialize component
    Component.onCompleted: {
        isVisible = Qt.binding(function() { return root.visible && root.opacity > 0; });
    }

    Connections {
        function onJwtTokenChanged() {
            if (root.jwtToken && root.jwtToken !== "") {
                console.log("JWT Token is set DateIdeas: " + root.jwtToken);
                root.getDateIdeasAnswers();
            } else {
                root.responsesList = [];
                console.error("JWT Token is not set or empty");
            }
        }

        target: root
    }

    function getDateIdeasAnswers() {
        // Make API request to get date ideas answers
        CallAPI.makeApiRequest(
            "/get-matched-date-ideas",
            "token=" + root.jwtToken,
            function (reqSuccess, response) {
                if (reqSuccess) {
                    console.log("Date ideas answers received:", response);
                    response = JSON.parse(response);
                    root.responsesList = response;
                    updateResponsesList();
                } else {
                    console.error("Failed to fetch date ideas answers:", response);
                }
            },
            "POST"
        );
    }
    
    function updateResponsesList() {
        responsesModel.clear();
        for (var i = 0; i < root.responsesList.length; i++) {
            var item = root.responsesList[i];
            responsesModel.append({
                title: item.title || "",
                description: item.description || "",
                user_a_vote: item.user_a_vote || "maybe",
                user_b_vote: item.user_b_vote || "maybe",
                idea_id: item.idea_id || ""
            });
        }
    }

    // Header
    Rectangle {
        id: resultsHeader

        height: 60
        color: "transparent"

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: 16
            rightMargin: 16
            topMargin: 16
        }

        Text {
            anchors.centerIn: parent
            text: "🔄 Your Responses"
            font.pixelSize: 24
            font.bold: true
            color: "white"
        }

    }

    // Info text
    Text {
        id: resultInfo

        text: responsesModel.count > 0 ? "Here are all your responses (" + responsesModel.count + ")" : "No responses yet"
        font.pixelSize: 14
        color: "#9ca3af" // gray-400

        anchors {
            top: resultsHeader.bottom
            horizontalCenter: parent.horizontalCenter
            topMargin: 5
        }

    }

    // Results list
    ScrollView {
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AlwaysOff

        anchors {
            left: parent.left
            right: parent.right
            top: resultInfo.bottom
            bottom: parent.bottom
            topMargin: 10
            leftMargin: 16
            rightMargin: 16
            bottomMargin: 16
        }

        ListView {
            id: responsesList

            anchors.fill: parent
            anchors.margins: 8
            spacing: 20
            Component.onCompleted: {
                updateResponsesList();
            }

            model: ListModel {
                id: responsesModel
            }
            // Increased spacing between items

            delegate: Rectangle {
                width: Math.min(responsesList.width, 320) // Set a static max width
                height: delegateLayout.implicitHeight + 30
                radius: 12
                color: "#1f1f1f" // gray-800
                anchors.horizontalCenter: parent.horizontalCenter // Center in the list

                // Colored border based on match
                Rectangle {
                    id: responseBorder

                    anchors.fill: parent
                    z: -1
                    radius: 14
                    anchors.margins: -2

                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: (model.user_a_vote === "yes" && model.user_b_vote === "yes") ? "#16a34a" : "#d97706" // Green if both yes, amber otherwise
                        }

                        GradientStop {
                            position: 1
                            color: (model.user_a_vote === "yes" && model.user_b_vote === "yes") ? "#15803d" : "#b45309" // Darker green if both yes, darker amber otherwise
                        }
                    }

                }

                ColumnLayout {
                    id: delegateLayout
                    spacing: 10
                    anchors {
                        fill: parent
                        margins: 12
                    }

                    // Title row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        // Match indicator
                        Rectangle {
                            Layout.preferredWidth: 8
                            Layout.preferredHeight: 24
                            radius: 4
                            color: (model.user_a_vote === "yes" && model.user_b_vote === "yes") ? "#16a34a" : "#d97706"
                        }

                        // Title
                        Text {
                            text: model.title
                            font.pixelSize: 18
                            font.bold: true
                            color: "white"
                            Layout.fillWidth: true
                        }
                    }

                    // Description
                    Text {
                        text: model.description
                        font.pixelSize: 14
                        color: "#e5e7eb" // gray-200
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                    }

                    // Vote information row
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 8
                        spacing: 10

                        // Your vote
                        RowLayout {
                            spacing: 5
                            
                            Text {
                                text: "You:"
                                font.pixelSize: 12
                                color: "#9ca3af" // gray-400
                            }
                            
                            Rectangle {
                                Layout.preferredWidth: 60
                                Layout.preferredHeight: 24
                                radius: 12
                                color: {
                                    if (model.user_a_vote === "yes")
                                        return "#16a34a"; // green-600
                                    else if (model.user_a_vote === "no")
                                        return "#dc2626"; // red-600
                                    else
                                        return "#d97706"; // yellow-600
                                }
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: model.user_a_vote ? model.user_a_vote.toUpperCase() : "MAYBE"
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: "white"
                                }
                            }
                        }
                        
                        // Partner vote
                        RowLayout {
                            spacing: 5
                            
                            Text {
                                text: "Partner:"
                                font.pixelSize: 12
                                color: "#9ca3af" // gray-400
                            }
                            
                            Rectangle {
                                Layout.preferredWidth: 60
                                Layout.preferredHeight: 24
                                radius: 12
                                color: {
                                    if (model.user_b_vote === "yes")
                                        return "#16a34a"; // green-600
                                    else if (model.user_b_vote === "no")
                                        return "#dc2626"; // red-600
                                    else
                                        return "#d97706"; // yellow-600
                                }
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: model.user_b_vote ? model.user_b_vote.toUpperCase() : "MAYBE"
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: "white"
                                }
                            }
                        }
                    }
                }

            }

        }

    }

    // Refresh timer for periodic updates while visible
    Timer {
        id: refreshTimer
        interval: 30000 // 30 seconds
        repeat: true
        running: root.isVisible && root.jwtToken && root.jwtToken !== ""
        onTriggered: {
            console.log("Auto-refreshing date ideas");
            root.getDateIdeasAnswers();
        }
    }

}
