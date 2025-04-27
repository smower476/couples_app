import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15
import "CallAPI.js" as CallAPI

Item {
    id: profileRoot
    width: parent.width
    height: parent.height

    // Signal to notify parent (main.qml)
    signal logoutRequested()

    // Properties for user info
    property string token: ""
    property var userInfo: null
    property var partnerInfo: null
    property bool isLoading: false
    property string errorMessage: ""
    
    // Mood status options
    property var moodStatuses: ["angry", "sad", "neutral", "happy"]
    property int currentMoodIndex: -1 // -1 means no mood selected
    
    // Function to convert mood status string to index
    function moodStatusToIndex(status) {
        if (!status) return 2; // Default to neutral
        return moodStatuses.indexOf(status);
    }
    
    // Function to update the UI with user info
    function updateUserInfo(info) {
        if (!info) return;
        
        userInfo = info;
        usernameText.text = info.username || "Unknown";
        linkedStatusText.text = "Linked: " + (info.linked_user ? "Yes" : "No");
        
        // Set mood slider position based on mood_status
        if (info.mood_status) {
            currentMoodIndex = moodStatusToIndex(info.mood_status);
            if (currentMoodIndex >= 0) {
                moodSlider.value = currentMoodIndex;
            } else {
                moodSlider.value = 2; // Default to neutral
            }
        } else {
            moodSlider.value = 2; // Default to neutral
        }
    }
    
    // Load user info when token is set
    onTokenChanged: {
       //console.log("ProfileView: onTokenChanged triggered with token:", token);
        if (token) {
            loadUserInfo();
        }
    }
    
    // Function to load user info from API
    function loadUserInfo() {
        isLoading = true;
        errorMessage = "";
       //console.log("Loading user info with token:", token);
        // Call the API to get user info
        CallAPI.getUserInfo(token, function(success, result) {
            isLoading = false;
            if (success) {
                updateUserInfo(result);
                
                // Also load partner info if user is linked
                if (result.linked_user) {
                    loadPartnerInfo();
                } else {
                    partnerInfo = null;
                }
            } else {
                if (typeof result === "object" && result.message) {
                    errorMessage = result.message;
                } else {
                    errorMessage = "Failed to load user info";
                }
            }
        });
    }
    
    // Function to load partner info
    function loadPartnerInfo() {
        CallAPI.getPartnerInfo(token, function(success, result) {
            if (success) {
                partnerInfo = result;
                partnerUsernameText.text = "Partner: " + (result.username || "Unknown");
                partnerMoodText.text = "Partner Mood: " + (result.mood_status || "Not set");
            } else {
                partnerInfo = null;
                partnerUsernameText.text = "Partner: Not available";
            }
        });
    }
    
    // Function to update user mood
    function updateMood(moodIndex) {
        if (moodIndex < 0 || moodIndex >= moodStatuses.length) return;
        
        var moodStatus = moodStatuses[moodIndex];
        
        CallAPI.setUserInfo(token, null, moodStatus, function(success, result) {
            if (success) {
               //console.log("Mood updated successfully");
            } else {
               //console.log("Failed to update mood:", result);
                errorMessage = "Failed to update mood";
            }
        });
    }
    
    // Refresh button clicked
    function onRefreshClicked() {
        loadUserInfo();
    }

    // UI Components
    Rectangle {
        anchors.fill: parent
        color: "#121212" // Dark background - Keeping this as it's the root background
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 10

        // Main content column layout
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 15

            // Card for username (top)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                color: "transparent" // Transparent header to match LinkerView
                radius: 10

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Profile"
                        font.pixelSize: 22
                        font.bold: true
                        color: "white" // White text for header
                    }
                    
                    Label {
                        id: usernameText
                        Layout.alignment: Qt.AlignHCenter
                        text: "Loading..."
                        font.pixelSize: 18
                        font.bold: true
                        color: "white" // White text for username
                    }
                }
            }

            // Loading indicator
            BusyIndicator {
                Layout.alignment: Qt.AlignHCenter
                running: profileRoot.isLoading
                visible: profileRoot.isLoading
            }
            
            // Error message
            Label {
                Layout.fillWidth: true
                text: profileRoot.errorMessage
                color: "#ef4444" // Red color for error to match LinkerView
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                visible: profileRoot.errorMessage !== ""
                font.pixelSize: 16
            }

            // User and Partner info side by side
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 180
                color: "#1f1f1f" // Dark card background to match LinkerView input field
                radius: 10
                visible: profileRoot.userInfo !== null

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 15
                    
                    // User info section
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 10

                        Label {
                            text: "Your Information"
                            font.bold: true
                            font.pixelSize: 18
                            color: "#9ca3af" // Gray text for label
                        }

                        Label {
                            id: linkedStatusText
                            text: "Linked: Loading..."
                            font.pixelSize: 16
                            color: "white" // White text for linked status
                            wrapMode: Text.WordWrap
                        }
                    }

                    // Vertical separator
                    Rectangle {
                        Layout.fillHeight: true
                        width: 1
                        color: "#313244" // Separator color
                        visible: profileRoot.partnerInfo !== null
                    }

                    // Partner info section
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 10
                        visible: profileRoot.partnerInfo !== null

                        Label {
                            text: "Partner Information"
                            font.bold: true
                            font.pixelSize: 18
                            color: "#9ca3af" // Gray text for label
                        }

                        Label {
                            id: partnerUsernameText
                            text: "Partner: Loading..."
                            font.pixelSize: 16
                            color: "white" // White text for partner username
                            wrapMode: Text.WordWrap
                        }

                        Label {
                            id: partnerMoodText
                            text: "Partner Mood: Loading..."
                            font.pixelSize: 16
                            color: "white" // White text for partner mood
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            // Mood Section
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 150 // Keep preferred height for layout
                spacing: 10
                // Background color matching main background
                Rectangle {
                    anchors.fill: parent
                    color: "#121212" // Main background color from main.qml
                }

                // Mood slider container with simplified positioning
Label {
                    text: "Set your mood"
                    font.pixelSize: 18
                    font.bold: true // Keep bold for consistency with previous "Your Mood"
                    color: "#9ca3af" // Gray text for label
                    Layout.leftMargin: 15
                    Layout.rightMargin: 15
                    Layout.topMargin: 15 // Add top margin
                }
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    Layout.leftMargin: 15 // Add margins to match previous card padding
                    Layout.rightMargin: 15
                    Layout.topMargin: 15 // Add top margin to the slider container

                    // Upper bracket indicator
                    Rectangle {
                        id: upperBracket
                        width: 20
                        height: 10
                        color: "#ec4899" // Pink indicator to match LinkerView accent
                        anchors {
                            bottom: sliderRow.top
                            bottomMargin: 5
                        }
                        x: moodSlider.visualPosition * (sliderRow.width - width)
                    }

                    // Colored mood slider
                    Item {
                        id: sliderRow
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                        }
                        height: 30

                        Row {
                            anchors.fill: parent

                            Rectangle {
                                width: parent.width / 4
                                height: parent.height
                                color: "#f38ba8" // Red for sad
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "Angry"
                                    color: "#1e1e2e" // Dark text
                                    font.pixelSize: 14
                                    font.bold: true
                                }
                            }

                            Rectangle {
                                width: parent.width / 4
                                height: parent.height
                                color: "#f9e2af" // Yellow for angry
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "Sad"
                                    color: "#1e1e2e" // Dark text
                                    font.pixelSize: 14
                                    font.bold: true
                                }
                            }

                            Rectangle {
                                width: parent.width / 4
                                height: parent.height
                                color: "#89b4fa" // Blue for neutral

                                Text {
                                    anchors.centerIn: parent
                                    text: "Neutral"
                                    color: "#1e1e2e" // Dark text
                                    font.pixelSize: 14
                                    font.bold: true
                                }
                            }

                            Rectangle {
                                width: parent.width / 4
                                height: parent.height
                                color: "#a6e3a1" // Green for happy

                                Text {
                                    anchors.centerIn: parent
                                    text: "Happy"
                                    color: "#1e1e2e" // Dark text
                                    font.pixelSize: 14
                                    font.bold: true
                                }
                            }
                        }
                    }

                    // Invisible slider on top for interaction
                    Slider {
                        id: moodSlider
                        anchors.fill: parent
                        from: 0
                        to: 3
                        stepSize: 1
                        value: 2 // Default to neutral
                        snapMode: Slider.SnapAlways

                        background: Rectangle {
                            color: "transparent" // Make background invisible
                        }

                        handle: Item {
                            // No visible handle as we're using brackets instead
                        }

                        onMoved: {
                            profileRoot.updateMood(Math.round(value))
                        }
                    }

                    // Lower bracket indicator
                    Rectangle {
                        width: 20
                        height: 10
                        color: "#ec4899" // Pink indicator to match LinkerView accent
                        anchors {
                            top: sliderRow.bottom
                            topMargin: 5
                        }
                        x: moodSlider.visualPosition * (sliderRow.width - width)
                    }
                }
            }

            // Spacer to push content up and buttons down
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            // Action buttons - aligned to the right
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                Row {
                    anchors.right: parent.right
                    spacing: 10
                    Button {
                        width: 120
                        height: 45
                        text: "Refresh"
                        Material.background: "#ec4899" // Pink background to match LinkerView button
                        Material.foreground: "white" // White text to match LinkerView button
                        onClicked: profileRoot.onRefreshClicked()
                    }
                    Button {
                        id: logoutButton
                        width: 120
                        height: 45
                        text: "Logout"
                        Material.background: "#ec4899" // Pink background to match LinkerView button
                        Material.foreground: "white" // White text to match LinkerView button
                        onClicked: {
                           //console.log("Logout clicked")
                            profileRoot.logoutRequested()
                        }
                    }
                }
            }
        }
    }
}
