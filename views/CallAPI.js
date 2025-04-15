// network.js
function getDailyQuestion(callback, apiKey) {
    var xhr = new XMLHttpRequest();
    xhr.open("GET", "https://api.api-ninjas.com/v1/trivia");
    xhr.setRequestHeader("X-Api-Key", apiKey);  // Set your API key here

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                var response = JSON.parse(xhr.responseText);
                callback(response[0].question);  // Call the callback function with the new question
            } else {
                console.log("Error:", xhr.status, xhr.responseText);
                callback("Not able to load");
            }
        }
    };

    xhr.send();
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

// Function to fetch multiple random words in parallel
function fetchRandomWords(count, apiKey, callback) {
    var words = [];
    var completedRequests = 0;

    for (let i = 0; i < count; i++) {
        let xhr = new XMLHttpRequest();
        // Add a unique timestamp query parameter to prevent caching
        xhr.open("GET", `https://api.api-ninjas.com/v1/randomword`);
        xhr.setRequestHeader("X-Api-Key", apiKey);

        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        let response = JSON.parse(xhr.responseText);
                        if (response.word) {
                            words.push(response.word[0]);
                        } else {
                            console.log("Unexpected response:", response);
                        }
                    } catch (e) {
                        console.log("Error parsing JSON:", e);
                    }
                } else {
                    console.log("Error:", xhr.status, xhr.responseText);
                }
                
                // --- Login/Register Functions ---
                
                const API_BASE_URL = "http://129.158.234.85:8080"; // Define base URL
                
                function registerUser(username, password, callback) {
                    var xhr = new XMLHttpRequest();
                    var url = API_BASE_URL + "/add-user";
                    var params = "username=" + encodeURIComponent(username) + "&password=" + encodeURIComponent(password);
                
                    xhr.open("POST", url, true);
                    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
                
                    xhr.onreadystatechange = function() {
                        if (xhr.readyState === XMLHttpRequest.DONE) {
                            if (xhr.status === 200) {
                                console.log("Registration successful:", xhr.responseText);
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
                
                // --- End Login/Register Functions ---
                completedRequests++;

                // When all requests finish, execute the callback
                if (completedRequests === count) {
                    callback(words);
                }
            }
        };

        xhr.send();
    }
}

// Function to shuffle an array randomly
function shuffleArray(array) {
    for (let i = array.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [array[i], array[j]] = [array[j], array[i]]; // Swap elements
    }
}


