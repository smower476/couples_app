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
                // Get the most recent completed quiz (first element after sorting descending)
                const lastCompletedQuiz = answeredQuizzes[0];
                // Defensive: check for user_answer and answered_at, else fallback to created_at
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
                        //console.log("Daily quiz already done for today.");
                        callback(true, "done");
                        return;
                    } else {
                        //console.log("Daily quiz not done for today. Diff:", diff, "oneDay:", oneDay);
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
                        //console.log("Unanswered quizzes received:", xhr.responseText);
                        try {
                            // Wrap number fields in quotes before parsing
                            const responseText = wrapNumberFieldsInQuotes(xhr.responseText);
                            //console.log("Raw quiz data:", responseText);
                            const quizzes = JSON.parse(responseText);

                            // Sort quizzes by ID
                            quizzes.sort((a, b) => {
                                if (typeof a.id === 'string' && typeof b.id === 'string') {
                                    return a.id.localeCompare(b.id);
                                } else {
                                    return a.id - b.id;
                                }
                            });
                            //console.log("Sorted quiz data:", JSON.stringify(quizzes, null, 2));

                            // Sort quizzes by created_at in ascending order (oldest first)
                            quizzes.sort((a, b) => new Date(a.created_at) - new Date(b.created_at));

                            // Select the oldest quiz (the first one after sorting)
                            const quizId = quizzes[0].id;

                            //console.log("Selected quiz ID:", quizId);
                            callback(true, quizId); // Success, return quiz ID
                        } catch (e) {
                            //console.error("Error processing quizzes:", e);
                            callback(false, "Failed to process quizzes: " + e.message);
                        }
                    } else {
                        //console.error("Get unanswered quizzes error:", xhr.status, xhr.responseText);
                        callback(false, "Failed to get unanswered quizzes: " + xhr.responseText); // Failure
                    }
                }
            };

            xhr.send(params);
        } else {
            //console.error("Failed to get answered quizzes:", answeredQuizzes);
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
                //console.log("Answered quizzes received:", xhr.responseText);
                try {
                    // Wrap number fields in quotes before parsing
                    const responseText = wrapNumberFieldsInQuotes(xhr.responseText);
                    const answeredQuizzes = JSON.parse(responseText);
                    // Defensive: ensure always array
                    if (Array.isArray(answeredQuizzes)) {
                        // Sort by timestamp (descending - most recent first)
                        answeredQuizzes.sort((a, b) => {
                            const timeA = new Date(a.user_answer?.answered_at || a.self_answered_at || a.created_at || 0).getTime();
                            const timeB = new Date(b.user_answer?.answered_at || b.self_answered_at || b.created_at || 0).getTime();
                            return timeB - timeA; // Descending order
                        });
                        callback(true, answeredQuizzes);
                    } else if (answeredQuizzes) {
                        // If single object, wrap in array (already sorted)
                        callback(true, [answeredQuizzes]);
                    } else {
                        callback(true, []); // Empty array
                    }
                } catch (e) {
                    //console.error("Error processing answered quizzes:", e);
                    callback(false, "Failed to process answered quizzes: " + e.message);
                }
            } else {
                //console.error("Get answered quizzes error:", xhr.status, xhr.responseText);
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
    //console.log(params);

    xhr.open("POST", url, true);
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                //console.log("Quiz content received:", xhr.responseText);
                // Wrap number fields in quotes before parsing
                const responseText = wrapNumberFieldsInQuotes(xhr.responseText);
                const quizContent = JSON.parse(responseText);
                //console.log("Quiz content (pretty):", JSON.stringify(quizContent, null, 2));
                callback(true, quizContent); // Success, return quiz content
            } else {
                //console.error("Get quiz content error:", xhr.status, xhr.responseText);
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
                //console.log("Error:", xhr.status, xhr.responseText);
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
                //console.log("Registration successful:", xhr.status, xhr.responseText);
                // Wrap number fields in quotes before parsing (assuming response might contain user ID or similar)
                const responseText = wrapNumberFieldsInQuotes(xhr.responseText);
                callback(true, responseText); // Success
            } else {
                //console.error("Registration error:", xhr.status, xhr.responseText);
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
                //console.log("Login successful. JWT:", xhr.responseText);
                // Assuming the response text is the JWT token directly, no parsing needed here
                callback(true, xhr.responseText); // Success, return JWT
            } else {
                //console.error("Login error:", xhr.status, xhr.responseText);
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
                    //console.error("Get link code error: Network error, CORS issue, or server is unreachable.");
                    callback(false, { status: 0, message: "Network error, CORS issue, or server is unreachable. Check server logs and CORS headers." });
                } else {
                    // Sometimes status 0 but responseText is present (rare)
                    callback(false, { status: 0, message: "Unexpected status 0 with response: " + xhr.responseText });
                }
            } else if (xhr.status === 200) {
                //console.log("Link code received:", xhr.responseText);
                callback(true, xhr.responseText); // Success, return link code
            } else if (xhr.status === 409) {
                //console.error("Get link code error: user has already been linked");
                callback(false, { status: 409, message: "User has already been linked." });
            } else {
                //console.error("Get link code error:", xhr.status, xhr.responseText);
                callback(false, "Failed to get link code: " + xhr.responseText);
            }
    };

    xhr.onerror = function(e) {
        // This is called for network errors, CORS, etc.
        //console.error("getLinkCode: onerror triggered. Most likely a network or CORS error.", e);
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
                //console.log("Users linked successfully:", xhr.responseText);
                // Wrap number fields in quotes before parsing (assuming response might contain linked user IDs or similar)
                const responseText = wrapNumberFieldsInQuotes(xhr.responseText);
                callback(true, responseText); // Success
            } else {
                //console.error("Link users error:", xhr.status, xhr.responseText);
                callback(false, "Failed to link users: " + xhr.responseText); // Failure
            }
        }
    };

    xhr.send(params);
}

