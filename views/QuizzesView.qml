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

    signal completionAcknowledged()

    property bool quizCompleted: false
    property var completedQuizData: null
    property string currentQuizState: "loading"



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
                const numQuestions = transformedQuiz.questions.length;
                root.currentQuizAnswers = new Array(numQuestions).fill(0);
                root.partnerGuesses = new Array(numQuestions).fill(0);
                root.quizPhase = "answeringSelf";
                root.questionIndex = 0;
                root.currentQuizState = "current";
                console.log("Question 1:", root.quizData.questions[0].options)
            } else {
                console.log("QuizzesView: No valid quiz content received for quizId:", quizId, "Setting state to no_available.");
                root.quizData = null;
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
            console.log("QuizzesView: jwtToken changed to:", root.jwtToken ? "present" : "absent");
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
}

