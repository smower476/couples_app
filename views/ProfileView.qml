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
        userIdText.text = "User ID: " + (info.id || "Unknown");
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
                partnerIdText.text = "Partner ID: " + (result.id || "Unknown");
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

    ColumnLayout {
        anchors {
            fill: parent
            margins: 20
        }
        spacing: 15

        // Header with username
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

        // Profile content in a scrollable area
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            
            ColumnLayout {
                width: parent.width
                spacing: 15
                
                // Loading indicator
                BusyIndicator {
                    Layout.alignment: Qt.AlignHCenter
                    running: isLoading
                    visible: isLoading
                }
                
                // Error message
                Label {
                    Layout.fillWidth: true
                    text: errorMessage
                    color: "#f38ba8" // Red/pink color
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    visible: errorMessage !== ""
                    font.pixelSize: 16
                }
                
                // User info section
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: userInfoColumn.height + 30
                    color: "#313244" // Dark card background
                    radius: 10
                    visible: userInfo !== null
                    
                    ColumnLayout {
                        id: userInfoColumn
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 15
                        }
                        spacing: 10
                        
                        Label {
                            text: "Your Information"
                            font.bold: true
                            font.pixelSize: 18
                            color: "#cdd6f4" // Light text
                        }
                        
                        Label {
                            id: userIdText
                            text: "User ID: Loading..."
                            font.pixelSize: 16
                            color: "#cdd6f4" // Light text
                        }
                        
                        Label {
                            id: linkedStatusText
                            text: "Linked: Loading..."
                            font.pixelSize: 16
                            color: "#cdd6f4" // Light text
                        }
                    }
                }
                
                // Partner info section
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: partnerInfoColumn.height + 30
                    color: "#313244" // Dark card background
                    radius: 10
                    visible: partnerInfo !== null
                    
                    ColumnLayout {
                        id: partnerInfoColumn
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 15
                        }
                        spacing: 10
                        
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
                        }
                        
                        Label {
                            id: partnerIdText
                            text: "Partner ID: Loading..."
                            font.pixelSize: 16
                            color: "#cdd6f4" // Light text
                        }
                        
                        Label {
                            id: partnerMoodText
                            text: "Partner Mood: Loading..."
                            font.pixelSize: 16
                            color: "#cdd6f4" // Light text
                        }
                    }
                }
                
                // Mood Section
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: moodColumn.height + 30
                    color: "#313244" // Dark card background
                    radius: 10
                    
                    ColumnLayout {
                        id: moodColumn
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 15
                        }
                        spacing: 15
                        
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
                        
                        // Colored mood sections
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 10
                            Layout.bottomMargin: 5
                            
                            Row {
                                anchors.fill: parent
                                
                                // Sad section (blue)
                                Rectangle {
                                    width: parent.width / 4
                                    height: parent.height
                                    color: "#f38ba8" // Red for sad
                                }
                                
                                // Angry section (red)
                                Rectangle {
                                    width: parent.width / 4
                                    height: parent.height
                                    color: "#f9e2af" // Yellow for angry
                                }
                                
                                // Neutral section (yellow)
                                Rectangle {
                                    width: parent.width / 4
                                    height: parent.height
                                    color: "#89b4fa" // Blue for neutral
                                }
                                
                                // Happy section (green)
                                Rectangle {
                                    width: parent.width / 4
                                    height: parent.height
                                    color: "#a6e3a1" // Green for happy
                                }
                            }
                        }
                        
                        // Mood Slider
                        Slider {
                            id: moodSlider
                            Layout.fillWidth: true
                            from: 0
                            to: 3
                            stepSize: 1
                            value: 2 // Default to neutral
                            snapMode: Slider.SnapAlways
                            
                            background: Rectangle {
                                x: moodSlider.leftPadding
                                y: moodSlider.topPadding + moodSlider.availableHeight / 2 - height / 2
                                width: moodSlider.availableWidth
                                height: 4
                                radius: 2
                                color: "#45475a" // Slider track color
                                visible: false // Hide default track since we have colored sections
                            }
                            
                            handle: Rectangle {
                                x: moodSlider.leftPadding + moodSlider.visualPosition * (moodSlider.availableWidth - width)
                                y: moodSlider.topPadding + moodSlider.availableHeight / 2 - height / 2
                                width: 24
                                height: 24
                                radius: 12
                                border.width: 2
                                border.color: "#1e1e2e"
                                color: {
                                    if (moodSlider.value === 0) return "#f38ba8" // Sad - red
                                    if (moodSlider.value === 1) return "#f9e2af" // Angry - yellow
                                    if (moodSlider.value === 2) return "#89b4fa" // Neutral - blue
                                    if (moodSlider.value === 3) return "#a6e3a1" // Happy - green
                                    return "#cba6f7" // Default - purple
                                }
                            }
                            
                            onMoved: {
                                updateMood(Math.round(value))
                            }
                        }
                        
                        // Mood Labels
                        Row {
                            Layout.fillWidth: true
                            spacing: 0
                            
                            Repeater {
                                model: ["Sad", "Angry", "Neutral", "Happy"]
                                
                                Label {
                                    width: moodSlider.width / 4
                                    text: modelData
                                    color: "#cdd6f4" // Light text
                                    font.pixelSize: 14
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }
                    }
                }
                
                // Action buttons
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    
                    Button {
                        Layout.fillWidth: true
                        text: "Refresh"
                        Material.background: "#89b4fa" // Blue
                        Material.foreground: "#1e1e2e" // Dark text
                        onClicked: onRefreshClicked()
                    }
                    
                    Button {
                        id: logoutButton
                        Layout.fillWidth: true
                        text: "Logout"
                        Material.background: "#f38ba8" // Red/pink
                        Material.foreground: "#1e1e2e" // Dark text
                        onClicked: {
                            console.log("Logout clicked")
                            profileRoot.logoutRequested()
                        }
                    }
                }
                
                // Bottom spacing
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20
                }
            }
        }
    }
}
