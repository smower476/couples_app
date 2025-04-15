import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "CallAPI.js" as CallAPI // Import the API functions

Item {
    id: loginRegisterRoot
    width: parent.width
    height: parent.height

    // Signals to notify the parent (main.qml)
    // Signal for login result (now includes username)
    signal loginAttemptFinished(bool success, string tokenOrError, string username)
    // Signal to navigate to registration page
    signal navigateToRegisterRequested()

    // Property to hold status message
    property string statusMessage: ""
    // Removed showConfirmPassword property

    // --- Validation Functions ---
    function isValidLogin(login) {
        // Regex: ^[a-zA-Z0-9_]{3,20}$
        const loginRegex = /^[a-zA-Z0-9_]{3,20}$/;
        return loginRegex.test(login);
    }

    function isValidPassword(password) {
        // Regex: ^[a-zA-Z0-9@#%*!?]{8,32}$
        // Allows letters, numbers, and @#%*!? symbols, length 8-32
        const passwordRegex = /^[a-zA-Z0-9@#%*!?]{8,32}$/;
        return passwordRegex.test(password);
    }
    // --- End Validation Functions ---

    ColumnLayout {
        id: formLayout // Give the layout an id
        anchors.centerIn: parent
        width: parent.width * 0.8
        spacing: 20

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Login or Register"
            font.pixelSize: 24
            font.bold: true
            color: "white"
        }

        TextField {
            id: usernameInput
            Layout.fillWidth: true
            placeholderText: "Username or Email"
            color: "white"
            background: Rectangle {
                color: "#374151" // gray-700
                radius: 4
                border.color: "#4b5563" // gray-600
            }
            placeholderTextColor: "#9ca3af" // gray-400
        }

        TextField {
            id: passwordInput
            Layout.fillWidth: true
            placeholderText: "Password"
            echoMode: TextInput.Password
            color: "white"
            background: Rectangle {
                color: "#374151" // gray-700
                radius: 4
                border.color: "#4b5563" // gray-600
            }
            placeholderTextColor: "#9ca3af" // gray-400
        }

        // Removed Confirm Password Field

        // Status Message Area
        Text {
            id: statusText
            Layout.fillWidth: true
            text: loginRegisterRoot.statusMessage
            color: statusMessage.startsWith("Error") ? "red" : "lightgreen" // Color based on message
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            visible: statusMessage !== "" // Only show if there's a message
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Button {
                id: loginButton
                Layout.fillWidth: true
                text: "Login"
                onClicked: {
                    console.log("Login clicked:", usernameInput.text);
                    loginRegisterRoot.statusMessage = ""; // Clear previous message
                    // Removed showConfirmPassword = false

                    // --- Add Login Validation ---
                    if (!isValidLogin(usernameInput.text)) {
                        loginRegisterRoot.statusMessage = "Error: Invalid username format (3-20 chars, a-z, A-Z, 0-9, _)";
                        return;
                    }
                    // --- End Login Validation ---

                    loginRegisterRoot.statusMessage = "Logging in..."; // Show status
                    CallAPI.loginUser(usernameInput.text, passwordInput.text, (success, tokenOrError) => {
                        if (success) {
                            // Clear fields on success? Optional.
                            // usernameInput.text = ""
                            // passwordInput.text = ""
                            loginRegisterRoot.statusMessage = "Login Successful!";
                            // Emit success with token AND username
                            loginRegisterRoot.loginAttemptFinished(true, tokenOrError, usernameInput.text);
                        } else {
                            loginRegisterRoot.statusMessage = "Error: " + tokenOrError;
                            // Emit failure (username doesn't matter here)
                            loginRegisterRoot.loginAttemptFinished(false, tokenOrError, usernameInput.text);
                        }
                    });
                }
            }

            Button {
                id: registerButton
                Layout.fillWidth: true
                text: "Register"
                onClicked: {
                    console.log("Navigate to Register clicked");
                    loginRegisterRoot.statusMessage = ""; // Clear status
                    // Emit signal to navigate
                    loginRegisterRoot.navigateToRegisterRequested();
                }
            }
        }
    }
}