pragma ComponentBehavior: Bound
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    width: parent.width
    height: parent.height

    Column {
        anchors.centerIn: parent
        spacing: 20
        width: parent.width * 0.8

        Text {
            width: parent.width
            text: "🤔 Loading Quiz..."
            font.pixelSize: 24
            font.bold: true
            color: "white"
            horizontalAlignment: Text.AlignHCenter
        }

        BusyIndicator {
            anchors.horizontalCenter: parent.horizontalCenter
            running: true
            palette.dark: "#ec4899"
        }

        Text {
            width: parent.width
            text: "Fetching your daily quiz..."
            font.pixelSize: 16
            color: "#9ca3af"
            horizontalAlignment: Text.AlignHCenter
        }
    }
}