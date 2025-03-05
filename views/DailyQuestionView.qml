import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    width: parent.width
    height: parent.height
    
    // Properties
    property string dailyQuestion: "What moment today made you smile?"
    property string currentResponse: ""
    property string apiKey_: ""
    // Signals
    signal submitResponse(string response)
    signal getAPIKEY

    API_Key {
        onSendAPISIG: function(apiKey) {
            root.apiKey_ = apiKey
            getDailyQuestion()
        }
    }

    // Function to fetch the daily question from the server
    function getDailyQuestion() {
            var xhr = new XMLHttpRequest();
            // Replace with your actual API key from API Ninjas
            var apiKey = root.apiKey_;
            // Set the API endpoint and request headers
            xhr.open("GET", "https://api.api-ninjas.com/v1/trivia");
            xhr.setRequestHeader("X-Api-Key", apiKey);  // Set your API key here

            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 200) {
                        // Parse the JSON response and update the dailyQuestion property
                        var response = JSON.parse(xhr.responseText);
                        dailyQuestion = response[0].question;  // Assuming the question is the first item in the array
                    } else {
                        console.log("Error:", xhr.status, xhr.responseText);
                        dailyQuestion = "Not able to load";
                    }
                }
            };

            xhr.send();  // Send the GET request asynchronously
    }
    
    ColumnLayout {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            margins: 16
        }
        spacing: 20
        // Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            color: "transparent"
            
            Text {
                anchors.centerIn: parent
                text: "❓ Daily Connection Question"
                font.pixelSize: 24
                font.bold: true
                color: "white"
            }
        }
        
        // Question
        Text {
            Layout.fillWidth: true
            text: root.dailyQuestion
            font.pixelSize: 22
            color: "white"
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
        }
        
        // Response text area
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 200
            color: "#1f1f1f" // gray-800
            radius: 8
            
            ScrollView {
                id: scrollView
                anchors.fill: parent
                anchors.margins: 8
                clip: true
                
                TextArea {
                    id: responseTextArea
                    placeholderText: "Share your thoughts..."
                    wrapMode: TextEdit.Wrap
                    color: "white"
                    background: null
                    
                    onTextChanged: {
                        root.currentResponse = text
                    }
                }
            }
        }
        
        // Submit button
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            color: "#ec4899" // pink-600
            radius: 8
            
            Text {
                anchors.centerIn: parent
                text: "Share with Partner 💖"
                font.pixelSize: 16
                font.bold: true
                color: "white"
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (root.currentResponse.trim() !== "") {
                        root.submitResponse(root.currentResponse)
                        responseTextArea.text = ""
                        root.getDailyQuestion()
                    }
                }
            }
        }
        
        // Spacer
        Item {
            Layout.fillHeight: true
        }
    }
}
