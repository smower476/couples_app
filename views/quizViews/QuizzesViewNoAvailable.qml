pragma ComponentBehavior: Bound
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    width: parent.width
    height: parent.height

    signal backToHub()

    Rectangle {
        anchors.fill: parent
        anchors.margins: 20
        color: "#1f1f1f"
        radius: 10

        Column {
            anchors.centerIn: parent
            spacing: 20
            width: parent.width * 0.8

            Text {
                width: parent.width
                text: "😴 No Quizzes Available"
                font.pixelSize: 24
                font.bold: true
                color: "white"
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                width: parent.width
                text: "You've completed today's quiz already. Come back tomorrow for a new one!"
                font.pixelSize: 16
                color: "#d1d5db"
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }

            Rectangle {
                height: 1
                width: parent.width * 0.8
                color: "#4b5563"
                anchors.horizontalCenter: parent.horizontalCenter
                radius: 0.5
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Back to Hub"
                background: Rectangle {
                    implicitWidth: 200
                    implicitHeight: 50
                    radius: 25
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#ec4899" }
                        GradientStop { position: 1.0; color: "#db2777" }
                    }
                }
                contentItem: Text {
                    text: parent.text
                    font.pixelSize: 16
                    font.bold: true
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: root.backToHub()
            }
        }
    }
}