function answerQuiz(token, quizId, selfAnswers, partnerGuesses, callback) {
    // Combine self answers and partner guesses into a single array
    const combinedAnswers = selfAnswers.concat(partnerGuesses);
    //console.log("Combined answers array:", JSON.stringify(combinedAnswers));

    // Encode the combined array
    let combinedBinaryString = "";
    for (const answer of combinedAnswers) {
        // Convert answer (1-4) to 2-bit binary (00-11)
        switch (answer) {
            case 1: combinedBinaryString += "00"; break;
            case 2: combinedBinaryString += "01"; break;
            case 3: combinedBinaryString += "10"; break;
            case 4: combinedBinaryString += "11"; break;
            default:
                //console.error("Invalid answer/guess value in combined array:", answer);
                callback(false, "Invalid answer/guess value provided.");
                return;
        }
    }

    // Ensure the binary string length is correct (2 bits * (num_questions * 2))
    const numQuestions = selfAnswers.length; // Original number of questions
    const expectedLength = numQuestions * 2 * 2; // 2 bits per answer/guess, 2 sets (self + guess)
    if (combinedBinaryString.length !== expectedLength) {
        //console.error(`Combined binary string length mismatch. Expected ${expectedLength}, got ${combinedBinaryString.length}`);
        // Pad with leading zeros if necessary
        while (combinedBinaryString.length < expectedLength) {
            combinedBinaryString = "0" + combinedBinaryString;
        }
        // Alternatively, handle as an error:
        // callback(false, "Internal error: Combined answer encoding length mismatch.");
        // return;
    }

    const base10CombinedAnswer = parseInt(combinedBinaryString, 2);
    //console.log("Combined Binary:", combinedBinaryString, "-> Base 10:", base10CombinedAnswer);

    var xhr = new XMLHttpRequest();
    var url = API_BASE_URL + "/answer-quiz";
    // Send only the combined answer as the 'answer' parameter
    var params = "token=" + encodeURIComponent(token) +
                 "&quiz_id=" + encodeURIComponent(quizId) +
                 "&answer=" + encodeURIComponent(base10CombinedAnswer); // Send combined value

    xhr.open("POST", url, true);
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                //console.log("Quiz answered successfully:", xhr.responseText);
                // Wrap number fields in quotes before parsing (assuming response might contain quiz result ID or similar)
                const responseText = wrapNumberFieldsInQuotes(xhr.responseText);
                callback(true, responseText); // Success
            } else {
                //console.error("Answer quiz error:", xhr.status, xhr.responseText);
                callback(false, "Failed to answer quiz: " + xhr.responseText); // Failure
            }
        }
    };

    xhr.send(params);
}

