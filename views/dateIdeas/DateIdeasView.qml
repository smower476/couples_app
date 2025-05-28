import "../CallAPI.js" as CallAPI
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    // Signal to trigger when responses are updated
    //console.log("Updating responses list, total responses: " + root.userResponses.length);
    // Debug sample data (for testing purposes)

    id: root

    // Properties
    property var dateIdeas: []
    property int currentIndex: 0
    property var userResponses: [] // Array to store user responses: {idea: string, response: "yes"|"no"|"maybe"}
    property int reviewIndex: 0 // Index for reviewing responses
    property string jwtToken: "" // JWT token for API authentication
    // Debug properties - remove in production
    property bool debugShowExampleResponses: true
    // Animation properties
    property real initialX: 0
    property real initialY: 0
    property real dragThreshold: width * 0.35 // Threshold to detect swipe left/right

    // Signals
    signal finishedDateIdeasReview()

    function getDateIdeas() {
        // Example API response structure:
        //           [
        //     {
        //       "idea_id": "string",
        //       "title": "string",
        //       "description": "string",
        //     }
        //     // ...
        //   ]
        CallAPI.makeApiRequest("/get-date-ideas", "token=" + root.jwtToken, function(reqSuccess, response) {
            if (reqSuccess) {
                if (response && response.length > 0) {
                    console.log("Received date ideas: " + JSON.stringify(response));
                    console.log("type of response: " + typeof response);
                    // Make sure we're working with actual JSON objects, not a string
                    if (typeof response === 'string') {
                        try {
                            response = JSON.parse(response);
                            console.log("Parsed response from string to JSON object");
                        } catch (e) {
                            console.error("Failed to parse response string to JSON: " + e);
                        }
                    }
                    root.dateIdeas = Array.isArray(response) ? response.map(function(idea) {
                        return {
                            "id": idea.id,
                            "title": idea.title,
                            "description": idea.description || ""
                        };
                    }) : Object.values(response).map(function(idea) {
                        return {
                            "id": idea.id,
                            "title": idea.title,
                            "description": idea.description || ""
                        };
                    });
                    if (root.dateIdeas.length === 0) {
                        console.warn("No date ideas found in response.");
                        root.finishedDateIdeasReview();
                    }
                    console.log("Date ideas loaded: " + JSON.stringify(root.dateIdeas));
                    root.currentIndex = 0; // Reset index to start from first idea
                    console.log("Date ideas loaded: " + root.dateIdeas.length);
                } else {
                    console.error("No date ideas found in response.");
                }
            } else {
                console.error("Failed to fetch date ideas: " + response);
            }
        }, "POST");
    }

    function submitAnswerAPI(id, response) {
        if (!root.jwtToken || root.jwtToken === "") {
            console.error("JWT Token is not set, cannot submit response.");
            return ;
        }
        var currentIdea = root.dateIdeas[root.currentIndex];
        if (!currentIdea) {
            console.error("No current date idea to submit response for.");
            return ;
        }
        console.log("ID: " + id + ", Response: " + response);
        CallAPI.makeApiRequest("/submit-date-idea", "token=" + root.jwtToken + "&idea_id=" + id + "&answer=" + response, function(reqSuccess, response) {
            if (reqSuccess) {
                console.log("Response submitted successfully: " + response);
            } else {
                console.error("Failed to submit response: " + response);
                console.error("Response from server: " + JSON.stringify(response));
            }
        }, "POST");
    }

    // Function to animate card out in a given direction
    function animateOut(direction) {
        exitAnimation.stop();
        if (direction === "right") {
            exitAnimation.xTo = root.width + card.width;
            exitAnimation.yTo = card.y;
            exitAnimation.rotationTo = 30;
        } else if (direction === "left") {
            exitAnimation.xTo = -card.width;
            exitAnimation.yTo = card.y;
            exitAnimation.rotationTo = -30;
        } else if (direction === "up") {
            exitAnimation.xTo = card.x;
            exitAnimation.yTo = -card.height;
            exitAnimation.rotationTo = 0;
        }
        exitAnimation.start();
    }

    width: parent.width
    height: parent.height
    // Initialize with first card content
    Component.onCompleted: {
        if (dateIdeas.length > 0) {
            root.initialX = (cardContainer.width - card.width) / 2;
            root.initialY = (cardContainer.height - card.height) / 2;
        }
    }

    Connections {
        function onJwtTokenChanged() {
            if (root.jwtToken && root.jwtToken !== "") {
                console.log("JWT Token is set DateIdeas: " + root.jwtToken);
                root.getDateIdeas();
            } else {
                root.initialX = (cardContainer.width - card.width) / 2;
                root.initialY = (cardContainer.height - card.height) / 2;
                root.dateIdeas = [];
                root.userResponses = [];
                root.currentIndex = 0;
                card.x = root.initialX;
                card.y = root.initialY;
                rotationTransform.angle = 0;
                card.opacity = 1;
                yesIndicator.opacity = 0;
                noIndicator.opacity = 0;
                maybeIndicator.opacity = 0;
                console.warn("JWT Token is not set, resetting date ideas and responses.");
            }
        }

        target: root
    }
    // Card View (normal mode)

    Item {
        id: cardView

        width: parent.width
        height: parent.height

        // Header
        Rectangle {
            id: header

            height: 60
            color: "transparent"

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: 16
                rightMargin: 16
                topMargin: 16
            }

            Text {
                anchors.centerIn: parent
                text: "🌟 Date Idea Picker"
                font.pixelSize: 24
                font.bold: true
                color: "white"
            }

        }

        // Swipe instructions
        Text {
            id: instructions

            text: "Swipe right for Yes, left for No, up for Maybe"
            font.pixelSize: 14
            color: "#9ca3af" // gray-400

            anchors {
                top: header.bottom
                horizontalCenter: parent.horizontalCenter
                topMargin: 5
            }

        }

        // Container for card and indicators
        Item {
            id: cardContainer

            anchors {
                left: parent.left
                right: parent.right
                top: instructions.bottom
                bottom: parent.bottom
                topMargin: 10
                leftMargin: 20
                rightMargin: 20
                bottomMargin: 20
            }

            // Swipe Indicators (hidden initially)
            Rectangle {
                id: yesIndicator

                width: 100
                height: 40
                radius: 20
                color: "#16a34a" // green-600
                opacity: 0
                rotation: 30

                anchors {
                    right: parent.right
                    top: parent.top
                    margins: 20
                }

                Text {
                    anchors.centerIn: parent
                    text: "YES 👍"
                    font.pixelSize: 16
                    font.bold: true
                    color: "white"
                }

            }

            Rectangle {
                id: noIndicator

                width: 100
                height: 40
                radius: 20
                color: "#dc2626" // red-600
                opacity: 0
                rotation: -30

                anchors {
                    left: parent.left
                    top: parent.top
                    margins: 20
                }

                Text {
                    anchors.centerIn: parent
                    text: "NO 👎"
                    font.pixelSize: 16
                    font.bold: true
                    color: "white"
                }

            }

            Rectangle {
                id: maybeIndicator

                width: 100
                height: 40
                radius: 20
                color: "#d97706" // yellow-600
                opacity: 0

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                    topMargin: 20
                }

                Text {
                    anchors.centerIn: parent
                    text: "MAYBE 🤔"
                    font.pixelSize: 16
                    font.bold: true
                    color: "white"
                }

            }

            // Card
            Rectangle {
                id: card

                width: parent.width * 0.9
                height: parent.height * 0.7
                x: (parent.width - width) / 2 // Center horizontally
                y: (parent.height - height) / 2 // Center vertically
                color: "#1f1f1f" // gray-800
                radius: 16
                // Swipe animations
                transform: [
                    Rotation {
                        id: rotationTransform

                        origin.x: card.width / 2
                        origin.y: card.height / 2
                        angle: 0

                        axis {
                            x: 0
                            y: 0
                            z: 1
                        }

                    },
                    Scale {
                        id: scaleTransform

                        origin.x: card.width / 2
                        origin.y: card.height / 2
                        xScale: 1
                        yScale: 1
                    }
                ]

                // Add gradient border effect
                Rectangle {
                    id: borderEffect

                    anchors.fill: parent
                    anchors.margins: -2
                    radius: 18
                    z: -1

                    gradient: Gradient {
                        // pink-600
                        GradientStop {
                            position: 0
                            color: "#ec4899"
                        }

                        // pink-700
                        GradientStop {
                            position: 1
                            color: "#db2777"
                        }

                    }

                }

                // Card content
                ColumnLayout {
                    spacing: 20

                    anchors {
                        fill: parent
                        margins: 20
                    }

                    // Date idea emoji
                    Text {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 80
                        text: !root.dateIdeas.length ? "" : "🌟"
                        font.pixelSize: 72
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                    }

                    // Date idea text
                    Text {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        text: root.dateIdeas.length > 0 ? root.dateIdeas[root.currentIndex].title : ""
                        font.pixelSize: 28
                        color: "white"
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    // Date idea description
                    Text {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        text: root.dateIdeas.length > 0 ? (root.dateIdeas[root.currentIndex].description || "No description available") : ""
                        font.pixelSize: 16
                        color: "#9ca3af" // gray-400
                        wrapMode: Text.Wrap
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        maximumLineCount: 6
                        width: parent.width - 20
                    }

                    // Swipe icons hint
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignBottom
                        spacing: 30

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "👈 No"
                            font.pixelSize: 16
                            color: "#9ca3af" // gray-400
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "👆 Maybe"
                            font.pixelSize: 16
                            color: "#9ca3af" // gray-400
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Yes 👉"
                            font.pixelSize: 16
                            color: "#9ca3af" // gray-400
                        }

                    }

                }

                // Handle touch interactions
                MouseArea {
                    id: dragArea

                    anchors.fill: parent
                    drag.target: card
                    drag.axis: Drag.XAndY
                    onPressed: {
                        root.initialX = card.x;
                        root.initialY = card.y;
                    }
                    onReleased: {
                        var xDiff = card.x - root.initialX;
                        var yDiff = card.y - root.initialY;
                        if (xDiff > root.dragThreshold) {
                            // Swiped right (Yes)
                            animateOut("right");
                            root.submitAnswerAPI(root.dateIdeas[root.currentIndex].id, "yes");
                        } else if (xDiff < -root.dragThreshold) {
                            // Swiped left (No)
                            animateOut("left");
                            root.submitAnswerAPI(root.dateIdeas[root.currentIndex].id, "no");
                        } else if (yDiff < -root.dragThreshold) {
                            // Swiped up (Maybe)
                            animateOut("up");
                            root.submitAnswerAPI(root.dateIdeas[root.currentIndex].id, "maybe");
                        } else {
                            // Return to center
                            resetPosition.start();
                        }
                    }
                    onPositionChanged: {
                        var xDiff = card.x - root.initialX;
                        var yDiff = card.y - root.initialY;
                        // Rotate card based on horizontal movement
                        rotationTransform.angle = xDiff * 0.05;
                        if (xDiff > 0) {
                            // Swiping right - show YES
                            yesIndicator.opacity = Math.min(Math.abs(xDiff) / root.dragThreshold, 1);
                            noIndicator.opacity = 0;
                            maybeIndicator.opacity = 0;
                        } else if (xDiff < 0) {
                            // Swiping left - show NO
                            noIndicator.opacity = Math.min(Math.abs(xDiff) / root.dragThreshold, 1);
                            yesIndicator.opacity = 0;
                            maybeIndicator.opacity = 0;
                        } else if (yDiff < 0) {
                            // Swiping up - show MAYBE
                            maybeIndicator.opacity = Math.min(Math.abs(yDiff) / root.dragThreshold, 1);
                            yesIndicator.opacity = 0;
                            noIndicator.opacity = 0;
                        } else {
                            // Reset all
                            yesIndicator.opacity = 0;
                            noIndicator.opacity = 0;
                            maybeIndicator.opacity = 0;
                        }
                    }
                }

            }

        }

    }

    // Animation to reset card position
    ParallelAnimation {
        id: resetPosition

        PropertyAnimation {
            target: card
            property: "x"
            to: initialX
            duration: 200
            easing.type: Easing.OutQuad
        }

        PropertyAnimation {
            target: card
            property: "y"
            to: initialY
            duration: 200
            easing.type: Easing.OutQuad
        }

        PropertyAnimation {
            target: rotationTransform
            property: "angle"
            to: 0
            duration: 200
            easing.type: Easing.OutQuad
        }

        PropertyAnimation {
            target: yesIndicator
            property: "opacity"
            to: 0
            duration: 200
        }

        PropertyAnimation {
            target: noIndicator
            property: "opacity"
            to: 0
            duration: 200
        }

        PropertyAnimation {
            target: maybeIndicator
            property: "opacity"
            to: 0
            duration: 200
        }

    }

    // Animation for card exit
    ParallelAnimation {
        // Improved logging with JSON.stringify for better object inspection
        //console.log("Added response: " + lastResponse + " for idea: " + root.dateIdeas[root.currentIndex]);
        //console.log("Last added response object: " + JSON.stringify(root.userResponses[root.userResponses.length - 1]));
        //console.log("Total responses: " + root.userResponses.length);

        id: exitAnimation

        property real xTo: 0
        property real yTo: 0
        property real rotationTo: 0

        onFinished: {
            // Store the user response for the current idea
            if (root.currentIndex < root.dateIdeas.length - 1) {
                var lastResponse = "";
                if (exitAnimation.xTo > root.width)
                    lastResponse = "yes";
                else if (exitAnimation.xTo < 0)
                    lastResponse = "no";
                else
                    lastResponse = "maybe";
                // Store response in the array
                root.userResponses.push({
                    "idea": root.dateIdeas[root.currentIndex],
                    "response": lastResponse
                });
                // Move to next card
                root.currentIndex++;
                console.log("Current index after response: " + root.currentIndex);
                card.x = root.initialX;
                card.y = root.initialY;
                rotationTransform.angle = 0;
                card.opacity = 1;
                yesIndicator.opacity = 0;
                noIndicator.opacity = 0;
                maybeIndicator.opacity = 0;
            } else {
                console.log("No more date ideas available, finishing review.");
                root.finishedDateIdeasReview();
            }
        }

        PropertyAnimation {
            target: card
            property: "x"
            to: exitAnimation.xTo
            duration: 300
            easing.type: Easing.OutQuad
        }

        PropertyAnimation {
            target: card
            property: "y"
            to: exitAnimation.yTo
            duration: 300
            easing.type: Easing.OutQuad
        }

        PropertyAnimation {
            target: rotationTransform
            property: "angle"
            to: exitAnimation.rotationTo
            duration: 300
            easing.type: Easing.OutQuad
        }

        PropertyAnimation {
            target: card
            property: "opacity"
            to: 0
            duration: 300
        }

    }

}
