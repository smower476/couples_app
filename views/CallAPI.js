const API_BASE_URL = "http://129.158.234.85:8080"; // Define base URL

function wrapNumberFieldsInQuotes(responseText) {
    // This regex finds a quoted key, followed by optional whitespace, a colon,
    // then captures one or more digits, and asserts that the digits are followed
    // by a comma, closing brace, or closing bracket (to avoid matching numbers in strings).
    const regex = /"(\w+)":\s*(\d+)(?=[,\}\]])/g;
    return responseText.replace(regex, '"$1": "$2"');
}

function getDailyQuizId(token, callback) {
    getAnsweredQuizzes(token, function(success, answeredQuizzes) {
        if (success) {
            if (answeredQuizzes.length > 0) {
                // Get the timestamp of the last completed quiz
                const lastCompletedQuiz = answeredQuizzes[answeredQuizzes.length - 1];
                // Defensive: check for user_answer and answered_at, else fallback to created_at
                let lastCompletedTime = null;
                if (lastCompletedQuiz.user_answer && lastCompletedQuiz.user_answer.answered_at) {
                    lastCompletedTime = new Date(lastCompletedQuiz.user_answer.answered_at).getTime();
                } else if (lastCompletedQuiz.self_answered_at) {
                    lastCompletedTime = new Date(lastCompletedQuiz.self_answered_at).getTime();
                } else if (lastCompletedQuiz.created_at) {
                    lastCompletedTime = new Date(lastCompletedQuiz.created_at).getTime();
                }
                if (lastCompletedTime) {
                    const now = Date.now();
                    const diff = now - lastCompletedTime;
                    const oneDay = 24 * 60 * 60 * 1000;
                    if (diff < oneDay) {
                        console.log("Daily quiz already done for today.");
                        callback(true, "done");
                        return;
                    } else {
                        console.log("Daily quiz not done for today. Diff:", diff, "oneDay:", oneDay);
                    }
                }
            }

            // If not done for today, proceed with getting an unanswered quiz
            var xhr = new XMLHttpRequest();
            var url = API_BASE_URL + "/get-unanswered-quizzes-for-pair";
            var params = "token=" + encodeURIComponent(token);

            xhr.open("POST", url, true);
            xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");

            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 200) {
                        console.log("Unanswered quizzes received:", xhr.responseText);
                        try {
                            // Wrap number fields in quotes before parsing
                            const responseText = wrapNumberFieldsInQuotes(xhr.responseText);
                            console.log("Raw quiz data:", responseText);
                            const quizzes = JSON.parse(responseText);

                            // Sort quizzes by ID
                            quizzes.sort((a, b) => {
                                if (typeof a.id === 'string' && typeof b.id === 'string') {
                                    return a.id.localeCompare(b.id);
                                } else {
                                    return a.id - b.id;
                                }
                            });
                            console.log("Sorted quiz data:", JSON.stringify(quizzes, null, 2));

                            // Sort quizzes by created_at in ascending order (oldest first)
                            quizzes.sort((a, b) => new Date(a.created_at) - new Date(b.created_at));

                            // Select the oldest quiz (the first one after sorting)
                            const quizId = quizzes[0].id;

                            console.log("Selected quiz ID:", quizId);
                            callback(true, quizId); // Success, return quiz ID
                        } catch (e) {
                            console.error("Error processing quizzes:", e);
                            callback(false, "Failed to process quizzes: " + e.message);
                        }
                    } else {
                        console.error("Get unanswered quizzes error:", xhr.status, xhr.responseText);
                        callback(false, "Failed to get unanswered quizzes: " + xhr.responseText); // Failure
                    }
                }
            };

            xhr.send(params);
        } else {
            console.error("Failed to get answered quizzes:", answeredQuizzes);
            callback(false, "Failed to get answered quizzes.");
        }
    });
}

