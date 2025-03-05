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
    
    // Data models
    property var initialQuizzes: [
        {
            id: 1,
            title: "How Well Do You Know Your Partner?",
            questions: [
                {
                    question: "What's their dream vacation?",
                    options: [
                        "Tropical Beach",
                        "Mountain Adventure",
                        "City Exploration",
                        "Relaxing Cruise"
                    ]
                },
                {
                    question: "What's their biggest fear?",
                    options: [
                        "Heights",
                        "Public Speaking",
                        "Failure",
                        "Loneliness"
                    ]
                },
                {
                    question: "What's their favorite memory with you?",
                    options: [
                        "First Date",
                        "Spontaneous Road Trip",
                        "Cozy Night In",
                        "Milestone Celebration"
                    ]
                }
            ]
        },
        {
            id: 2,
            title: "Love Language Quiz",
            questions: [
                {
                    question: "How do you prefer to receive affection?",
                    options: [
                        "Words of Affirmation",
                        "Physical Touch",
                        "Acts of Service",
                        "Quality Time"
                    ]
                },
                {
                    question: "What makes you feel most loved?",
                    options: [
                        "Surprises",
                        "Deep Conversations",
                        "Helping with Chores",
                        "Gifts"
                    ]
                },
                {
                    question: "Your partner's love language?",
                    options: [
                        "Receiving Gifts",
                        "Physical Affection",
                        "Words of Support",
                        "Shared Experiences"
                    ]
                }
            ]
        }
    ]
    
    property var dateIdeas: [
        "🍽️ Romantic Dinner",
        "🎬 Movie Night",
        "🚶 Scenic Walk",
        "🎳 Bowling",
        "🍦 Ice Cream Date",
        "🎨 Art Gallery Visit",
        "🏞️ Picnic in the Park",
        "🍷 Wine Tasting",
        "🎮 Game Night",
        "🧘 Couples Yoga"
    ]
    
    // App state
    property string dailyQuestion: "What moment today made you smile?"
    property int dateIdeasIndex: 0
    property bool partnerLinked: false
    property var quizResponses: ({})
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
            case "hub": return 0;
            case "quizzes": return 1;
            case "daily-question": return 2;
            case "date-ideas": return 3;
            case "linker": return 4;
            default: return 0;
            }
        }
        
        // Hub view
        HubView {
            id: hubView
            quizResponses: window.quizResponses
            dailyResponses: window.dailyResponses
            dateIdeasHistory: window.dateIdeasHistory
            initialQuizzes: window.initialQuizzes
        }
        
        // Quizzes view
        QuizzesView {
            id: quizzesView
            initialQuizzes: window.initialQuizzes
            currentQuiz: window.currentQuiz
            currentQuizIndex: window.currentQuizIndex
            currentQuestionIndex: window.currentQuestionIndex
            quizResponses: window.quizResponses
            
            onStartQuiz: function(quiz) {
                window.currentQuiz = quiz
                window.currentQuizIndex = window.initialQuizzes.findIndex(q => q.id === quiz.id)
                window.currentQuestionIndex = 0
            }
            
            onQuizResponse: function(response) {
                // Update quiz responses
                var updatedResponses = JSON.parse(JSON.stringify(window.quizResponses))
                if (!updatedResponses[window.currentQuiz.id]) {
                    updatedResponses[window.currentQuiz.id] = {}
                }
                updatedResponses[window.currentQuiz.id][window.currentQuestionIndex] = response
                window.quizResponses = updatedResponses
                
                // Move to next question or quiz
                if (window.currentQuestionIndex < window.currentQuiz.questions.length - 1) {
                    window.currentQuestionIndex++
                } else if (window.currentQuizIndex < window.initialQuizzes.length - 1) {
                    window.currentQuizIndex++
                    window.currentQuestionIndex = 0
                    window.currentQuiz = window.initialQuizzes[window.currentQuizIndex]
                } else {
                    window.currentQuiz = null
                    window.currentQuizIndex = 0
                    window.currentQuestionIndex = 0
                }
            }
        }
        
        // Daily question view
        DailyQuestionView {
            id: dailyQuestionView
            dailyQuestion: window.dailyQuestion
            
            onSubmitResponse: function(response) {
                var updatedResponses = window.dailyResponses.slice()
                updatedResponses.push({
                    question: window.dailyQuestion,
                    response: response,
                    date: new Date().toLocaleDateString()
                })
                window.dailyResponses = updatedResponses
            }
        }
        
        // Date ideas view
        DateIdeasView {
            id: dateIdeasView
            dateIdeas: window.dateIdeas
            currentIndex: window.dateIdeasIndex
            
            onDateIdeaResponse: function(response) {
                var updatedHistory = window.dateIdeasHistory.slice()
                updatedHistory.push({
                    idea: window.dateIdeas[window.dateIdeasIndex],
                    response: response,
                    date: new Date().toLocaleDateString()
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
        
        onTabSelected: function(tabName) {
            window.currentView = tabName
        }
    }
}
