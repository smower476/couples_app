import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts 1.15

// Import local components and views
import "components"
import "views"
import "views/CallAPI.js" as CallAPI // Import the JS file

ApplicationWindow {
    id: window
    width: 390 // iPhone 12 width
    height: 844 // iPhone 12 height
    visible: true
    title: "Couples App"
    color: "#121212" // dark gray-900
    // Property to track the current view
    property string currentView: "hub" // Default view
    property bool isLoggedIn: false // Track login status
    property string jwtToken: "" // Store JWT token
    property string currentUsername: "" // Store username after login/register

    // Signal emitted after successful login and token is set
    signal loginSuccessful()

    // --- New properties for quiz completion state ---
    property bool quizCompletedState: false
    property var lastCompletedQuizData: null
    // --- End new properties ---

    property var dateIdeas: ["🍽️ Romantic Dinner", "🎬 Movie Night", "🚶 Scenic Walk", "🎳 Bowling", "🍦 Ice Cream Date", "🎨 Art Gallery Visit", "🏞️ Picnic in the Park", "🍷 Wine Tasting", "🎮 Game Night", "🧘 Couples Yoga"]

    // App state
    property string dailyQuestion: "What moment today made you smile?"
    property int dateIdeasIndex: 0
    property bool partnerLinked: false
    property var quizResponses: [] // Holds responses like [{id: "quiz1", title: "Quiz 1", questions: [{ "Q1": "A1"}, {"Q2": "A2"}]}]
    property var dailyResponses: []
    property var dateIdeasHistory: []
    property var currentQuiz: null // Holds the currently active quiz object fetched from QuizzesView
    property int currentQuestionIndex: 0 // Index of the question being displayed within currentQuiz

    // Stack view for different screens
    StackLayout {
        id: stackLayout
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: bottomNavigation.top
        }
        currentIndex: {
            switch (currentView) {
            case "hub":
                return 0
            case "quizzes":
                return 1
            case "daily-question":
                return 2
            case "date-ideas":
                return 3
            case "linker":
                return 4
            case "login": // Add login view index
                return 5
            case "profile": // Add profile view index
                return 6
            case "register": // Add register view index
                return 7
            default:
                return 0 // Default to hub
            }
        }

        // Hub view
        HubView {
            id: hubView
            quizResponses: window.quizResponses
            dailyResponses: window.dailyResponses
            dateIdeasHistory: window.dateIdeasHistory
        }

        // Quizzes view
        QuizzesView {
            id: quizzesView
            // Pass state properties from main.qml (window) to QuizzesView's properties
            quizData: window.currentQuiz // Pass window.currentQuiz to QuizzesView.quizData
            questionIndex: window.currentQuestionIndex // Pass window.currentQuestionIndex to QuizzesView.questionIndex
            responses: window.quizResponses // Pass window.quizResponses to QuizzesView.responses
            jwtToken: window.jwtToken // Pass the JWT token
            // --- Pass new completion state properties ---
            quizCompleted: window.quizCompletedState
            completedQuizData: window.lastCompletedQuizData
            // --- End new properties ---

            // Handle the signal emitted by QuizzesView when data is fetched
            onQuizFetched: function(fetchedQuizData) {
                console.log("main.qml: Quiz fetched signal received.");
                if (fetchedQuizData) {
                    window.currentQuiz = fetchedQuizData;
                    window.currentQuestionIndex = 0; // Reset index for new quiz
                    window.quizCompletedState = false; // Ensure completion state is reset for new quiz
                    window.lastCompletedQuizData = null;
                    // Ensure responses array has an entry for this quiz, create if not
                    var existingResponseIndex = window.quizResponses.findIndex(r => r.id === fetchedQuizData.id);
                    if (existingResponseIndex === -1) {
                        var newResponses = window.quizResponses.slice(); // Create a copy
                        newResponses.push({
                            id: fetchedQuizData.id,
                            title: fetchedQuizData.title,
                            questions: [] // Initialize empty questions array
                        });
                        window.quizResponses = newResponses; // Update the main state
                        console.log("main.qml: Added new response entry for quiz:", fetchedQuizData.id);
                    }
                } else {
                    console.error("main.qml: Quiz fetch failed.");
                    window.currentQuiz = null; // Clear quiz if fetch failed
                    window.quizCompletedState = false; // Reset completion state
                    window.lastCompletedQuizData = null;
                }
            }

            // Handle the signal emitted by QuizzesView when an answer is selected
            onQuizResponse: function (questionText, selectedAnswer) {
                console.log("main.qml: Quiz response received:", questionText, selectedAnswer);
                // Ensure there's a current quiz loaded
                if (!window.currentQuiz) {
                    console.error("main.qml: Received quiz response but no current quiz is set.");
                    return;
                }

                // --- Update quizResponses state in main.qml ---
                var responsesCopy = JSON.parse(JSON.stringify(window.quizResponses)); // Deep copy
                var quizId = window.currentQuiz.id;
                var questionIdx = window.currentQuestionIndex;

                // Find the response object for the current quiz
                var quizResponseObj = responsesCopy.find(r => r.id === quizId);

                // This should exist because onQuizFetched creates it, but check just in case
                if (!quizResponseObj) {
                     console.error("main.qml: Response object not found for quiz ID:", quizId);
                     // Optionally create it here if needed, though it indicates a logic error elsewhere
                     quizResponseObj = { id: quizId, title: window.currentQuiz.title, questions: [] };
                     responsesCopy.push(quizResponseObj);
                }

                // Ensure the questions array is long enough (fill with nulls if needed)
                while (quizResponseObj.questions.length <= questionIdx) {
                    quizResponseObj.questions.push(null);
                }

                // Store the response for the current question index
                // Format: { "Question Text": "Selected Answer" }
                quizResponseObj.questions[questionIdx] = { [questionText]: selectedAnswer };

                // Update the main state property - this triggers UI updates in QuizzesView
                window.quizResponses = responsesCopy;
                console.log("main.qml: Updated quizResponses:", JSON.stringify(window.quizResponses));


                // --- Move to next question or finish quiz ---
                if (questionIdx < window.currentQuiz.questions.length - 1) {
                    window.currentQuestionIndex++; // Go to next question
                    console.log("main.qml: Moving to next question index:", window.currentQuestionIndex);
                } else {
                    console.log("main.qml: Quiz finished!");
                    // Quiz finished, prepare data and set completion state
                    var finishedQuizId = window.currentQuiz.id;
                    var finalResponses = window.quizResponses.find(r => r.id === finishedQuizId);

                    // --- Update completion state instead of navigating ---
                    window.lastCompletedQuizData = finalResponses ? finalResponses : { id: finishedQuizId, title: "Quiz Results", questions: [] };
                    window.quizCompletedState = true; // Set completion state
                    // --- End update completion state ---

                    window.currentQuiz = null; // Clear the active quiz
                    window.currentQuestionIndex = 0; // Reset index
                    console.log("main.qml: Quiz completed. State set with data:", JSON.stringify(window.lastCompletedQuizData));
                }
            }

            // --- Handle signal from QuizzesView popup ---
            onCompletionAcknowledged: () => {
                console.log("main.qml: Quiz completion acknowledged.");
                window.quizCompletedState = false; // Reset completion state
                window.lastCompletedQuizData = null;
                // Optionally navigate away, e.g., back to hub
                window.currentView = "hub";
            }
            // --- End handle signal ---
        }

        // Daily question view
        DailyQuestionView {
            id: dailyQuestionView
            dailyQuestion: window.dailyQuestion

            onSubmitResponse: function (response, question) {
                var updatedResponses = window.dailyResponses.slice()
                updatedResponses.push({
                                          "question": question,
                                          "response": response,
                                          "date": new Date().toLocaleDateString(
                                                      )
                                      })
                window.dailyResponses = updatedResponses
            }
        }

        // Date ideas view
        DateIdeasView {
            id: dateIdeasView
            dateIdeas: window.dateIdeas
            currentIndex: window.dateIdeasIndex

            onDateIdeaResponse: function (response) {
                var updatedHistory = window.dateIdeasHistory.slice()
                updatedHistory.push({
                                        "idea": window.dateIdeas[window.dateIdeasIndex],
                                        "response": response,
                                        "date": new Date().toLocaleDateString()
                                    })
                window.dateIdeasHistory = updatedHistory

                if (response === "no") {
                    window.dateIdeasIndex = (window.dateIdeasIndex + 1) % window.dateIdeas.length
                }
            }
        }

        // Linker view
        LinkerView {
            id: linkerView
            partnerLinked: window.partnerLinked
            jwtToken: window.jwtToken // Pass the token from main window

            onLinkPartner: {
                window.partnerLinked = true
            }
        }

        // --- Add Login/Register and Profile Views ---
        LoginRegisterView {
            id: loginRegisterView

            // Connect to signals from LoginRegisterView
            onLoginAttemptFinished: (success, tokenOrError, username) => { // Add username parameter
                if (success) {
                    console.log("Login finished successfully in main.qml");
                    window.jwtToken = tokenOrError; // Store the JWT
                    window.currentUsername = username; // Use username from signal
                    window.isLoggedIn = true;
                    window.loginSuccessful(); // Emit signal *after* token and status are set
                    window.currentView = "hub"; // Go back to hub after login
                } else {
                    console.error("Login finished with error in main.qml:", tokenOrError);
                    // Error is shown in LoginRegisterView
                }
            }

            onNavigateToRegisterRequested: () => {
                console.log("Navigate to Register requested");
                window.currentView = "register"; // Change view to register page
            }
        }

        ProfileView {
            id: profileView
            // Pass username to profile view
            displayInfo: "Username: " + (window.currentUsername ? window.currentUsername : "[Not Logged In]")

            // Connect to signal from ProfileView
            onLogoutRequested: () => {
                console.log("Logout requested");
                window.jwtToken = ""; // Clear the token
                window.currentUsername = ""; // Clear username
                window.isLoggedIn = false;
                window.currentView = "hub"; // Go back to hub after logout
            }
        }

        // --- Add Register View ---
        RegisterView {
            id: registerView

            onRegistrationComplete: (success, result) => {
                if (success) {
                    console.log("Registration finished successfully in main.qml");
                    // Result is expected to be JSON string: {token: "...", username: "..."}
                    try {
                        var data = JSON.parse(result);
                        window.jwtToken = data.token;
                        window.currentUsername = data.username;
                        window.isLoggedIn = true;
                        window.currentView = "hub"; // Go to hub after successful registration
                    } catch (e) {
                        console.error("Error parsing registration result:", e, result);
                        // Fallback or show error? For now, go to login
                        window.currentView = "login";
                    }
                } else {
                    console.error("Registration finished with error in main.qml:", result);
                    // Error is shown in RegisterView, stay on register page
                }
            }

            onBackToLoginRequested: () => {
                console.log("Back to Login requested");
                window.currentView = "login"; // Go back to login page
            }
        }
        // --- End Register View ---
    }

    // Bottom navigation
    BottomNavigation {
        id: bottomNavigation
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        activeTab: currentView

        onTabSelected: function (tabName) {
            // Only allow navigation via bottom bar if logged in or to hub
            if (window.isLoggedIn || tabName === "hub") {
                 window.currentView = tabName
            } else {
                // If not logged in and trying to access other tabs, redirect to login
                window.currentView = "login"
            }
        }
    }

    // Function to handle profile button click from HubView
    function handleProfileClick() {
        if (window.isLoggedIn) {
            window.currentView = "profile"
        } else {
            window.currentView = "login"
        }
    }
}
