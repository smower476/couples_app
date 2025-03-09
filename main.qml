import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts 1.15

// Import local components and views
import "components"
import "views"

ApplicationWindow {
    id: window
    width: 390 // iPhone 12 width
    height: 844 // iPhone 12 height
    visible: true
    title: "Couples App"
    color: "#121212" // dark gray-900
    // Property to track the current view
    property string currentView: "hub"

    property var dateIdeas: ["🍽️ Romantic Dinner", "🎬 Movie Night", "🚶 Scenic Walk", "🎳 Bowling", "🍦 Ice Cream Date", "🎨 Art Gallery Visit", "🏞️ Picnic in the Park", "🍷 Wine Tasting", "🎮 Game Night", "🧘 Couples Yoga"]

    // App state
    property string dailyQuestion: "What moment today made you smile?"
    property int dateIdeasIndex: 0
    property bool partnerLinked: false
    property var quizResponses: []
    property var dailyResponses: []
    property var dateIdeasHistory: []
    property var currentQuiz: null
    property int currentQuizIndex: 0
    property int currentQuestionIndex: 0

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
            default:
                return 0
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
            currentQuiz: window.currentQuiz
            currentQuizIndex: window.currentQuizIndex
            currentQuestionIndex: window.currentQuestionIndex
            quizResponses: window.quizResponses

            onStartQuiz: function (quiz) {
                window.currentQuiz = quiz
                window.currentQuestionIndex = 0
            }

            onQuizResponse: function (question, response) {
                // Update quiz responses
                var updatedResponses = JSON.parse(JSON.stringify(window.quizResponses))
                //Making sure this section exists
                if (!updatedResponses.some(q => q.id === window.currentQuiz.id)) {
                    // Create a new quiz entry if it doesn't exist
                    updatedResponses.push({
                        id: window.currentQuiz.id,
                        title: window.currentQuiz.title,
                        questions: []
                    });
                }
                // Find the quiz object based on the currentQuiz.id
                var quizIndex = updatedResponses.findIndex(q => q.id === window.currentQuiz.id);

                if (quizIndex === -1) {
                    updatedResponses.push({
                        id: window.currentQuiz.id,
                        title: window.currentQuiz.title,
                        questions: []
                    });
                    quizIndex = updatedResponses.length - 1;
                }

                // Ensure the questions array exists
                if (!updatedResponses[quizIndex].questions[window.currentQuestionIndex]) {
                    updatedResponses[quizIndex].questions[window.currentQuestionIndex] = {};
                }

                updatedResponses[quizIndex].questions[window.currentQuestionIndex][question] = response
                console.log(response)
                window.quizResponses = updatedResponses;

                // Move to next question or quiz
                if (window.currentQuestionIndex < window.currentQuiz.questions.length - 1) {
                    window.currentQuestionIndex++
                } else {
                    window.currentQuiz = null
                    window.currentQuizIndex = 0
                    window.currentQuestionIndex = 0
                }
                console.log(JSON.stringify(window.quizResponses))
            }
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

            onLinkPartner: {
                window.partnerLinked = true
            }
        }
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
            window.currentView = tabName
        }
    }
}
