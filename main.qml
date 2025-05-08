import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts 1.15
import Qt.labs.settings 1.0
import "views/CallAPI.js" as CallAPI

import "components"
import "views"

ApplicationWindow {
    id: window
    width: 390 
    height: 844
    visible: true
    title: "Couples App"
    color: "#121212"
    Settings {
        id: appSettings
        property string savedJwtToken: ""
        property string savedUsername: ""
    }
    property string currentView: "hub"
    property bool isLoggedIn: jwtToken !== ""
    property string jwtToken: appSettings.savedJwtToken
    property string currentUsername: appSettings.savedUsername

    signal loginSuccessful()

    property bool quizCompletedState: false
    property var lastCompletedQuizData: null
    // TODO - add dateIdeas actual implementation
    property var dateIdeas: ["🍽️ Romantic Dinner", "🎬 Movie Night", "🚶 Scenic Walk", "🎳 Bowling", "🍦 Ice Cream Date", "🎨 Art Gallery Visit", "🏞️ Picnic in the Park", "🍷 Wine Tasting", "🎮 Game Night", "🧘 Couples Yoga"]

    property string dailyQuestion: "What moment today made you smile?"
    property int dateIdeasIndex: 0
    property bool partnerLinked: false
    property var quizResponses: []
    property var dailyResponses: []
    property var dateIdeasHistory: []
    property var currentQuiz: null
    property int currentQuestionIndex: 0

    StackLayout {
        id: stackLayout
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: bottomNavigation.top
        }
        currentIndex: {
            switch (window.currentView) {
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
            case "login":
                return 5
            case "profile":
                return 6
            case "register":
                return 7
            case "quizHistoryDetail":
                return 8
            default:
                return 0
            }
        }

        HubView {
            id: hubView
            quizResponses: window.quizResponses
            dailyResponses: window.dailyResponses
            dateIdeasHistory: window.dateIdeasHistory
            jwtToken: window.jwtToken
        }

        QuizzesView {
            id: quizzesView
            quizData: window.currentQuiz
            questionIndex: window.currentQuestionIndex
            jwtToken: window.jwtToken
            quizCompleted: window.quizCompletedState
            completedQuizData: window.lastCompletedQuizData
            onCompletionAcknowledged: {
                window.currentView = "hub" // Or any other desired view
            }
        }

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

        LinkerView {
            id: linkerView
            partnerLinked: window.partnerLinked
            jwtToken: window.jwtToken

            onLinkPartner: {
                window.partnerLinked = true
            }
        }

        LoginRegisterView {
            id: loginRegisterView

            onLoginAttemptFinished: (success, tokenOrError, username) => {
                if (success) {
                    // window.jwtToken = tokenOrError;
                    // window.currentUsername = username;
                    // window.isLoggedIn = true;
                    appSettings.savedJwtToken = tokenOrError;
                    appSettings.savedUsername = username;
                    window.loginSuccessful();
                    window.currentView = "hub";
                } else {
                }
            }

            onNavigateToRegisterRequested: () => {
                window.currentView = "register";
            }
        }

        ProfileView {
            id: profileView
            token: window.jwtToken

            onLogoutRequested: () => {
                appSettings.savedJwtToken = "";
                appSettings.savedUsername = "";
                // window.isLoggedIn = false;
                window.currentView = "hub";
                window.quizCompletedState = false;
                window.lastCompletedQuizData = null;
                window.dateIdeasIndex = 0;
                window.partnerLinked = false;
                window.quizResponses = [];
                window.dailyResponses = [];
                window.dateIdeasHistory = [];
                window.currentQuiz = null;
                window.currentQuestionIndex = 0;
            }
        }

        RegisterView {
            id: registerView

            onRegistrationComplete: (success, result) => {
                if (success) {
                    try {
                        var data = JSON.parse(result);
                        appSettings.savedJwtToken = data.token;
                        appSettings.savedUsername = data.username;
                        // window.isLoggedIn = true;
                        window.currentView = "hub";
                    } catch (e) {
                        window.currentView = "login";
                    }
                } else {
                }
            }

            onBackToLoginRequested: () => {
                window.currentView = "login";
            }
        }
        QuizHistoryDetailView {
            id: quizHistoryDetailView
            jwtToken: window.jwtToken
        }
    }

    BottomNavigation {
        id: bottomNavigation
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        activeTab: window.currentView

        onTabSelected: function (tabName) {
            if (window.isLoggedIn || tabName === "hub") {
                 window.currentView = tabName
            } else {
                window.currentView = "login"
            }
        }
    }

    function handleProfileClick() {
        if (window.isLoggedIn) {
            window.currentView = "profile"
        } else {
            window.currentView = "login"
        }
    }

    function showQuizHistoryDetail(quizData) {
        quizHistoryDetailView.rawAnsweredQuizData = quizData;
        window.currentView = "quizHistoryDetail";
    }

    Component.onCompleted: {
    if (appSettings.savedJwtToken !== "") {
        CallAPI.getUserInfo(appSettings.savedJwtToken, function(success, userInfo) {
            if (!success) {
                appSettings.savedJwtToken = "";
                appSettings.savedUsername = "";
                window.currentView = "hub";
            } else {
                if (userInfo && userInfo.username) {
                    appSettings.savedUsername = userInfo.username;
                }
            }
        });
    }
}
}
