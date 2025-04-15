import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: profileRoot
    width: parent.width
    height: parent.height

    // Signal to notify parent (main.qml)
    signal logoutRequested()

    // Property to receive display info from parent
    property string displayInfo: "Username: [Default]"

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 20

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "User Profile"
            font.pixelSize: 24
            font.bold: true
            color: "white"
        }

        Text {
            id: usernameText
            Layout.alignment: Qt.AlignHCenter
            text: profileRoot.displayInfo // Bind to the new property
            font.pixelSize: 18
            color: "white"
        }

        Button {
            id: logoutButton
            Layout.alignment: Qt.AlignHCenter
            text: "Logout"
            onClicked: {
                console.log("Logout clicked")
                // Emit signal
                profileRoot.logoutRequested()
            }
        }
    }
}