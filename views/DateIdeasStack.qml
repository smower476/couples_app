import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import "./dateIdeas/"


StackLayout {
    id: root
    anchors.fill: parent
    property string jwtToken: ""
    property string errorMessage: ""
    property string currentView: "DateIdeasPicker" // "DateIdeasPicker", "DateIdeasResult", "error"

    Connections {
        function onJwtTokenChanged() {
            if (root.jwtToken && root.jwtToken !== "") {
                console.log("JWT Token is set DateIdeas: " + root.jwtToken);
                root.currentView = "DateIdeasPicker";
            } else {
                root.responsesList = [];
                console.error("JWT Token is not set or empty");
            }
        }

        target: root
    }

    currentIndex: {
        switch (root.currentView) {
        case "DateIdeasPicker":
            return 0
        case "DateIdeasResult":
            return 1
        case "error":
            return 2
        default:
            return 0
        }
    }

    DateIdeasView {
        id: dateIdeasView
        jwtToken: root.jwtToken
        onFinishedDateIdeasReview : function() {
            root.currentView = "DateIdeasResult";
        }
    }

    DateIdeasResults {
        id: dateIdeasResults
        jwtToken: root.jwtToken
    }
}
