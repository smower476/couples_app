const API_BASE_URL = "http://129.158.234.85:8080"; // Define base URL

function getDailyQuizId(token, callback) {
    var xhr = new XMLHttpRequest();
    var url = API_BASE_URL + "/get-daily-quiz";
    var params = "token=" + encodeURIComponent(token);

    xhr.open("POST", url, true);
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                console.log("Daily Quiz ID received:", xhr.responseText);
                callback(true, xhr.responseText); // Success, return quiz ID
            } else {
                console.error("Get daily quiz ID error:", xhr.status, xhr.responseText);
                callback(false, "Failed to get daily quiz ID: " + xhr.responseText); // Failure
            }
        }
    };

    xhr.send(params);
}

function getQuizContent(token, quizId, callback) {
    var xhr = new XMLHttpRequest();
    var url = API_BASE_URL + "/get-quiz-content";
    var params = "token=" + encodeURIComponent(token) + "&quiz_id=" + encodeURIComponent(quizId);

    xhr.open("POST", url, true);
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                console.log("Quiz content received:", xhr.responseText);
                callback(true, JSON.parse(xhr.responseText)); // Success, return quiz content
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
                var response = JSON.parse(xhr.responseText);
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
                callback(true, xhr.responseText); // Success
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
                // Assuming the response text is the JWT token directly
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
    if (xhr.readyState === XMLHttpRequest.DONE) {
        if (xhr.status === 200) {
            console.log("Link code received:", xhr.responseText);
            // Assuming the response text is the link code directly
            callback(true, xhr.responseText); // Success, return link code
        } else {
            console.error("Get link code error:", xhr.status, xhr.responseText);
            callback(false, "Failed to get link code: " + xhr.responseText); // Failure
        }
    }
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
                callback(true, xhr.responseText); // Success
            } else {
                console.error("Link users error:", xhr.status, xhr.responseText);
                callback(false, "Failed to link users: " + xhr.responseText); // Failure
            }
        }
    };

    xhr.send(params);
}

// --- End Login/Register Functions ---



