import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../CallAPI.js" as CallAPI


Item {
    id: root
    anchors.fill: parent
    property string dailyQuestion: ""
    property string dailyQuestionId: ""
    property string currentResponse: ""
    property string jwtToken: ""
    signal submitResponse(string response, string question)
    signal switchToDifferentView(string view, var parameters)

    Connections {
        target: root
        function onJwtTokenChanged() {
            if (root.jwtToken && root.jwtToken !== "") {
                console.log("JWT Token is set: " + root.jwtToken);
                // root.getDailyQuestion();
            } else {
                root.quizData = null;
                root.completedQuizData = null;
                root.currentQuizState = "no_available";
            }
        }
    }

    function getDailyQuestion() {
        //makeApiRequest(endpoint, params, callback, method = "POST")
        //           [  
        //     {  
        //       "question_id": "string",      // Уникальный идентификатор вопроса  
        //       "question": "string",         // Текст вопроса викторины  
        //       "user_answer": "string",      // Ответ Пользователя А 
            //   "user_timestamp": timestamp  // Время ответа Пользователя А
        //       "partner_answer": "string\_or\_null" // Ответ Пользователя Б (или null, если нет ответа) 
        //       "partner_timestamp": timestamp // Время ответа Пользователя Б (или null, если нет ответа) 
        //     }  
        //     // ... другие объекты викторин, если они соответствуют критериям  
        //   ]
        var should_getDailyQuestion = true;
        request = CallAPI.makeApiRequest(
            "/get-daily-questions-answered",
            "token=" + root.jwtToken,
            function (reqSuccess, response) {
                if (reqSuccess) {
                    if (response && response.length > 0) {
                        // Sort by date answered (choose the oldest answer if both users answered)
                        response.sort(function (a, b) {
                            var timestampA = a.user_timestamp < a.partner_timestamp ? a.user_timestamp : a.partner_timestamp;
                            var timestampB = b.user_timestamp < b.partner_timestamp ? b.user_timestamp : b.partner_timestamp;
                            var dateA = new Date(timestampA).getTime();
                            var dateB = new Date(timestampB).getTime();
                            return dateA - dateB;

                        });
                        // If latest response is less than 24 hours ago, return the latest response
                        var latestResponse = response[0];
                        var latestTimestamp = latestResponse.user_timestamp < latestResponse.partner_timestamp ? latestResponse.user_timestamp : latestResponse.partner_timestamp;
                        var latestDate = new Date(latestTimestamp);
                        var currentTime = new Date();
                        var timeDiff = Math.abs(currentTime - latestDate);
                        var diffHours = Math.floor((timeDiff / (1000 * 60 * 60)) % 24);
                        if (diffHours < 24) {
                            console.log("Latest response is less than 24 hours old.");
                            should_getDailyQuestion = false;
                            root.switchToDifferentView("result", {
                                question: latestResponse.question,
                                userAnswer: latestResponse.user_answer,
                                partnerAnswer: latestResponse.partner_answer,
                                userTimestamp: latestResponse.user_timestamp,
                                partnerTimestamp: latestResponse.partner_timestamp
                            });
                        } else {
                            console.log("No recent daily question available.");
                        }
                        
                    } else {
                        console.log("No daily question available.");
                    }
                } else {
                    console.log("Error fetching daily question: " + response);
                    root.switchToDifferentView("error", {
                        errorMessage: "Error fetching daily question: " + response
                    });
                }
            }
        );
        if (!should_getDailyQuestion) {
            return;
        }
        request = CallAPI.makeApiRequest(
            "/get-daily-questions-unanswered",
            "token=" + root.jwtToken,
            function (reqSuccess, response) {
                if (reqSuccess) {
                    if (response && response.question) {
                        // Sort by question_id
                        response.sort(function (a, b) {
                            return a.question_id - b.question_id;
                        });
                        // Take the first question
                        var question = response[0].question;
                        var questionId = response[0].question_id;
                        root.dailyQuestion = question;
                        root.dailyQuestionId = questionId;
                    } else {
                        console.log("No daily question available.");
                        root.dailyQuestion = "No daily question available.";
                    }
                } else {
                    console.log("Error fetching daily question: " + response);
                    root.switchToDifferentView("error", {
                        errorMessage: "Error fetching daily question: " + response
                    });
                }
            }
        );
    }
    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: 20
        // Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            color: "transparent"

            Text {
                anchors.centerIn: parent
                text: "Daily Connection Question"
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
                        root.currentResponse = text;
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
                        root.submitResponse(root.currentResponse, root.dailyQuestion);
                        responseTextArea.text = "";
                        CallAPI.getDailyQuestion(function (newQuestion) {
                            dailyQuestion = newQuestion;
                        }, root.apiKey_);
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