function getPartnerInfo(token, callback) {
    var xhr = new XMLHttpRequest();
    var url = API_BASE_URL + "/get-partner-info";
    var params = "token=" + encodeURIComponent(token);

    xhr.open("POST", url, true); // Changed to POST method based on working shell script
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
   //console.log("getPartnerInfo params:", params);
   //console.log("getPartnerInfo method: POST"); // Debug log for method
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
               //console.log("Partner info received:", xhr.responseText);
                try {
                    // Assuming partner info is JSON, parse it
                    const partnerInfo = JSON.parse(xhr.responseText);
                    callback(true, partnerInfo); // Success, return partner info
                } catch (e) {
                    //console.error("Error parsing partner info:", e);
                    callback(false, "Failed to parse partner info: " + e.message);
                }
            } else {
                //console.error("Get partner info error:", xhr.status, xhr.responseText);
                // Handle specific error statuses if needed, otherwise return generic failure
                callback(false, { status: xhr.status, message: "Failed to get partner info: " + xhr.responseText }); // Failure
            }
        }
    };

    xhr.onerror = function(e) {
        //console.error("getPartnerInfo: onerror triggered. Network or CORS error.", e);
        callback(false, { status: 0, message: "Network error or CORS issue (onerror triggered)." });
    };

    xhr.send(params);
}

function getUserInfo(token, callback) {
    var xhr = new XMLHttpRequest();
    var url = API_BASE_URL + "/get-user-info";
    var params = "token=" + encodeURIComponent(token);

    xhr.open("POST", url, true);
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");

    xhr.onreadystatechange = function() {
       //console.log("responseText:", xhr.responseText);
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
               //console.log("User info received:", xhr.responseText);
                try {
                    // Wrap number fields before parsing for consistency
                    const responseText = wrapNumberFieldsInQuotes(xhr.responseText);
                    const userInfo = JSON.parse(responseText); // Parse the modified text
                    callback(true, userInfo); // Success, return user info
                } catch (e) {
                    callback(false, "Failed to parse user info: " + e.message);
                }
            } else {
                callback(false, { status: xhr.status, message: "Failed to get user info: " + xhr.responseText });
            }
        }
    };

    xhr.onerror = function(e) {
        callback(false, { status: 0, message: "Network error or CORS issue (onerror triggered)." });
    };

    xhr.send(params);
}

function setUserInfo(token, moodScale, moodStatus, callback) {
    var xhr = new XMLHttpRequest();
    var url = API_BASE_URL + "/set-user-info";
    var params = "token=" + encodeURIComponent(token);
    
    // Add mood_scale parameter if provided
    if (moodScale !== undefined && moodScale !== null) {
        params += "&mood_scale=" + encodeURIComponent(moodScale);
    } else {
        params += "&mood_scale=";  // Empty value as seen in the test script
    }
    
    // Add mood_status parameter if provided
    if (moodStatus !== undefined && moodStatus !== null) {
        params += "&mood_status=" + encodeURIComponent(moodStatus);
    } else {
        params += "&mood_status=";  // Empty value as seen in the test script
    }

    xhr.open("POST", url, true);
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
               //console.log("User info updated:", xhr.responseText);
                callback(true, xhr.responseText); // Success
            } else {
                callback(false, "Failed to update user info: " + xhr.responseText); // Failure
            }
        }
    };

    xhr.onerror = function(e) {
        callback(false, { status: 0, message: "Network error or CORS issue (onerror triggered)." });
    };

    xhr.send(params);
}

// --- End Login/Register Functions ---
