import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "CallAPI.js" as CallAPI

Item {
    id: loginRegisterRoot
    width: parent.width
    height: parent.height

    // Signals to notify the parent (main.qml)
    signal loginAttemptFinished(bool success, string tokenOrError, string username)
    signal navigateToRegisterRequested()

    // Property to hold status message
    property string statusMessage: ""

    // --- Validation Functions ---
    function isValidLogin(login) {
        const loginRegex = /^[a-zA-Z0-9_]{3,20}$/;
        return loginRegex.test(login);
    }

    function isValidPassword(password) {
        const passwordRegex = /^[a-zA-Z0-9@#%*!?]{8,32}$/;
        return passwordRegex.test(password);
    }
    // --- End Validation Functions ---

    // Define styles directly in the component
    readonly property color backgroundColor: "#121212"
    readonly property color cardBackgroundColor: "#1e1e1e"
    readonly property color primaryColor: "#ec4899"
    readonly property color textColor: "#ffffff"
    readonly property color secondaryTextColor: "#a0a0a0"
    readonly property int fontSizeSmall: 12
    readonly property int fontSizeNormal: 14
    readonly property int fontSizeMedium: 16
    readonly property int fontSizeXLarge: 24
    readonly property int marginSmall: 8
    readonly property int marginNormal: 12
    readonly property int marginMedium: 16
    readonly property int marginLarge: 20
    readonly property int marginXLarge: 24

    // Background with gradient
    Rectangle {
        anchors.fill: parent
        color: backgroundColor
        
        // Add subtle gradient to background
        gradient: Gradient {
            GradientStop { position: 0.0; color: backgroundColor }
            GradientStop { position: 1.0; color: Qt.darker(backgroundColor, 1.2) }
        }
    }

    // App logo/branding
    Image {
        id: appLogo
        source: "../images/heart.svg"
        width: 80
        height: 80
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.1
        fillMode: Image.PreserveAspectFit
    }

    // Main content area with card-like appearance
    Rectangle {
        id: cardContainer
        width: parent.width * 0.85
        height: formLayout.height + marginXLarge * 2
        anchors.centerIn: parent
        color: cardBackgroundColor
        radius: 16
    }

    ColumnLayout {
        id: formLayout
        anchors.centerIn: parent
        width: cardContainer.width - marginXLarge * 2
        spacing: marginLarge

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Welcome Back"
            font.pixelSize: fontSizeXLarge
            font.bold: true
            color: textColor
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Sign in to your account"
            font.pixelSize: fontSizeNormal
            color: secondaryTextColor
            Layout.bottomMargin: marginNormal
        }

        // Username field with icon
        ColumnLayout {
            Layout.fillWidth: true
            spacing: marginSmall
            
            Text {
                text: "Username or Email"
                color: secondaryTextColor
                font.pixelSize: fontSizeNormal
            }
            
            Rectangle {
                Layout.fillWidth: true
                height: 48
                color: "#2d2d2d"
                radius: 8
                
                TextField {
                    id: usernameInput
                    anchors.fill: parent
                    leftPadding: 16
                    rightPadding: 16
                    verticalAlignment: TextInput.AlignVCenter
                    placeholderText: "Enter your username"
                    placeholderTextColor: "#6b7280"
                    color: textColor
                    font.pixelSize: fontSizeNormal
                    background: Item {} // Remove default background
                }
            }
        }

        // Password field with icon and toggle visibility
        ColumnLayout {
            Layout.fillWidth: true
            spacing: marginSmall
            
            Text {
                text: "Password"
                color: secondaryTextColor
                font.pixelSize: fontSizeNormal
            }
            
            Rectangle {
                Layout.fillWidth: true
                height: 48
                color: "#2d2d2d"
                radius: 8
                
                TextField {
                    id: passwordInput
                    anchors.fill: parent
                    anchors.rightMargin: 48
                    leftPadding: 16
                    rightPadding: 16
                    verticalAlignment: TextInput.AlignVCenter
                    placeholderText: "Enter your password"
                    placeholderTextColor: "#6b7280"
                    echoMode: showPasswordButton.checked ? TextInput.Normal : TextInput.Password
                    color: textColor
                    font.pixelSize: fontSizeNormal
                    background: Item {} // Remove default background
                }
                
                // Password visibility toggle
                Button {
                    id: showPasswordButton
                    width: 48
                    height: 48
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checkable: true
                    flat: true
                    
                    contentItem: Text {
                        text: showPasswordButton.checked ? "hide" : "show"
                        color: secondaryTextColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: fontSizeSmall
                    }
                    
                    background: Rectangle {
                        color: "transparent"
                    }
                }
            }
        }

        // Status Message Area with improved styling
        Rectangle {
            Layout.fillWidth: true
            height: statusText.contentHeight + marginMedium
            color: statusMessage.startsWith("Error") ? "#450a0a" : "#042f2e"  // Red-900 or Teal-900 based on error
            radius: 6
            visible: statusMessage !== ""
            Layout.topMargin: marginNormal
            
            Text {
                id: statusText
                anchors.fill: parent
                anchors.margins: marginNormal
                text: loginRegisterRoot.statusMessage
                color: statusMessage.startsWith("Error") ? "#fecaca" : "#ccfbf1"  // Red-100 or Teal-100
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: fontSizeNormal
            }
        }

        // Primary login button with modern styling
        Button {
            id: loginButton
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            Layout.topMargin: marginLarge
            
            background: Rectangle {
                color: loginButton.pressed ? Qt.darker(primaryColor, 1.2) : primaryColor
                radius: 8
                
                // Add gradient effect
                gradient: Gradient {
                    GradientStop { position: 0.0; color: loginButton.pressed ? Qt.darker(primaryColor, 1.2) : primaryColor }
                    GradientStop { position: 1.0; color: loginButton.pressed ? Qt.darker("#db2777", 1.2) : "#db2777" }  // Slightly darker pink
                }
                
                // Add subtle animation on hover/press
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            
            contentItem: Text {
                text: "Sign In"
                color: "#ffffff"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: fontSizeMedium
                font.bold: true
            }
            
            onClicked: {
                //console.log("Login clicked:", usernameInput.text);
                loginRegisterRoot.statusMessage = "";
                if (!isValidLogin(usernameInput.text)) {
                    loginRegisterRoot.statusMessage = "Error: Invalid username format (3-20 chars, a-z, A-Z, 0-9, _)";
                    return;
                }

                loginRegisterRoot.statusMessage = "Logging in...";
                CallAPI.loginUser(usernameInput.text, passwordInput.text, (success, tokenOrError) => {
                    if (success) {
                        loginRegisterRoot.statusMessage = "Login Successful!";
                        loginRegisterRoot.loginAttemptFinished(true, tokenOrError, usernameInput.text);
                    } else {
                        loginRegisterRoot.statusMessage = "Error: " + tokenOrError;
                        loginRegisterRoot.loginAttemptFinished(false, tokenOrError, usernameInput.text);
                    }
                });
            }
        }

        // Register option with text and button
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: marginMedium
            
            Text {
                text: "Don't have an account?"
                color: secondaryTextColor
                font.pixelSize: fontSizeNormal
            }
            
            Text {
                text: "Sign Up"
                color: primaryColor
                font.pixelSize: fontSizeNormal
                font.bold: true
                
                // Make text clickable
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        //console.log("Navigate to Register clicked");
                        loginRegisterRoot.statusMessage = "";
                        loginRegisterRoot.navigateToRegisterRequested();
                    }
                }
            }
        }
        
        // Add some spacing at the bottom
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: marginLarge
        }
    }
}