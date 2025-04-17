import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "CallAPI.js" as CallAPI

Item {
    id: root
    width: parent.width
    height: parent.height

    // Properties passed from main.qml
    property var quizData: null // Changed from alias to regular property
    property int questionIndex: 0 // Changed from alias to regular property
    property var responses: [] // Changed from alias to regular property

    // Internal properties
    property string apiKey_: ""
    property string jwtToken: ""

    // Signals
    signal quizFetched(var quizData) // Emitted when quiz data is loaded
    signal quizResponse(string question, string response) // Emitted when an answer is clicked

    // Component initialization logic
    Component.onCompleted: {
        // Fetch the daily quiz when the component is loaded and token is available
        // Assuming jwtToken is populated by main.qml before this view is shown
        if (root.jwtToken) {
            fetchDailyQuiz();
        } else {
            // Handle case where token is not yet available (e.g., wait for a signal)
            console.log("QuizzesView: JWT token not available on completion.");
            // We might need a signal from main.qml when login completes
            // For now, let's assume it's set. If not, this won't fetch.
        }
    }

    // Connections to react to property changes on this component (root)
    Connections {
        target: root

        // Fetch quiz when the jwtToken property changes (e.g., after login)
        function onJwtTokenChanged() {
            console.log("QuizzesView: jwtToken changed. Fetching quiz.");
            // Fetch only if the token is now valid (not empty)
            if (root.jwtToken) {
                fetchDailyQuiz();
            } else {
                // Token cleared (logout), main.qml should handle clearing quizData if needed
                // root.initialQuizzes = []; // Removed
                console.log("QuizzesView: jwtToken cleared.");
            }
        }
    }

    // Function to fetch and process the daily quiz
    function fetchDailyQuiz() {
        console.log("QuizzesView: Fetching daily quiz with token:", root.jwtToken);
        getNewQuiz(function (quizContent) {
            // Check if quizContent and quiz_content array exist and have data
            if (quizContent && quizContent.quiz_content && quizContent.quiz_content.length > 0) {
                // Transform the fetched quiz content into the format expected by the UI
                var transformedQuiz = {
                    // Assuming the API response doesn't provide a single ID/Title for the whole quiz
                    // Using a default title or deriving one if possible. Let's use the first question's ID as quiz ID for uniqueness.
                    id: quizContent.quiz_content[0].content_id || "daily_quiz_" + new Date().getTime(), // Use first question ID or timestamp
                    title: quizContent.quiz_name || "Daily Quiz", // Use quiz_name if available from API, else default
                    questions: quizContent.quiz_content.map((item, index) => {
                        return {
                            question: item.content_data,
                            // Map answers to simple strings for options
                            options: item.answers.map(ans => ans.answer_content),
                            // Store original answer details if needed later for checking (optional)
                            _answers: item.answers,
                            _content_id: item.content_id
                        };
                    })
                };
                console.log("Transformed Quiz:", JSON.stringify(transformedQuiz));
                // Emit signal with fetched data instead of setting internal state
                root.quizFetched(transformedQuiz);
                // root.currentQuiz = transformedQuiz; // Removed
                // root.currentQuestionIndex = 0; // Removed
                // root.quizResponses = {}; // Removed
                // root.initialQuizzes = [transformedQuiz]; // Removed
            } else {
                console.error("Failed to process quiz content or quiz_content is empty:", quizContent);
                // Emit signal with null data to indicate failure
                root.quizFetched(null);
                // root.currentQuiz = null; // Removed
                // root.initialQuizzes = []; // Removed
                // Handle error: show message to user? (Maybe main.qml handles this)
            }
        });
    }

    // Remove the old getNewQuestion function as it's no longer needed
    /*
    function getNewQuestion(callback, apikey) {
        CallAPI.getQuizzQuestionAndAnswer(function (question, answers) {
            callback({
                         "question": question,
                         "options": answers
                     })
        }, root.apiKey_)
    }
    */

    function getNewQuiz(callback) {
        CallAPI.getDailyQuizId(root.jwtToken, function(success, quizId) {
            if (success) {
                console.log("Daily Quiz ID:", quizId);
                CallAPI.getQuizContent(root.jwtToken, quizId, function(success, quizContent) {
                    if (success) {
                        console.log("Quiz content:", quizContent);
                        callback(quizContent); // Pass the quiz content to the callback
                    } else {
                        console.error("Failed to get quiz content:", quizContent);
                        // Handle the error appropriately
                    }
                });
            } else {
                console.error("Failed to get daily quiz ID:", quizId);
                // Handle the error appropriately
            }
        });
    }


    ScrollView {
        id: scrollView
        anchors.fill: parent
        contentWidth: parent.width
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 16

            // Header
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                color: "transparent"

                // Combined Header Text - Shows title when quiz is loaded
                Text {
                    anchors.centerIn: parent
                    text: root.quizData ? root.quizData.title : "🤔 Loading Quiz..." // Use property quizData
                    font.pixelSize: 24
                    font.bold: true
                    color: "white"
                }
            }

            // Quiz list removed - Quiz starts automatically

            // Quiz question (visible when a quiz is loaded)
            Rectangle {
                Layout.fillWidth: true
                Layout.margins: 16
                // Layout.preferredHeight removed, let it fill height
                Layout.fillHeight: true // Make the question container fill available vertical space
                color: "#1f1f1f" // gray-800
                radius: 8
                visible: root.quizData !== null // Use property quizData

                ColumnLayout {
                    id: questionColumn
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 16
                    }

                    Text {
                        // Use properties questionIndex and quizData
                        text: "Question " + (root.questionIndex + 1) + " of "
                              + (root.quizData ? root.quizData.questions.length : 0)
                        font.pixelSize: 16
                        color: "#9ca3af" // gray-400
                    }

                    Item {
                        Layout.fillHeight: true
                    }

                    Text {
                        // Use properties quizData and questionIndex
                        text: root.quizData ? root.quizData.questions[root.questionIndex].question : ""
                        font.pixelSize: 20
                        color: "white"
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }

                    ColumnLayout { // Changed from GridLayout
                        Layout.fillWidth: true
                        Layout.fillHeight: true // Make the answers layout fill vertical space
                        spacing: 24 // Increased spacing to spread items out more
                        Repeater {
                            // Use properties quizData and questionIndex
                            model: root.quizData ? root.quizData.questions[root.questionIndex].options : []

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: Math.min(answerText.implicitHeight + 20, 100)
                                Layout.maximumHeight: 100
                                radius: 4

                                // Updated isSelected logic using properties and main.qml's response structure
                                property bool isSelected: {
                                    // Check if quizData and responses exist
                                    if (!root.quizData || !root.responses) return false;

                                    // Find the response object for the current quiz
                                    var quizResponseObj = root.responses.find(r => r.id === root.quizData.id);
                                    if (!quizResponseObj || !quizResponseObj.questions) return false;

                                    // Get the response for the current question index
                                    var questionResponse = quizResponseObj.questions[root.questionIndex];
                                    if (!questionResponse) return false;

                                    // The response is stored as { questionText: answerText }
                                    // We need the answerText part. Get the first value from the object.
                                    var selectedAnswer = Object.values(questionResponse)[0];

                                    // Compare with the current option (modelData)
                                    return selectedAnswer === modelData;
                                }

                                color: isSelected ? "#ec4899" : "#4b5563" // pink-600 or gray-600

                                // Replaced ScrollView with Text directly to test wrapping
                                Text {
                                    id: answerText // Use the id referenced in Layout.preferredHeight
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        top: parent.top
                                        margins: 10 // Apply padding directly
                                    }
                                    // modelData here is an option string from the transformed 'options' array
                                    text: modelData
                                    font.pixelSize: 14
                                    color: "white"
                                    wrapMode: Text.Wrap // Enable wrapping
                                    width: parent.width - 20 // Constrain width to parent Rectangle minus margins
                                    horizontalAlignment: Text.AlignHCenter // Center the text horizontally
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    // Pass the question text and the selected option text (use properties)
                                    onClicked: {
                                        if (root.quizData) { // Ensure quizData is loaded
                                            root.quizResponse(root.quizData.questions[root.questionIndex].question, modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Bottom padding
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 20
            }
        }
    }
}

