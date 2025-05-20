function wrapNumberFieldsInQuotes(responseText) {
    const regex = /"(\w+)":\s*(\d+)(?=[,\}\]])/g;
    return responseText.replace(regex, '"$1": "$2"');
}

function makeApiRequest(endpoint, params, callback, method = "POST") {
    var xhr = new XMLHttpRequest();
    var url = window.aPI_BASE_URL + endpoint;

    xhr.open(method, url, true);
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status >= 200 && xhr.status < 300) {
                let responseText = xhr.responseText;
                if (endpoint !== "/login") {
                    try {
                        JSON.parse(responseText);
                        responseText = wrapNumberFieldsInQuotes(responseText);
                    } catch (e) {
                    }
                }
                callback(true, responseText);
            } else {
                callback(false, { status: xhr.status, message: "API request failed: " + xhr.responseText, responseText: xhr.responseText });
            }
        }
    };

    xhr.onerror = function() {
        callback(false, { status: 0, message: "Network error or CORS issue (onerror triggered)." });
    };

    xhr.send(params);
}


function getDailyQuizId(token, callback) {
    getAnsweredQuizzes(token, function(success, answeredQuizzes) {
        if (success) {
            if (answeredQuizzes.length > 0) {
                const lastCompletedQuiz = answeredQuizzes[0];
                let lastCompletedTime = null;
                const timestamp = lastCompletedQuiz.user_answer?.answered_at || lastCompletedQuiz.self_answered_at || lastCompletedQuiz.created_at;
                if (timestamp) {
                    lastCompletedTime = new Date(timestamp).getTime();
                }
                if (lastCompletedTime) {
                    const now = Date.now();
                    const diff = now - lastCompletedTime;
                    const oneDay = 24 * 60 * 60 * 1000;
                    if (diff < oneDay) {
                        callback(true, "done");
                        return;
                    }
                }
            }

            const endpoint = "/get-unanswered-quizzes-for-pair";
            const params = "token=" + encodeURIComponent(token);

            makeApiRequest(endpoint, params, function(reqSuccess, responseData) {
                if (reqSuccess) {
                    try {
                        const quizzes = JSON.parse(responseData);

                        quizzes.sort((a, b) => {
                            if (typeof a.id === 'string' && typeof b.id === 'string') {
                                return a.id.localeCompare(b.id);
                            } else {
                                return a.id - b.id;
                            }
                        });

                        quizzes.sort((a, b) => new Date(a.created_at) - new Date(b.created_at));

                        if (quizzes.length > 0) {
                            const quizId = quizzes[0].id;
                            callback(true, quizId);
                        } else {
                            callback(false, "No unanswered quizzes available.");
                        }
                    } catch (e) {
                        callback(false, "Failed to process quizzes: " + e.message);
                    }
                } else {
                    callback(false, "Failed to get unanswered quizzes: " + (responseData.message || responseData));
                }
            });
        } else {
            callback(false, "Failed to get answered quizzes.");
        }
    });
}

function getAnsweredQuizzes(token, callback) {
    const endpoint = "/get-answered-quizes";
    const params = "token=" + encodeURIComponent(token);

    makeApiRequest(endpoint, params, function(success, responseData) {
        if (success) {
            try {
                const answeredQuizzes = JSON.parse(responseData);
                if (Array.isArray(answeredQuizzes)) {
                    answeredQuizzes.sort((a, b) => {
                        const timeA = new Date(a.user_answer?.answered_at || a.self_answered_at || a.created_at || 0).getTime();
                        const timeB = new Date(b.user_answer?.answered_at || b.self_answered_at || b.created_at || 0).getTime();
                        return timeB - timeA;
                    });
                    callback(true, answeredQuizzes);
                } else if (answeredQuizzes) {
                    callback(true, [answeredQuizzes]);
                } else {
                    callback(true, []);
                }
            } catch (e) {
                callback(false, "Failed to process answered quizzes: " + e.message);
            }
        } else {
            callback(false, "Failed to get answered quizzes: " + (responseData.message || responseData));
        }
    });
}

function getQuizContent(token, quizId, callback) {
    const endpoint = "/get-quiz-content";
    const params = "token=" + encodeURIComponent(token) + "&quiz_id=" + encodeURIComponent(quizId);

    makeApiRequest(endpoint, params, function(success, responseData) {
        if (success) {
            try {
                const quizContent = JSON.parse(responseData);
                callback(true, quizContent);
            } catch (e) {
                callback(false, "Failed to parse quiz content: " + e.message);
            }
        } else {
            callback(false, "Failed to get quiz content: " + (responseData.message || responseData));
        }
    });
}

function getQuizzQuestionAndAnswer(callback, apiKey) {
    var xhr = new XMLHttpRequest();
    var answers = [];
    var completedRequests = 0;

    xhr.open("GET", "https://api.api-ninjas.com/v1/riddles");
    xhr.setRequestHeader("X-Api-Key", apiKey);

    xhr.onreadystatechange = function () {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                const responseText = wrapNumberFieldsInQuotes(xhr.responseText);
                var response = JSON.parse(responseText);
                var question = response[0].question;
                answers.push(response[0].answer);

                fetchRandomWords(3, apiKey, function (randomWords) {
                    answers = answers.concat(randomWords);
                    shuffleArray(answers);
                    callback(question, answers);
                });
            } else {
                callback("Not able to load", []);
            }
        }
    };

    xhr.send();
}


