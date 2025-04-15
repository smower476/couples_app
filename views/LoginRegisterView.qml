import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: loginRegisterRoot
    width: parent.width
    height: parent.height

    // Signals to notify the parent (main.qml)
    signal loginRequested(string username, string password)
    signal registerRequested(string username, string password)

    ColumnLayout {
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

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Button {
                id: loginButton
                Layout.fillWidth: true
                text: "Login"
                onClicked: {
                    console.log("Login clicked:", usernameInput.text)
                    // Emit signal with credentials
                    loginRegisterRoot.loginRequested(usernameInput.text, passwordInput.text)
                }
            }

            Button {
                id: registerButton
                Layout.fillWidth: true
                text: "Register"
                onClicked: {
                    console.log("Register clicked:", usernameInput.text)
                    // Emit signal with credentials
                    loginRegisterRoot.registerRequested(usernameInput.text, passwordInput.text)
                }
            }
        }
    }
}