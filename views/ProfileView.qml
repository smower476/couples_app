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
    property var moodStatuses: ["sad", "angry", "neutral", "happy"]
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
                currentMoodText.text = "Current Mood: " + info.mood_status;
            } else {
                moodSlider.value = 2; // Default to neutral
                currentMoodText.text = "Current Mood: Not set";
            }
        } else {
            moodSlider.value = 2; // Default to neutral
            currentMoodText.text = "Current Mood: Not set";
        }
    }
    
    // Load user info when token is set
    onTokenChanged: {
        console.log("ProfileView: onTokenChanged triggered with token:", token);
        if (token) {
            loadUserInfo();
        }
    }
    
    // Function to load user info from API
    function loadUserInfo() {
        isLoading = true;
        errorMessage = "";
        console.log("Loading user info with token:", token);
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
        currentMoodText.text = "Current Mood: " + moodStatus;
        
        CallAPI.setUserInfo(token, null, moodStatus, function(success, result) {
            if (success) {
                console.log("Mood updated successfully");
            } else {
                console.log("Failed to update mood:", result);
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
        color: "#1e1e2e" // Dark background
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
                color: "#313244" // Darker header
                radius: 10

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Profile"
                        font.pixelSize: 22
                        font.bold: true
                        color: "#cdd6f4" // Light text
                    }
                    
                    Label {
                        id: usernameText
                        Layout.alignment: Qt.AlignHCenter
                        text: "Loading..."
                        font.pixelSize: 18
                        font.bold: true
                        color: "#89b4fa" // Blue highlight for username
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
                color: "#f38ba8" // Red/pink color
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                visible: profileRoot.errorMessage !== ""
                font.pixelSize: 16
            }

            // User and Partner info side by side
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 180
                color: "#313244" // Dark card background
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
                            color: "#cdd6f4" // Light text
                        }

                        Label {
                            id: linkedStatusText
                            text: "Linked: Loading..."
                            font.pixelSize: 16
                            color: "#cdd6f4" // Light text
                            wrapMode: Text.WordWrap
                        }
                    }

                    // Vertical separator
                    Rectangle {
                        Layout.fillHeight: true
                        width: 1
                        color: "#585b70" // Separator color
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
                            color: "#cdd6f4" // Light text
                        }

                        Label {
                            id: partnerUsernameText
                            text: "Partner: Loading..."
                            font.pixelSize: 16
                            color: "#cdd6f4" // Light text
                            wrapMode: Text.WordWrap
                        }

                        Label {
                            id: partnerMoodText
                            text: "Partner Mood: Loading..."
                            font.pixelSize: 16
                            color: "#cdd6f4" // Light text
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            // Mood Scale Card
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 150
                color: "#313244" // Dark card background
                radius: 10

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10                // Mood Section - directly in the layout without its own card
                    
                    Label {
                        text: "Your Mood"
                        font.bold: true
                        font.pixelSize: 18
                        color: "#cdd6f4" // Light text
                    }

                    Label {
                        id: currentMoodText
                        text: "Current Mood: Not set"
                        font.pixelSize: 16
                        color: "#cdd6f4" // Light text
                    }

                    // Mood slider container with simplified positioning
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 60
                        
                        // Upper bracket indicator
                        Rectangle {
                            id: upperBracket
                            width: 20
                            height: 10
                            color: "#cba6f7" // Purple indicator
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
                                        text: "Sad"
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
                                        text: "Angry"
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
                            color: "#cba6f7" // Purple indicator
                            anchors {
                                top: sliderRow.bottom
                                topMargin: 5
                            }
                            x: moodSlider.visualPosition * (sliderRow.width - width)
                        }
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
                        Material.background: "#89b4fa" // Blue
                        Material.foreground: "#1e1e2e" // Dark text
                        onClicked: profileRoot.onRefreshClicked()
                    }
                    Button {
                        id: logoutButton
                        width: 120
                        height: 45
                        text: "Logout"
                        Material.background: "#f38ba8" // Red/pink
                        Material.foreground: "#1e1e2e" // Dark text
                        onClicked: {
                            console.log("Logout clicked")
                            profileRoot.logoutRequested()
                        }
                    }
                }
            }
        }
    }
}