function registerUser(username, password, callback) {
    const endpoint = "/add-user";
    const params = "username=" + encodeURIComponent(username) + "&password=" + encodeURIComponent(password);

    makeApiRequest(endpoint, params, function(success, responseData) {
        if (success) {
            callback(true, responseData);
        } else {
            callback(false, "Registration failed: " + (responseData.message || responseData));
        }
    });
}

function loginUser(username, password, callback) {
    const endpoint = "/login";
    const params = "username=" + encodeURIComponent(username) + "&password=" + encodeURIComponent(password);

    makeApiRequest(endpoint, params, function(success, responseData) {
        if (success) {
            callback(true, responseData);
        } else {
            callback(false, "Login failed: " + (responseData.message || responseData));
        }
    });
}

function getLinkCode(token, callback) {
    const endpoint = "/get-link-code";
    const params = "token=" + encodeURIComponent(token);

    makeApiRequest(endpoint, params, function(success, responseData) {
        if (success) {
            callback(true, responseData);
        } else {
            if (responseData.status === 409) {
                callback(false, { status: 409, message: "User has already been linked." });
            } else {
                callback(false, (responseData.message || responseData));
            }
        }
    });
}

function linkUsers(token, linkCode, callback) {
    const endpoint = "/link-users";
    const params = "token=" + encodeURIComponent(token) + "&link_code=" + encodeURIComponent(linkCode);

    makeApiRequest(endpoint, params, function(success, responseData) {
        if (success) {
            callback(true, responseData);
        } else {
            callback(false, "Failed to link users: " + (responseData.message || responseData));
        }
    });
}

function answerQuiz(token, quizId, selfAnswers, partnerGuesses, callback) {
    const combinedAnswers = selfAnswers.concat(partnerGuesses);

    let combinedBinaryString = "";
    for (const answer of combinedAnswers) {
        switch (answer) {
            case 1: combinedBinaryString += "00"; break;
            case 2: combinedBinaryString += "01"; break;
            case 3: combinedBinaryString += "10"; break;
            case 4: combinedBinaryString += "11"; break;
            default:
                callback(false, "Invalid answer/guess value provided.");
                return;
        }
    }

    const numQuestions = selfAnswers.length;
    const expectedLength = numQuestions * 2 * 2;
    if (combinedBinaryString.length !== expectedLength) {
        while (combinedBinaryString.length < expectedLength) {
            combinedBinaryString = "0" + combinedBinaryString;
        }
    }

    const base10CombinedAnswer = parseInt(combinedBinaryString, 2);

    const endpoint = "/answer-quiz";
    const params = "token=" + encodeURIComponent(token) +
                 "&quiz_id=" + encodeURIComponent(quizId) +
                 "&answer=" + encodeURIComponent(base10CombinedAnswer);

    makeApiRequest(endpoint, params, function(success, responseData) {
        if (success) {
            callback(true, responseData);
        } else {
            callback(false, "Failed to answer quiz: " + (responseData.message || responseData));
        }
    });
}

function getPartnerInfo(token, callback) {
    const endpoint = "/get-partner-info";
    const params = "token=" + encodeURIComponent(token);

    makeApiRequest(endpoint, params, function(success, responseData) {
        if (success) {
            try {
                const partnerInfo = JSON.parse(responseData);
                callback(true, partnerInfo);
            } catch (e) {
                callback(false, "Failed to parse partner info: " + e.message);
            }
        } else {
            callback(false, { status: responseData.status, message: "Failed to get partner info: " + (responseData.message || responseData) });
        }
    });
}

function getUserInfo(token, callback) {
    const endpoint = "/get-user-info";
    const params = "token=" + encodeURIComponent(token);

    makeApiRequest(endpoint, params, function(success, responseData) {
        if (success) {
            try {
                const userInfo = JSON.parse(responseData);
                callback(true, userInfo);
            } catch (e) {
                callback(false, "Failed to parse user info: " + e.message);
            }
        } else {
            callback(false, { status: responseData.status, message: "Failed to get user info: " + (responseData.message || responseData) });
        }
    });
}

function setUserInfo(token, moodScale, moodStatus, callback) {
    const endpoint = "/set-user-info";
    let params = "token=" + encodeURIComponent(token);
    
    if (moodScale !== undefined && moodScale !== null) {
        params += "&mood_scale=" + encodeURIComponent(moodScale);
    } else {
        params += "&mood_scale=";
    }
    
    if (moodStatus !== undefined && moodStatus !== null) {
        params += "&mood_status=" + encodeURIComponent(moodStatus);
    } else {
        params += "&mood_status=";
    }

    makeApiRequest(endpoint, params, function(success, responseData) {
        if (success) {
            callback(true, responseData);
        } else {
            callback(false, "Failed to update user info: " + (responseData.message || responseData));
        }
    });
}

function unlinkUsersApi(token, callback) {
    var endpoint = "/unlink-users";
    var params = "token=" + encodeURIComponent(token);

    makeApiRequest(endpoint, params, function(success, response) {
        if (success) {
            callback(true, response);
        } else {
            callback(false, "Failed to unlink users: " + (response.message || response));
        }
    });
}