function getAnsweredQuizzes(token, callback) {
    var xhr = new XMLHttpRequest();
    var url = API_BASE_URL + "/get-answered-quizes";
    var params = "token=" + encodeURIComponent(token);

    xhr.open("POST", url, true);
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                console.log("Answered quizzes received:", xhr.responseText);
                try {
                    // Wrap number fields in quotes before parsing
                    const responseText = wrapNumberFieldsInQuotes(xhr.responseText);
                    const answeredQuizzes = JSON.parse(responseText);
                    // Defensive: ensure always array
                    if (Array.isArray(answeredQuizzes)) {
                        callback(true, answeredQuizzes);
                    } else if (answeredQuizzes) {
                        callback(true, [answeredQuizzes]);
                    } else {
                        callback(true, []);
                    }
                } catch (e) {
                    console.error("Error processing answered quizzes:", e);
                    callback(false, "Failed to process answered quizzes: " + e.message);
                }
            } else {
                console.error("Get answered quizzes error:", xhr.status, xhr.responseText);
                callback(false, "Failed to get answered quizzes: " + xhr.responseText);
            }
        }
    };

    xhr.send(params);
}

function getQuizContent(token, quizId, callback) {
    var xhr = new XMLHttpRequest();
    var url = API_BASE_URL + "/get-quiz-content";
    var params = "token=" + encodeURIComponent(token) + "&quiz_id=" + encodeURIComponent(quizId);
    console.log(params);

    xhr.open("POST", url, true);
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                console.log("Quiz content received:", xhr.responseText);
                // Wrap number fields in quotes before parsing
                const responseText = wrapNumberFieldsInQuotes(xhr.responseText);
                const quizContent = JSON.parse(responseText);
                console.log("Quiz content (pretty):", JSON.stringify(quizContent, null, 2));
                callback(true, quizContent); // Success, return quiz content
            } else {
                console.error("Get quiz content error:", xhr.status, xhr.responseText);
                callback(false, "Failed to get quiz content: " + xhr.responseText); // Failure
            }
        }
    };

    xhr.send(params);
}

function getQuizzQuestionAndAnswer(callback, apiKey) {
    var xhr = new XMLHttpRequest();
    var answers = [];
    var completedRequests = 0;

    // Fetch the main riddle question
    xhr.open("GET", "https://api.api-ninjas.com/v1/riddles");
    xhr.setRequestHeader("X-Api-Key", apiKey);

    xhr.onreadystatechange = function () {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                // Wrap number fields in quotes before parsing
                const responseText = wrapNumberFieldsInQuotes(xhr.responseText); // No number fields to wrap in this case
                var response = JSON.parse(responseText);
                var question = response[0].question;
                answers.push(response[0].answer); // Correctly store the answer

                // Fetch 3 random words
                fetchRandomWords(3, apiKey, function (randomWords) {
                    answers = answers.concat(randomWords); // Merge correct answer + random words
                    shuffleArray(answers);
                    callback(question, answers); // Return both after all requests finish
                });
            } else {
                console.log("Error:", xhr.status, xhr.responseText);
                callback("Not able to load", []);
            }
        }
    };

    xhr.send();
}


function registerUser(username, password, callback) {
    var xhr = new XMLHttpRequest();
    var url = API_BASE_URL + "/add-user";
    var params = "username=" + encodeURIComponent(username) + "&password=" + encodeURIComponent(password);

    xhr.open("POST", url, true);
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            // Accept 200 OK or 201 Created as success for registration
            if (xhr.status === 200 || xhr.status === 201) {
                console.log("Registration successful:", xhr.status, xhr.responseText);
                // Wrap number fields in quotes before parsing (assuming response might contain user ID or similar)
                const responseText = wrapNumberFieldsInQuotes(xhr.responseText);
                callback(true, responseText); // Success
            } else {
                console.error("Registration error:", xhr.status, xhr.responseText);
                callback(false, "Registration failed: " + xhr.responseText); // Failure
            }
        }
    };

    xhr.send(params);
}

function loginUser(username, password, callback) {
    var xhr = new XMLHttpRequest();
    var url = API_BASE_URL + "/login";
    var params = "username=" + encodeURIComponent(username) + "&password=" + encodeURIComponent(password);

    xhr.open("POST", url, true);
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                console.log("Login successful. JWT:", xhr.responseText);
                // Assuming the response text is the JWT token directly, no parsing needed here
                callback(true, xhr.responseText); // Success, return JWT
            } else {
                console.error("Login error:", xhr.status, xhr.responseText);
                callback(false, "Login failed: " + xhr.responseText); // Failure
            }
        }
    };
