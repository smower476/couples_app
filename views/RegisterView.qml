import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "CallAPI.js" as CallAPI

Item {
    id: registerRoot
    width: parent.width
    height: parent.height

    // Signals to notify main.qml
    signal registrationComplete(bool success, string tokenOrError)
    signal backToLoginRequested()

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

    function isValidDateOfBirth(dobString) {
        const dobRegex = /^\d{2}-\d{2}-\d{4}$/;
        if (!dobRegex.test(dobString)) {
            return false;
        }
        try {
            const parts = dobString.split('-');
            const year = parseInt(parts[2], 10);
            const month = parseInt(parts[0], 10) - 1;
            const day = parseInt(parts[1], 10);
            const dob = new Date(year, month, day);

            if (dob.getFullYear() !== year || dob.getMonth() !== month || dob.getDate() !== day) {
                return false;
            }

            const today = new Date();
            today.setHours(0, 0, 0, 0);
            return !isNaN(dob.getTime()) && dob < today;
        } catch (e) {
            return false;
        }
    }

    // Define styles directly in the component - matching LoginRegisterView
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
        
        gradient: Gradient {
            GradientStop { position: 0.0; color: backgroundColor }
            GradientStop { position: 1.0; color: Qt.darker(backgroundColor, 1.2) }
        }
    }

    Image {
        id: appLogo
        source: "../images/heart.svg"
        width: 70
        height: 70
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.05
        fillMode: Image.PreserveAspectFit
    }

    Rectangle {
        id: cardContainer
        width: parent.width * 0.85
        anchors.top: appLogo.bottom
        anchors.topMargin: marginLarge
        anchors.bottom: parent.bottom
        anchors.bottomMargin: parent.height * 0.05
        anchors.horizontalCenter: parent.horizontalCenter
        color: cardBackgroundColor
        radius: 16
    }

    ScrollView {
        id: scrollView
        anchors.fill: cardContainer
        anchors.margins: marginLarge
        clip: true
        ScrollBar.vertical.policy: ScrollBar.Never
        ScrollBar.horizontal.policy: ScrollBar.Never
        ScrollBar.vertical.visible: false
        ScrollBar.horizontal.visible: false

        // Disable the flicking behavior that might show scrollbars
        contentWidth: availableWidth
        contentHeight: formLayout.implicitHeight

        ColumnLayout {
            id: formLayout
            width: scrollView.width
            height: scrollView.height
            spacing: marginLarge

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Create Account"
                font.pixelSize: fontSizeXLarge
                font.bold: true
                color: textColor
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Join and connect with your partner"
                font.pixelSize: fontSizeNormal
                color: secondaryTextColor
                Layout.bottomMargin: marginNormal
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: marginSmall
                
                Text {
                    text: "Email (Optional)"
                    color: secondaryTextColor
                    font.pixelSize: fontSizeNormal
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 48
                    color: "#2d2d2d"
                    radius: 8
                    
                    TextField {
                        id: emailInput
                        anchors.fill: parent
                        leftPadding: 16
                        rightPadding: 16
                        verticalAlignment: TextInput.AlignVCenter
                        placeholderText: "Enter your email"
                        placeholderTextColor: "#6b7280"
                        color: textColor
                        font.pixelSize: fontSizeNormal
                        background: Item {}
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: marginSmall
                
                Text {
                    text: "Name (Optional)"
                    color: secondaryTextColor
                    font.pixelSize: fontSizeNormal
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 48
                    color: "#2d2d2d"
                    radius: 8
                    
                    TextField {
                        id: nameInput
                        anchors.fill: parent
                        leftPadding: 16
                        rightPadding: 16
                        verticalAlignment: TextInput.AlignVCenter
                        placeholderText: "Enter your name"
                        placeholderTextColor: "#6b7280"
                        color: textColor
                        font.pixelSize: fontSizeNormal
                        background: Item {}
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: marginSmall
                
                Text {
                    text: "Date of Birth"
                    color: secondaryTextColor
                    font.pixelSize: fontSizeNormal
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 48
                    color: "#2d2d2d"
                    radius: 8
                    
                    TextField {
                        id: dobInput
                        anchors.fill: parent
                        leftPadding: 16
                        rightPadding: 16
                        verticalAlignment: TextInput.AlignVCenter
                        placeholderText: "MM-DD-YYYY"
                        placeholderTextColor: "#6b7280"
                        inputMask: "00-00-0000"
                        maximumLength: 10
                        color: textColor
                        font.pixelSize: fontSizeNormal
                        background: Item {}
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: marginSmall
                
                Text {
                    text: "Username*"
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
                        placeholderText: "Create a username"
                        placeholderTextColor: "#6b7280"
                        color: textColor
                        font.pixelSize: fontSizeNormal
                        background: Item {}
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: marginSmall
                
                Text {
                    text: "Password*"
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
                        leftPadding: 16
                        rightPadding: 16
                        verticalAlignment: TextInput.AlignVCenter
                        placeholderText: "Create a password"
                        placeholderTextColor: "#6b7280"
                        echoMode: TextInput.Password
                        color: textColor
                        font.pixelSize: fontSizeNormal
                        background: Item {}
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: marginSmall
                
                Text {
                    text: "Confirm Password*"
                    color: secondaryTextColor
                    font.pixelSize: fontSizeNormal
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 48
                    color: "#2d2d2d"
                    radius: 8
                    
                    TextField {
                        id: confirmPasswordInput
                        anchors.fill: parent
                        leftPadding: 16
                        rightPadding: 16
                        verticalAlignment: TextInput.AlignVCenter
                        placeholderText: "Confirm your password"
                        placeholderTextColor: "#6b7280"
                        echoMode: TextInput.Password
                        color: textColor
                        font.pixelSize: fontSizeNormal
                        background: Item {}
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: statusText.contentHeight + marginMedium
                color: statusMessage.startsWith("Error") ? "#450a0a" : "#042f2e"
                radius: 6
                visible: statusMessage !== ""
                Layout.topMargin: marginNormal
                
                Text {
                    id: statusText
                    anchors.fill: parent
                    anchors.margins: marginNormal
                    text: registerRoot.statusMessage
                    color: statusMessage.startsWith("Error") ? "#fecaca" : "#ccfbf1"
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: fontSizeNormal
                }
            }

            Button {
                id: registerButton
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                Layout.topMargin: marginLarge
                
                background: Rectangle {
                    color: registerButton.pressed ? Qt.darker(primaryColor, 1.2) : primaryColor
                    radius: 8
                    
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: registerButton.pressed ? Qt.darker(primaryColor, 1.2) : primaryColor }
                        GradientStop { position: 1.0; color: registerButton.pressed ? Qt.darker("#db2777", 1.2) : "#db2777" }
                    }
                    
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                
                contentItem: Text {
                    text: "Create Account"
                    color: "#ffffff"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: fontSizeMedium
                    font.bold: true
                }
                
                onClicked: {
                    registerRoot.statusMessage = "";

                    if (!isValidLogin(usernameInput.text)) {
                        registerRoot.statusMessage = "Error: Invalid username format (3-20 chars, a-z, A-Z, 0-9, _)";
                        return;
                    }
                    if (!isValidPassword(passwordInput.text)) {
                        registerRoot.statusMessage = "Error: Invalid password format (8-32 chars, a-z, A-Z, 0-9, @#%*!?)";
                        return;
                    }
                    if (passwordInput.text !== confirmPasswordInput.text) {
                        registerRoot.statusMessage = "Error: Passwords do not match";
                        return;
                    }
                    if (dobInput.text !== "" && dobInput.text !== "__-__-____" && !isValidDateOfBirth(dobInput.text)) {
                        registerRoot.statusMessage = "Error: Invalid Date of Birth (must be MM-DD-YYYY and in the past)";
                        return;
                    }

                    registerRoot.statusMessage = "Registering...";
                    CallAPI.registerUser(usernameInput.text, passwordInput.text, (regSuccess, regMessage) => {
                        if (regSuccess) {
                            registerRoot.statusMessage = "Registration successful. Logging in...";
                            CallAPI.loginUser(usernameInput.text, passwordInput.text, (loginSuccess, tokenOrError) => {
                                if (loginSuccess) {
                                    registerRoot.statusMessage = "Registration & Login Successful!";
                                    registerRoot.registrationComplete(true, JSON.stringify({token: tokenOrError, username: usernameInput.text}));
                                } else {
                                    registerRoot.statusMessage = "Error: Auto-login failed: " + tokenOrError;
                                    registerRoot.registrationComplete(false, tokenOrError);
                                }
                            });
                        } else {
                            registerRoot.statusMessage = "Error: Registration failed: " + regMessage;
                            registerRoot.registrationComplete(false, regMessage);
                        }
                    });
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: marginMedium
                
                Text {
                    text: "Already have an account?"
                    color: secondaryTextColor
                    font.pixelSize: fontSizeNormal
                }
                
                Text {
                    text: "Sign In"
                    color: primaryColor
                    font.pixelSize: fontSizeNormal
                    font.bold: true
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            registerRoot.backToLoginRequested();
                        }
                    }
                }
            }
            
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: marginXLarge
            }
        }
    }
}
