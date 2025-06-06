pragma ComponentBehavior: Bound
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Basic 6.2
import "CallAPI.js" as CallAPI
import "./quizViews/"

Item {
    id: root
    width: parent.width
    height: parent.height
    property var quizData: null
    property int questionIndex: 0
    property var currentQuizAnswers: []
    property var partnerGuesses: []

    property string quizPhase: "answeringSelf"
    property string jwtToken: ""
    property string currentQuizId: "" // Added property to track current quiz ID

    signal completionAcknowledged()

    property bool quizCompleted: false
    property var completedQuizData: null
    property string currentQuizState: "loading"
    property bool isVisible: false // Track visibility of the view

    Timer {
        id: updateTimer
        interval: 10*1000*60 // Check every 5 seconds when view is visible
        repeat: true
        running: root.isVisible && root.jwtToken && root.jwtToken !== ""
        onTriggered: {
            root.checkForQuizUpdates();
        }
    }

    // Added function for silently checking quiz updates
    function checkForQuizUpdates() {
        if (!root.jwtToken || root.jwtToken === "") {
            return;
        }
        CallAPI.getDailyQuizId(root.jwtToken, function(success, quizIdOrError) {
            if (success) {
                if (quizIdOrError === "done") {
                    // Quiz is already completed, nothing to update
                    return;
                }
                // Only if quiz ID is different from current one, fetch new content
                if (quizIdOrError !== root.currentQuizId) {
                    
                    CallAPI.getQuizContent(root.jwtToken, quizIdOrError, function(contentSuccess, quizContent) {
                        if (contentSuccess && quizContent && quizContent.quiz_content && quizContent.quiz_content.length > 0) {
                            var transformedQuiz = {
                                id: quizIdOrError,
                                title: quizContent.quiz_name || "Daily Quiz",
                                questions: quizContent.quiz_content.map((item, index) => {
                                    return {
                                        question: item.content_data,
                                        options: item.answers.map(ans => ans.answer_content),
                                        _answers: item.answers,
                                        _content_id: item.content_id
                                    };
                                })
                            };
                            
                            // Update quiz and reset state since it's a different quiz
                            root.quizData = transformedQuiz;
                            root.currentQuizId = quizIdOrError;
                            const numQuestions = transformedQuiz.questions.length;
                            root.currentQuizAnswers = new Array(numQuestions).fill(0);
                            root.partnerGuesses = new Array(numQuestions).fill(0);
                            root.quizPhase = "answeringSelf";
                            root.questionIndex = 0;
                            
                            if (root.currentQuizState === "loading" || root.currentQuizState === "no_available") {
                                root.currentQuizState = "current";
                            }
                            
                        } else {
                            console.error("QuizzesView: Failed to get content for new quiz. ID:", quizIdOrError);
                        }
                    });
                } else {
                    root.quizCompleted = false;
                    root.completedQuizData = null;
                    root.currentQuizState = "current";
                    root.currentQuizAnswers = new Array(root.quizData.questions.length).fill(0);
                    root.partnerGuesses = new Array(root.quizData.questions.length).fill(0);
                    root.quizPhase = "answeringSelf";
                    root.questionIndex = 0;
                }
            } else {
                console.error("QuizzesView: Failed to check for quiz updates. Error:", quizIdOrError);
            }
        });
    }

    function fetchDailyQuiz() {
        root.currentQuizState = "loading";
        getNewQuiz(function (quizContent, quizId) {
            if (quizContent && quizContent.quiz_content && quizContent.quiz_content.length > 0) {
                var transformedQuiz = {
                    id: quizId || "daily_quiz_" + new Date().getTime(),
                    title: quizContent.quiz_name || "Daily Quiz",
                    questions: quizContent.quiz_content.map((item, index) => {
                        return {
                            question: item.content_data,
                            options: item.answers.map(ans => ans.answer_content),
                            _answers: item.answers,
                            _content_id: item.content_id
                        };
                    })
                };
                root.quizData = transformedQuiz;
                root.currentQuizId = quizId; // Store the quiz ID
                const numQuestions = transformedQuiz.questions.length;
                root.currentQuizAnswers = new Array(numQuestions).fill(0);
                root.partnerGuesses = new Array(numQuestions).fill(0);
                root.quizPhase = "answeringSelf";
                root.questionIndex = 0;
                root.currentQuizState = "current";
            } else {
                root.quizData = null;
                root.currentQuizId = ""; // Clear the quiz ID
                root.currentQuizState = "no_available";
            }
        });
    }

    function getNewQuiz(callback) {
        CallAPI.getDailyQuizId(root.jwtToken, function(success, quizIdOrError) {
            if (success) {
                if (quizIdOrError === "done") {
                    root.quizCompleted = true;
                    fetchCompletedQuizResults();
                    return;
                }

                CallAPI.getQuizContent(root.jwtToken, quizIdOrError, function(contentSuccess, quizContent) {
                    if (contentSuccess) {
                        callback(quizContent, quizIdOrError);
                    } else {
                        console.error("QuizzesView: Failed to get quiz content for quizId:", quizIdOrError);
                        callback(null, quizIdOrError);
                    }
                });
            } else {
                console.error("QuizzesView: Failed to get daily quiz ID. Reason/Error:", quizIdOrError);

                root.currentQuizState = "no_available";
            }
        });
    }

    function fetchCompletedQuizResults() {
        if (!root.jwtToken) {
            root.completedQuizData = null;
            root.currentQuizState = "no_available";
            return;
        }
        CallAPI.getAnsweredQuizzes(root.jwtToken, function(answeredSuccess, answeredQuizzes) {
            if (answeredSuccess && answeredQuizzes && answeredQuizzes.length > 0) {
                const lastAnsweredQuiz = answeredQuizzes[0]; 
                const completedQuizId = lastAnsweredQuiz.id || lastAnsweredQuiz.quiz_id;

                if (!completedQuizId) {
                    console.error("QuizzesView: lastAnsweredQuiz has no ID. Data:", JSON.stringify(lastAnsweredQuiz));
                    root.completedQuizData = null;
                    root.currentQuizState = "no_available";
                    return;
                }

                CallAPI.getQuizContent(root.jwtToken, completedQuizId, function(contentSuccess, quizContent) {
                    if (contentSuccess && quizContent && quizContent.quiz_content) {

                        root.completedQuizData = {
                            answeredQuizDetails: lastAnsweredQuiz,
                            quizContent: quizContent 
                        };
                        root.currentQuizState = "completed";
                    } else {
                        console.error("QuizzesView: Failed to get content for completed quiz. ID:", completedQuizId);
                        root.completedQuizData = null;
                        root.currentQuizState = "no_available";
                    }
                });
            } else {
                console.error("QuizzesView: Failed to fetch answered quizzes or list is empty. Error/Result:", answeredQuizzes);
                root.completedQuizData = null;
                root.currentQuizState = "no_available";
            }
        });
    }


    StackLayout {
        id: stackLayout
        anchors.fill: parent

        currentIndex: {
            switch (root.currentQuizState) {
                case "loading":
                    return 0;
                case "current":
                    return 1;
                case "completed":
                    return 2;
                case "no_available":
                    return 3;
                default:
                    return 0;
            }
        }

        QuizzesViewLoading {
            id: quizLoadingView
        }

        QuizzesViewCurrent {
            id: quizCurrentView
            quizData: root.quizData
            questionIndex: root.questionIndex
            currentQuizAnswers: root.currentQuizAnswers
            partnerGuesses: root.partnerGuesses
            quizPhase: root.quizPhase
            onAnswerSelected: (qIndex, aIndex, isLast) => {
                root.currentQuizAnswers[qIndex] = aIndex;
                if (isLast) {
                    root.quizPhase = "guessingPartner";
                    root.questionIndex = 0;
                } else {
                    root.questionIndex++;
                }
            }
            onGuessSelected: (qIndex, gIndex, isLast) => {
                root.partnerGuesses[qIndex] = gIndex;
                if (isLast) {
                    CallAPI.answerQuiz(root.jwtToken, root.quizData.id, root.currentQuizAnswers, root.partnerGuesses, function(success, response) {
                        if (success) {
                            fetchCompletedQuizResults();
                            root.quizCompleted = true;
                        } else {
                             root.currentQuizState = "no_available";
                        }
                    });
                } else {
                    root.questionIndex++;
                }
            }
        }

        QuizzesViewCompleted {
            id: quizCompletedViewComponent
            completedQuizData: root.completedQuizData
            onAcknowledged: {
                root.completionAcknowledged()
                root.currentQuizState = "no_available";
            }
        }

        QuizzesViewNoAvailable {
            id: quizNoAvailableView
            onBackToHub: {
                root.completionAcknowledged();
            }
        }
    }

    Connections {
        target: root

        function onJwtTokenChanged() {
            if (root.jwtToken && root.jwtToken !== "") {
                root.fetchDailyQuiz();
            } else {
                root.quizData = null;
                root.completedQuizData = null;
                root.currentQuizState = "no_available";
            }
        }
    }
    
    Component.onCompleted: {
        if (root.jwtToken && root.jwtToken !== "") {
            fetchDailyQuiz();
        } else {
            root.currentQuizState = "no_available";
        }
    }
    
    onVisibleChanged: {
        root.isVisible = visible;
        if (visible && root.jwtToken && root.jwtToken !== "") {
            root.checkForQuizUpdates();
        }
    }
}