xhr.send(params);
}

function getLinkCode(token, callback) {
    var xhr = new XMLHttpRequest();
    var url = API_BASE_URL + "/get-link-code";
    var params = "token=" + encodeURIComponent(token);

    xhr.open("POST", url, true);
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");

    xhr.onreadystatechange = function() {
            if (xhr.status === 0) {
                if (!xhr.responseText) {
                    console.error("Get link code error: Network error, CORS issue, or server is unreachable.");
                    callback(false, { status: 0, message: "Network error, CORS issue, or server is unreachable. Check server logs and CORS headers." });
                } else {
                    // Sometimes status 0 but responseText is present (rare)
                    callback(false, { status: 0, message: "Unexpected status 0 with response: " + xhr.responseText });
                }
            } else if (xhr.status === 200) {
                console.log("Link code received:", xhr.responseText);
                callback(true, xhr.responseText); // Success, return link code
            } else if (xhr.status === 409) {
                console.error("Get link code error: user has already been linked");
                callback(false, { status: 409, message: "User has already been linked." });
            } else {
                console.error("Get link code error:", xhr.status, xhr.responseText);
                callback(false, "Failed to get link code: " + xhr.responseText);
            }
    };

    xhr.onerror = function(e) {
        // This is called for network errors, CORS, etc.
        console.error("getLinkCode: onerror triggered. Most likely a network or CORS error.", e);
        callback(false, { status: 0, message: "Network error or CORS issue (onerror triggered). Check server and browser console for CORS errors." });
    };

    xhr.send(params);
}

function linkUsers(token, linkCode, callback) {
    var xhr = new XMLHttpRequest();
    var url = API_BASE_URL + "/link-users";
    var params = "token=" + encodeURIComponent(token) + "&link_code=" + encodeURIComponent(linkCode);

    xhr.open("POST", url, true);
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                console.log("Users linked successfully:", xhr.responseText);
                // Wrap number fields in quotes before parsing (assuming response might contain linked user IDs or similar)
                const responseText = wrapNumberFieldsInQuotes(xhr.responseText);
                callback(true, responseText); // Success
            } else {
                console.error("Link users error:", xhr.status, xhr.responseText);
                callback(false, "Failed to link users: " + xhr.responseText); // Failure
            }
        }
    };

    xhr.send(params);
}

function answerQuiz(token, quizId, answers, callback) {
    let binaryString = "";
    for (const answer of answers) {
        // Convert answer (1-4) to 2-bit binary (00-11)
        // 1 -> 00, 2 -> 01, 3 -> 10, 4 -> 11
        switch (answer) {
            case 1:
                binaryString += "00";
                break;
            case 2:
                binaryString += "01";
                break;
            case 3:
                binaryString += "10";
                break;
            case 4:
                binaryString += "11";
                break;
            default:
                console.error("Invalid answer value:", answer);
                callback(false, "Invalid answer value provided.");
                return;
        }
    }

    // Convert binary string to base 10 integer
    const base10Answer = parseInt(binaryString, 2);
    console.log("Binary answer string:", binaryString);
    console.log("Base 10 answer:", base10Answer);

    var xhr = new XMLHttpRequest();
    var url = API_BASE_URL + "/answer-quiz";
    var params = "token=" + encodeURIComponent(token) + "&quiz_id=" + encodeURIComponent(quizId) + "&answer=" + encodeURIComponent(base10Answer);

    xhr.open("POST", url, true);
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                console.log("Quiz answered successfully:", xhr.responseText);
                // Wrap number fields in quotes before parsing (assuming response might contain quiz result ID or similar)
                const responseText = wrapNumberFieldsInQuotes(xhr.responseText);
                callback(true, responseText); // Success
            } else {
                console.error("Answer quiz error:", xhr.status, xhr.responseText);
                callback(false, "Failed to answer quiz: " + xhr.responseText); // Failure
            }
        }
    };

    xhr.send(params);
}

// --- End Login/Register Functions ---
