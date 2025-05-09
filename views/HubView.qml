import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "CallAPI.js" as CallAPI // Import CallAPI

Item {
    id: root
    width: parent.width
    height: parent.height
    
    // Properties
    property string jwtToken: "" // Add JWT token property
    property var answeredQuizzesList: [] // To store fetched answered quizzes
    property var quizResponses: []
    property var dailyResponses: []
    property var dateIdeasHistory: []
    property var initialQuizzes: []
    
    // Function to fetch answered quizzes
    function fetchAnsweredQuizzes() {
        console.log("HubView: fetchAnsweredQuizzes called."); // Log function call
        console.log("HubView: Current jwtToken:", root.jwtToken); // Log current token

        if (!root.jwtToken) {
            console.log("HubView: JWT token not available, cannot fetch answered quizzes. Returning."); // Log early exit
            return;
        }
        console.log("HubView: JWT token available. Proceeding with API call."); // Log before API call

        CallAPI.getAnsweredQuizzes(root.jwtToken, function(success, quizzes) {
            console.log("HubView: CallAPI.getAnsweredQuizzes callback received."); // Log callback received
            console.log("HubView: API call success:", success); // Log API call success status
            console.log("HubView: API call result (quizzes):", JSON.stringify(quizzes)); // Log API call result

            if (success) {
                console.log("HubView: Answered quizzes fetched successfully."); // Log success branch
                // Filter out any null or undefined entries and ensure it's an array
                root.answeredQuizzesList = Array.isArray(quizzes) ? quizzes.filter(q => q !== null && q !== undefined) : [];
                console.log("HubView: answeredQuizzesList updated:", JSON.stringify(root.answeredQuizzesList)); // Log updated list
            } else {
                console.error("HubView: Failed to fetch answered quizzes:", quizzes); // Log failure branch
                root.answeredQuizzesList = []; // Clear list on failure
                console.log("HubView: answeredQuizzesList cleared due to failure."); // Log list cleared
            }
        });
    }
    
    // Connections to react to property changes on this component (root)
    Connections {
        target: root
        
        function onJwtTokenChanged() {
            //console.log("HubView: jwtToken changed. Fetching answered quizzes.");
            if (root.jwtToken) {
                root.fetchAnsweredQuizzes();
            } else {
                //console.log("HubView: jwtToken cleared.");
                root.answeredQuizzesList = []; // Clear list if token is cleared
            }
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
                    text: "📊 Relationship Hub"
                    font.pixelSize: 24
                    font.bold: true
                    color: "white"
                }

                // --- Add Profile Button ---
                Text {
                    id: profileButton
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        rightMargin: 16 // Add some margin
                    }
                    text: "👤" // Placeholder icon/text
                    font.pixelSize: 24
                    color: "white"

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            // Call the function defined in main.qml
                            window.handleProfileClick()
                        }
                    }
                }
                // --- End Profile Button ---
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
                    
                    // Quiz history items (clickable list of quiz names)
                    Repeater {
                        model: root.answeredQuizzesList // Use the fetched list
                        
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 50 // Fixed height for list items
                            radius: 8
                            color: "#2d2d2d" // Slightly lighter gray for list items
                            
                            // Clickable area
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    // Navigate to the new detail view and pass the raw quiz data
                                    // Assuming 'window' is the root object in main.qml that handles view switching
                                    // and has a function like showQuizHistoryDetail to set the current view and pass data.
                                    if (window && window.showQuizHistoryDetail) {
                                        window.showQuizHistoryDetail(modelData); // Pass the raw answered quiz item
                                    } else {
                                        console.error("HubView: window or showQuizHistoryDetail function not available for navigation.");
                                        console.log("Clicked quiz (data not passed):", JSON.stringify(modelData));
                                    }
                                }
                            }
                            
                            Text {
                                anchors.centerIn: parent
                                text: modelData ? modelData.quiz_name || "Unnamed Quiz" : "Loading..." // Display quiz name
                                font.pixelSize: 16
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight // Elide long names
                                wrapMode: Text.NoWrap
                            }
                            
                            // Separator line
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 1
                                color: "#4b5563" // gray-600
                                anchors.bottom: parent.bottom
                                visible: index < root.answeredQuizzesList.length - 1
                            }
                        }
                    }
                    
                    Text {
                        text: root.answeredQuizzesList.length === 0 ? "No quiz history yet" : ""
                        font.pixelSize: 14
                        color: "#9ca3af" // gray-400
                        visible: root.answeredQuizzesList.length === 0
                    }
                }
            }
            
              // Relationship Insight Card
            Rectangle {
                Layout.fillWidth: true
                Layout.margins: 16
                Layout.preferredHeight: insightColumn.height + 32
                color: "#2c1d40" // Purple dark background
                radius: 8
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#2c1d40" }
                    GradientStop { position: 1.0; color: "#1f1f1f" }
                }
                
                ColumnLayout {
                    id: insightColumn
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 16
                    }
                    spacing: 16
                    
                    Text {
                        text: "💖 Relationship Insight"
                        font.pixelSize: 20
                        font.bold: true
                        color: "#ec4899" // pink-500
                    }
                    
                    Text {
                        Layout.fillWidth: true
                        text: "Did you know? Couples who regularly check in with each other through quizzes and discussions are 58% more likely to report feeling understood and connected to their partner."
                        font.pixelSize: 16
                        color: "white"
                        wrapMode: Text.Wrap
                        lineHeight: 1.4
                    }
                    
                    Button {
                        Layout.alignment: Qt.AlignCenter
                        Layout.topMargin: 8
                        Layout.preferredWidth: 200
                        Layout.preferredHeight: 50
                        text: "Go to Quizzes"
                        
                        background: Rectangle {
                            radius: 8
                            color: parent.pressed ? "#b44076" : "#ec4899" // Darker pink when pressed
                            
                            Rectangle {
                                width: parent.width
                                height: 2
                                color: "#ff6bb3" // Light pink
                                anchors.bottom: parent.bottom
                                opacity: 0.5
                                visible: !parent.parent.pressed
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
                        
                        onClicked: {
                            if (window.isLoggedIn) {
                                window.currentView = "quizzes"
                            } else {
                                window.currentView = "login"
                            }
                        }
                    }
                }
            }
            


            // Server Toggle Card
            Rectangle {
                Layout.fillWidth: true
                Layout.margins: 16
                Layout.preferredHeight: 80 // Adjust height as needed
                color: "#1f1f1f" // gray-800
                radius: 8

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 16
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        id: serverStatusText
                        Layout.fillWidth: true
                        text: "Current server: Development" // Initial text
                        font.pixelSize: 16
                        color: "white"
                        verticalAlignment: Text.AlignVCenter
                    }

                    Switch {
                        id: serverToggle
                        Layout.preferredWidth: 51 // iPhone toggle width
                        Layout.preferredHeight: 31 // iPhone toggle height
                        Layout.alignment: Qt.AlignVCenter
                        checked: true // Set to true to be on by default

                        // Custom styling for iPhone look
                        indicator: Rectangle {
                            implicitWidth: 27 // Thumb size
                            implicitHeight: 27
                            x: parent.checked ? parent.width - width - 2 : 2 // Animate position
                            y: 2
                            radius: width / 2 // Make it round
                            color: "white"
                            border.color: "#e0e0e0" // Light gray border
                            border.width: 1
                            antialiasing: true

                            Behavior on x {
                                NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                            }
                        }

                        background: Rectangle {
                            implicitWidth: 51 // Track width
                            implicitHeight: 31 // Track height
                            radius: height / 2 // Rounded track
                            color: parent.checked ? "#34c759" : "#787880" // Green when checked, gray when unchecked
                            antialiasing: true

                            Behavior on color {
                                ColorAnimation { duration: 200 }
                            }
                        }

                        onCheckedChanged: {
                            if (checked) {
                                // On state: Production
                                window.aPI_BASE_URL = "http://129.158.234.85:8081";
                                serverStatusText.text = "Current server: Production";
                            } else {
                                // Off state: Development
                                window.aPI_BASE_URL = "http://129.158.234.85:8080";
                                serverStatusText.text = "Current server: Development";
                            }
                            console.log("API Base URL changed to:", window.aPI_BASE_URL);
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

        Component.onCompleted: {
            //console.log("HubView: Component onCompleted. Fetching answered quizzes.");
            fetchAnsweredQuizzes();
        }
    }
}
