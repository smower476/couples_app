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
        // Basic check for MM-DD-YYYY format and if date is in the past
        const dobRegex = /^\d{2}-\d{2}-\d{4}$/;
        if (!dobRegex.test(dobString)) {
            return false; // Invalid format
        }
        try {
            // Need to rearrange MM-DD-YYYY to YYYY-MM-DD for reliable Date parsing
            const parts = dobString.split('-');
            const year = parseInt(parts[2], 10);
            const month = parseInt(parts[0], 10) - 1; // Month is 0-indexed
            const day = parseInt(parts[1], 10);
            const dob = new Date(year, month, day);

            // Check if the parsed date matches the input parts (handles invalid dates like 02-30-2024)
            if (dob.getFullYear() !== year || dob.getMonth() !== month || dob.getDate() !== day) {
                 return false; // Invalid date components
            }

            const today = new Date();
            // Clear time part for accurate date comparison
            today.setHours(0, 0, 0, 0);
            // Check if dob is a valid date and is before today
            return !isNaN(dob.getTime()) && dob < today;
        } catch (e) {
            return false; // Error parsing date
        }
    }
    // --- End Validation Functions ---

    ScrollView { // Added ScrollView for potentially longer content
        anchors.fill: parent
        contentWidth: parent.width
        clip: true

        ColumnLayout {
            width: parent.width * 0.9 // Slightly wider for more fields
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 30
            spacing: 15

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Create Account"
                font.pixelSize: 24
                font.bold: true
                color: "white"
            }

            // --- Decorative Fields ---
            // Removed Nickname Field
            TextField {
                Layout.fillWidth: true
                placeholderText: "Email (Optional)"
                color: "white"
                background: Rectangle { color: "#374151"; radius: 4; border.color: "#4b5563" }
                placeholderTextColor: "#9ca3af"
            }
             TextField {
                Layout.fillWidth: true
                placeholderText: "Name (Optional)"
                color: "white"
                background: Rectangle { color: "#374151"; radius: 4; border.color: "#4b5563" }
                placeholderTextColor: "#9ca3af"
            }
             TextField {
                id: dobInput // Give DOB field an ID
                Layout.fillWidth: true
                placeholderText: "Date of Birth (MM-DD-YYYY)" // Hint format
                inputMask: "00-00-0000" // Automatically format input
                maximumLength: 10 // Limit length
                color: "white"
                background: Rectangle { color: "#374151"; radius: 4; border.color: "#4b5563" }
                placeholderTextColor: "#9ca3af"
            }
            // --- End Decorative Fields ---

            TextField {
                id: usernameInput
                Layout.fillWidth: true
                placeholderText: "Username*"
                color: "white"
                background: Rectangle { color: "#374151"; radius: 4; border.color: "#4b5563" }
                placeholderTextColor: "#9ca3af"
            }

            TextField {
                id: passwordInput
                Layout.fillWidth: true
                placeholderText: "Password*"
                echoMode: TextInput.Password
                color: "white"
                background: Rectangle { color: "#374151"; radius: 4; border.color: "#4b5563" }
                placeholderTextColor: "#9ca3af"
            }

            TextField {
                id: confirmPasswordInput
                Layout.fillWidth: true
                placeholderText: "Confirm Password*"
                echoMode: TextInput.Password
                color: "white"
                background: Rectangle { color: "#374151"; radius: 4; border.color: "#4b5563" }
                placeholderTextColor: "#9ca3af"
            }

            // Status Message Area
            Text {
                id: statusText
                Layout.fillWidth: true
                text: registerRoot.statusMessage
                color: statusMessage.startsWith("Error") ? "red" : "lightgreen"
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                visible: statusMessage !== ""
            }

            Button {
                id: registerButton
                Layout.fillWidth: true
                text: "Register"
                onClicked: {
                    registerRoot.statusMessage = ""; // Clear previous message

                    // Validation
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
                    // --- Add DOB Validation ---
                    if (dobInput.text !== "" && dobInput.text !== "__-__-____" && !isValidDateOfBirth(dobInput.text)) { // Check mask isn't empty
                        registerRoot.statusMessage = "Error: Invalid Date of Birth (must be MM-DD-YYYY and in the past)";
                        return;
                    }
                    // --- End DOB Validation ---

                    registerRoot.statusMessage = "Registering...";
                    CallAPI.registerUser(usernameInput.text, passwordInput.text, (regSuccess, regMessage) => {
                        if (regSuccess) {
                            registerRoot.statusMessage = "Registration successful. Logging in...";
                            CallAPI.loginUser(usernameInput.text, passwordInput.text, (loginSuccess, tokenOrError) => {
                                if (loginSuccess) {
                                    registerRoot.statusMessage = "Registration & Login Successful!";
                                    // Pass back username along with token
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

            Button {
                Layout.fillWidth: true
                text: "Back to Login"
                flat: true // Make it look less prominent
                onClicked: {
                    registerRoot.backToLoginRequested();
                }
            }

             // Bottom padding
            Item { Layout.preferredHeight: 30 }
        }
    }
}