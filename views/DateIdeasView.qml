import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    width: parent.width
    height: parent.height
    
    // Properties
    property var dateIdeas: []
    property int currentIndex: 0
    property bool reviewMode: false
    property var userResponses: []  // Array to store user responses: {idea: string, response: "yes"|"no"|"maybe"}
    property int reviewIndex: 0     // Index for reviewing responses
    
    // Debug properties - remove in production
    property bool debugShowExampleResponses: true
    
    // Signals
    signal dateIdeaResponse(string response)
    signal userResponsesUpdated() // Signal to trigger when responses are updated
    
    // Animation properties
    property real initialX: 0
    property real initialY: 0
    property real dragThreshold: width * 0.35 // Threshold to detect swipe left/right
    
    // Stack view to switch between card view and list view
    StackLayout {
        anchors.fill: parent
        currentIndex: reviewMode ? 1 : 0
        
        // Card View (normal mode)
        Item {
            id: cardView
            width: parent.width
            height: parent.height
            
            // Header
            Rectangle {
                id: header
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    leftMargin: 16
                    rightMargin: 16
                    topMargin: 16
                }
                height: 60
                color: "transparent"
                
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
                anchors {
                    top: header.bottom
                    horizontalCenter: parent.horizontalCenter
                    topMargin: 5
                }
                text: "Swipe right for Yes, left for No, up for Maybe"
                font.pixelSize: 14
                color: "#9ca3af" // gray-400
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
                    anchors {
                        right: parent.right
                        top: parent.top
                        margins: 20
                    }
                    width: 100
                    height: 40
                    radius: 20
                    color: "#16a34a" // green-600
                    opacity: 0
                    rotation: 30
                    
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
                    anchors {
                        left: parent.left
                        top: parent.top
                        margins: 20
                    }
                    width: 100
                    height: 40
                    radius: 20
                    color: "#dc2626" // red-600
                    opacity: 0
                    rotation: -30
                    
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
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: parent.top
                        topMargin: 20
                    }
                    width: 100
                    height: 40
                    radius: 20
                    color: "#d97706" // yellow-600
                    opacity: 0
                    
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
                    x: (parent.width - width) / 2  // Center horizontally
                    y: (parent.height - height) / 2  // Center vertically
                    color: "#1f1f1f" // gray-800
                    radius: 16
                    
                    // Add gradient border effect
                    Rectangle {
                        id: borderEffect
                        anchors.fill: parent
                        anchors.margins: -2
                        radius: 18
                        z: -1
                        
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#ec4899" } // pink-600
                            GradientStop { position: 1.0; color: "#db2777" } // pink-700
                        }
                    }
                    
                    // Card content
                    ColumnLayout {
                        anchors {
                            fill: parent
                            margins: 20
                        }
                        spacing: 20
                        
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
                            text: root.dateIdeas.length > 0 ? root.dateIdeas[root.currentIndex] : ""
                            font.pixelSize: 28
                            color: "white"
                            wrapMode: Text.Wrap
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
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
                    
                    // Swipe animations
                    transform: [
                        Rotation {
                            id: rotationTransform
                            origin.x: card.width / 2
                            origin.y: card.height / 2
                            axis { x: 0; y: 0; z: 1 }
                            angle: 0
                        },
                        Scale {
                            id: scaleTransform
                            origin.x: card.width / 2
                            origin.y: card.height / 2
                            xScale: 1.0
                            yScale: 1.0
                        }
                    ]
                    
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
                                root.dateIdeaResponse("yes");
                            } else if (xDiff < -root.dragThreshold) {
                                // Swiped left (No)
                                animateOut("left");
                                root.dateIdeaResponse("no");
                            } else if (yDiff < -root.dragThreshold) {
                                // Swiped up (Maybe)
                                animateOut("up");
                                root.dateIdeaResponse("maybe");
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
                                yesIndicator.opacity = Math.min(Math.abs(xDiff) / root.dragThreshold, 1.0);
                                noIndicator.opacity = 0;
                                maybeIndicator.opacity = 0;
                            } else if (xDiff < 0) {
                                // Swiping left - show NO
                                noIndicator.opacity = Math.min(Math.abs(xDiff) / root.dragThreshold, 1.0);
                                yesIndicator.opacity = 0;
                                maybeIndicator.opacity = 0;
                            } else if (yDiff < 0) {
                                // Swiping up - show MAYBE
                                maybeIndicator.opacity = Math.min(Math.abs(yDiff) / root.dragThreshold, 1.0);
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
        
        // Results list view (review mode)
        Item {
            id: resultsView
            width: parent.width
            height: parent.height
            
            // Header
            Rectangle {
                id: resultsHeader
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    leftMargin: 16
                    rightMargin: 16
                    topMargin: 16
                }
                height: 60
                color: "transparent"
                
                Text {
                    anchors.centerIn: parent
                    text: "🔄 Your Responses"
                    font.pixelSize: 24
                    font.bold: true
                    color: "white"
                }
            }
            
            // Info text
            Text {
                id: resultInfo
                anchors {
                    top: resultsHeader.bottom
                    horizontalCenter: parent.horizontalCenter
                    topMargin: 5
                }
                text: responsesList.count > 0 
                      ? "Here are all your responses (" + responsesList.count + ")" 
                      : "No responses yet"
                font.pixelSize: 14
                color: "#9ca3af" // gray-400
            }
            
            // Results list
            ScrollView {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: resultInfo.bottom
                    bottom: parent.bottom
                    topMargin: 10
                    leftMargin: 16
                    rightMargin: 16
                    bottomMargin: 16
                }
                clip: true
                ScrollBar.vertical.policy: ScrollBar.AlwaysOff
                
                ListView {
                    id: responsesList
                    anchors.fill: parent
                    model: ListModel {
                        id: responsesModel
                    }
                    spacing: 20  // Increased spacing between items
                    
                    Component.onCompleted: {
                        updateResponsesList();
                    }
                    
                    delegate: Rectangle {
                        width: Math.min(responsesList.width, 320)  // Set a static max width
                        height: delegateLayout.implicitHeight + 30
                        radius: 12
                        color: "#1f1f1f" // gray-800
                        anchors.horizontalCenter: parent.horizontalCenter // Center in the list
                        
                        // Colored border based on response
                        Rectangle {
                            id: responseBorder
                            anchors.fill: parent
                            z: -1
                            radius: 14
                            gradient: Gradient {
                                GradientStop { 
                                    position: 0.0
                                    color: {
                                        if (model.response === "yes") return "#16a34a"; // green-600
                                        else if (model.response === "no") return "#dc2626"; // red-600
                                        else return "#d97706"; // yellow-600
                                    }
                                }
                                GradientStop { 
                                    position: 1.0
                                    color: {
                                        if (model.response === "yes") return "#15803d"; // green-700
                                        else if (model.response === "no") return "#b91c1c"; // red-700
                                        else return "#b45309"; // yellow-700
                                    }
                                }
                            }
                            anchors.margins: -2
                        }
                        
                        RowLayout {
                            id: delegateLayout
                            anchors {
                                fill: parent
                                margins: 12  // Reduced margins from 16 to 12
                            }
                            spacing: 12
                            
                            // Response emoji
                            Text {
                                text: {
                                    if (model.response === "yes") return "👍";
                                    else if (model.response === "no") return "👎";
                                    else return "🤔";
                                }
                                font.pixelSize: 28  // Reduced size from 32 to 28
                                Layout.preferredWidth: 36  // Reduced width from 40 to 36
                            }
                            
                            // Date idea
                            Text {
                                text: model.idea || "No idea specified"
                                font.pixelSize: 16  // Reduced size from 18 to 16
                                color: "white"
                                wrapMode: Text.Wrap
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                            }
                            
                            // Response badge
                            Rectangle {
                                Layout.preferredWidth: 70  // Reduced width from 80 to 70
                                Layout.preferredHeight: 26  // Reduced height from 30 to 26
                                radius: 13  // Reduced from 15 to 13
                                color: {
                                    if (model.response === "yes") return "#16a34a"; // green-600
                                    else if (model.response === "no") return "#dc2626"; // red-600
                                    else return "#d97706"; // yellow-600
                                }
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: model.response ? model.response.toUpperCase() : "MAYBE"
                                    font.pixelSize: 12  // Reduced size from 14 to 12
                                    font.bold: true
                                    color: "white"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Debug sample data (for testing purposes)
    property var debugResponses: [
        { idea: "Go for a hike in a nearby nature reserve", response: "yes" },
        { idea: "Cook a new recipe together", response: "yes" },
        { idea: "Visit a local museum or art gallery", response: "maybe" },
        { idea: "Have a picnic in the park", response: "yes" },
        { idea: "Take a dance class together", response: "no" }
    ]
    
    // Function to update the responses list
    function updateResponsesList() {
        //console.log("Updating responses list, total responses: " + root.userResponses.length);
        
        // Clear the model
        responsesModel.clear();
        
        // Add each response to the model
        if (root.userResponses.length > 0) {
            for (var i = 0; i < root.userResponses.length; i++) {
                var response = root.userResponses[i];
                responsesModel.append({
                    "idea": response.idea,
                    "response": response.response
                });
                //console.log("Added to list model: " + response.idea + " - " + response.response);
            }
        } else if (debugShowExampleResponses) {
            // Add debug responses if no actual responses
            for (var j = 0; j < debugResponses.length; j++) {
                responsesModel.append({
                    "idea": debugResponses[j].idea,
                    "response": debugResponses[j].response
                });
            }
        }
        
        // Emit signal that responses were updated
        root.userResponsesUpdated();
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
    
    // Animation for card exit
    ParallelAnimation {
        id: exitAnimation
        property real xTo: 0
        property real yTo: 0
        property real rotationTo: 0
        
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
        
        onFinished: {
            // Store the user response for the current idea
            if (root.currentIndex < root.dateIdeas.length) {
                var lastResponse = "";
                if (exitAnimation.xTo > root.width) lastResponse = "yes";
                else if (exitAnimation.xTo < 0) lastResponse = "no";
                else lastResponse = "maybe";
                
                // Store response in the array
                root.userResponses.push({
                    idea: root.dateIdeas[root.currentIndex],
                    response: lastResponse
                });
                
                // Improved logging with JSON.stringify for better object inspection
                //console.log("Added response: " + lastResponse + " for idea: " + root.dateIdeas[root.currentIndex]);
                //console.log("Last added response object: " + JSON.stringify(root.userResponses[root.userResponses.length - 1]));
                //console.log("Total responses: " + root.userResponses.length);
            }
            
            // Move to next card
            root.currentIndex++;
            
            // Check if we've gone through all ideas
            if (root.currentIndex >= root.dateIdeas.length) {
                // Update the responses list before switching to review mode
                updateResponsesList();
                
                // Switch to review mode
                root.reviewMode = true;
                //console.log("Switching to review mode. Total responses: " + root.userResponses.length);
                
                // Print all response objects for debugging
                //console.log("All responses:");
                for (var i = 0; i < root.userResponses.length; i++) {
                    //console.log("Response " + i + ": " + JSON.stringify(root.userResponses[i]));
                }
            } else {
                // Reset card position and appearance
                card.x = root.initialX;
                card.y = root.initialY;
                rotationTransform.angle = 0;
                card.opacity = 1;
                yesIndicator.opacity = 0;
                noIndicator.opacity = 0;
                maybeIndicator.opacity = 0;
            }
        }
    }
    
    // Initialize with first card content
    Component.onCompleted: {
        if (dateIdeas.length > 0) {
            root.initialX = (cardContainer.width - card.width) / 2;
            root.initialY = (cardContainer.height - card.height) / 2;
        }
        
        // Connect reviewMode property change to update responses list
        root.onReviewModeChanged.connect(function() {
            if (root.reviewMode) {
                updateResponsesList();
            }
        });
    }
}