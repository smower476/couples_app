pragma ComponentBehavior: Bound
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    width: parent.width
    height: parent.height

    // completedQuizData will now receive an object:
    // { answeredQuizDetails: ..., quizContent: ... }
    property var completedQuizData: null
    property var processedResults: null // To store the transformed data

    signal acknowledged()

    // Function to decode answers (moved from QuizzesView)
    function decodeAnswers(encoded, itemCount) {
        if (encoded === null || encoded === undefined || encoded === "null") {
            return new Array(itemCount).fill(0);
        }
        let encoded_num = parseInt(encoded, 10);
        if (isNaN(encoded_num)) {
            return new Array(itemCount).fill(0);
        }
        let bin = encoded_num.toString(2);
        const expectedBits = itemCount * 2; // Each item (answer/guess) takes 2 bits
        while (bin.length < expectedBits) {
            bin = "0" + bin;
        }
        if (bin.length > expectedBits) {
            // This case should ideally not happen if encoding is correct
            console.warn("decodeAnswers: binary string longer than expected, truncating. Original:", bin, "Expected bits:", expectedBits);
            bin = bin.substr(bin.length - expectedBits);
        }
        let arr = [];
        for (let i = 0; i < itemCount; ++i) {
            let bits = bin.substr(i * 2, 2);
            arr.push(parseInt(bits, 2) + 1); // Add 1 because answers are 1-4, but stored as 0-3 in bits
        }
        return arr;
    }

    // Function to process the raw data into displayable results
    function processQuizResults() {
        if (!completedQuizData || !completedQuizData.answeredQuizDetails || !completedQuizData.quizContent) {
            console.log("QuizzesViewCompleted: Insufficient data to process results.");
            root.processedResults = null;
            return;
        }

        const lastAnsweredQuiz = completedQuizData.answeredQuizDetails;
        const quizContent = completedQuizData.quizContent;
        const quizName = quizContent.quiz_name || "Completed Quiz Results";
        const questionCount = quizContent.quiz_content.length;

        let selfAnswers = [];
        let partnerAnswers = [];
        let yourGuesses = [];
        let partnerGuessesAboutSelf = [];
        let partnerCorrectGuesses = 0;
        let yourCorrectGuesses = 0;

        // The self_answer from API contains both self's answers and self's guesses about partner
        // The partner_answer from API contains both partner's answers and partner's guesses about self
        // Each part (answers, guesses) has 'questionCount' items. So, total items = questionCount * 2.

        if (lastAnsweredQuiz.self_answer) {
            const combinedDecodedSelf = decodeAnswers(lastAnsweredQuiz.self_answer, questionCount * 2);
            selfAnswers = combinedDecodedSelf.slice(0, questionCount);
            yourGuesses = combinedDecodedSelf.slice(questionCount);
        } else {
            selfAnswers = new Array(questionCount).fill(0);
            yourGuesses = new Array(questionCount).fill(0);
        }

        let partnerDidntAnswer = lastAnsweredQuiz.partner_answer === null || lastAnsweredQuiz.partner_answer === "null" || lastAnsweredQuiz.partner_answer === undefined;
        if (!partnerDidntAnswer) {
            const combinedDecodedPartner = decodeAnswers(lastAnsweredQuiz.partner_answer, questionCount * 2);
            partnerAnswers = combinedDecodedPartner.slice(0, questionCount);
            partnerGuessesAboutSelf = combinedDecodedPartner.slice(questionCount);
        } else {
            partnerAnswers = new Array(questionCount).fill(0);
            partnerGuessesAboutSelf = new Array(questionCount).fill(0);
        }

        const transformed = {
            id: lastAnsweredQuiz.id || lastAnsweredQuiz.quiz_id,
            title: quizName,
            totalQuestions: questionCount,
            questions: quizContent.quiz_content.map((question, index) => {
                const questionText = question.content_data;

                const selfAnsValue = (selfAnswers.length > index) ? selfAnswers[index] : 0;
                const selfIdx = selfAnsValue > 0 ? selfAnsValue - 1 : -1;
                const selfText = (selfIdx >= 0 && question.answers[selfIdx])
                    ? question.answers[selfIdx].answer_content
                    : "No answer";

                const partnerAnsValue = (!partnerDidntAnswer && partnerAnswers.length > index) ? partnerAnswers[index] : 0;
                const partnerIdx = partnerAnsValue > 0 ? partnerAnsValue - 1 : -1;
                const partnerText = partnerDidntAnswer
                    ? "Partner didn't answer"
                    : ((partnerIdx >= 0 && question.answers[partnerIdx])
                        ? question.answers[partnerIdx].answer_content
                        : "No answer");

                const yourGuessValue = (yourGuesses.length > index) ? yourGuesses[index] : 0;
                let yourGuessText = "No guess";
                if (yourGuessValue > 0) {
                    const yourGuessIdx = yourGuessValue - 1;
                    if (yourGuessIdx >= 0 && question.answers[yourGuessIdx]) {
                        yourGuessText = question.answers[yourGuessIdx].answer_content;
                    }
                }

                const partnerGuessValue = (!partnerDidntAnswer && partnerGuessesAboutSelf.length > index) ? partnerGuessesAboutSelf[index] : 0;
                let partnerGuessAboutSelfText = "No guess";
                if (partnerGuessValue > 0) {
                    const partnerGuessIdx = partnerGuessValue - 1;
                    if (partnerGuessIdx >= 0 && question.answers[partnerGuessIdx]) {
                        partnerGuessAboutSelfText = question.answers[partnerGuessIdx].answer_content;
                    }
                }
                
                let currentYourGuessCorrect = false;
                if (!partnerDidntAnswer && yourGuessValue > 0 && partnerAnsValue > 0) { // Both must have answered/guessed
                    currentYourGuessCorrect = (yourGuessValue === partnerAnsValue);
                    if (currentYourGuessCorrect) {
                        yourCorrectGuesses++;
                    }
                }

                let currentPartnerGuessCorrect = false;
                if (partnerGuessValue > 0 && selfAnsValue > 0) { // Both must have answered/guessed
                     currentPartnerGuessCorrect = (partnerGuessValue === selfAnsValue);
                    if (currentPartnerGuessCorrect) {
                        partnerCorrectGuesses++;
                    }
                }

                return {
                    question: questionText,
                    self: selfText,
                    partner: partnerText,
                    yourGuess: yourGuessText,
                    yourGuessCorrect: currentYourGuessCorrect,
                    partnerGuessAboutSelf: partnerGuessAboutSelfText,
                    partnerGuessCorrect: currentPartnerGuessCorrect
                };
            }),
            yourCorrectGuesses: yourCorrectGuesses,
            partnerCorrectGuesses: partnerCorrectGuesses,
            partnerDidntAnswer: partnerDidntAnswer
        };
        root.processedResults = transformed;
        console.log("QuizzesViewCompleted: Processed results:", JSON.stringify(transformed, null, 2));
    }

    // When completedQuizData changes, re-process it
    onCompletedQuizDataChanged: {
        console.log("QuizzesViewCompleted: completedQuizData changed, processing...");
        processQuizResults();
    }
    
    // Initialize on component completion if data is already there
    Component.onCompleted: {
        if (completedQuizData) {
            console.log("QuizzesViewCompleted: Component completed, processing initial data...");
            processQuizResults();
        }
    }


    Rectangle {
        anchors.fill: parent
        color: "#121212"
        
        Rectangle {
            anchors.fill: parent
            anchors.margins: 10
            color: "transparent"
            border.color: "#ec4899" 
            border.width: 1
            radius: 10
        }

        ScrollView {
            anchors.fill: parent
            anchors.margins: 20
            contentWidth: parent.width - 40
            clip: true

            ColumnLayout {
                width: parent.width
                spacing: 15

                Text {
                    Layout.fillWidth: true
                    text: "🎉 Congratulations! 🎉"
                    font.pixelSize: 24
                    font.bold: true
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    Layout.fillWidth: true
                    text: "You've completed the Daily Quiz!"
                    font.pixelSize: 16
                    color: "#d1d5db" 
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    Layout.fillWidth: true
                    text: root.processedResults.title
                    font.pixelSize: 20
                    font.bold: true
                    color: "#d1d5db"
                    horizontalAlignment: Text.AlignHCenter
                    Layout.topMargin: 10
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: "#4b5563" 
                    Layout.topMargin: 10
                    Layout.bottomMargin: 10
                }

                Text {
                    Layout.fillWidth: true
                    text: "Quiz Results:" 
                    font.pixelSize: 18
                    font.bold: true
                    color: "white"
                }

                Repeater {
                    id: resultsRepeater
                    // Use processedResults for display
                    model: root.processedResults.questions

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: resultContentColumn.height + 20
                        color: "#1f1f1f"
                        radius: 5
                        Layout.bottomMargin: 10
                        id: resultContent
                        required property var modelData
                        property var questionObj: modelData

                        Column {
                            id: resultContentColumn
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: 10
                            }
                            spacing: 4

                            Text {
                                width: parent.width
                                text: "Q: " + (resultContent.questionObj.question)
                                font.pixelSize: 14
                                color: "#e5e7eb"
                                wrapMode: Text.Wrap
                            }

                            Text {
                                width: parent.width
                                text: "You: " + (resultContent.questionObj.self || "No answer")
                                font.pixelSize: 14
                                color: "white"
                                font.bold: true
                                wrapMode: Text.Wrap
                                topPadding: 4
                            }

                            Text {
                                width: parent.width
                                text: "Partner: " + (resultContent.questionObj.partner || "No answer")
                                font.pixelSize: 14
                                color: "#ec4899"
                                font.bold: true
                                wrapMode: Text.Wrap
                                topPadding: 2
                            }

                            Text {
                                width: parent.width
                                text: "Your Guess: " + (resultContent.questionObj.yourGuess || "No guess") 
                                font.pixelSize: 14
                                color: {
                                    if (!resultContent.questionObj.yourGuess || resultContent.questionObj.yourGuess === "No guess") return "#9ca3af"; 
                                    return resultContent.questionObj.yourGuessCorrect ? "#4ade80" : "#f87171"; 
                                }
                                font.bold: true
                                wrapMode: Text.Wrap
                                topPadding: 2
                                visible: resultContent.questionObj.hasOwnProperty('yourGuess') 
                            }

                            Text {
                                width: parent.width
                                text: "Partners Guess: " + (resultContent.questionObj.partnerGuessAboutSelf || "No guess") 
                                font.pixelSize: 14
                                color: {
                                    if (!resultContent.questionObj.partnerGuessAboutSelf || resultContent.questionObj.partnerGuessAboutSelf === "No guess") return "#9ca3af"; 
                                    return resultContent.questionObj.partnerGuessCorrect ? "#4ade80" : "#f87171"; 
                                }
                                font.bold: true
                                wrapMode: Text.Wrap
                                topPadding: 2
                                visible: resultContent.questionObj.hasOwnProperty('partnerGuessAboutSelf') 
                            }
                        }
                    }
                }

                Text {
                    id: scoreText
                    Layout.fillWidth: true
                    text: {
                        // Use processedResults for display
                        if (root.processedResults && root.processedResults.hasOwnProperty('yourCorrectGuesses') && root.processedResults.hasOwnProperty('partnerCorrectGuesses') && root.processedResults.hasOwnProperty('totalQuestions')) {
                           const total = root.processedResults.totalQuestions;
                           const yourScore = root.processedResults.yourCorrectGuesses;
                           const partnerScore = root.processedResults.partnerCorrectGuesses;
                           let scoreString = "";
                           if (!root.processedResults.partnerDidntAnswer) {
                               scoreString = "Your Guesses Correct: " + yourScore + "/" + total;
                               scoreString += "\nPartner's Guesses Correct: " + partnerScore + "/" + total;
                           } else {
                               scoreString = "Partner hasn't answered yet.";
                           }
                           return scoreString;
                        }
                        return "Processing results..."; 
                    }
                    font.pixelSize: 16
                    color: "#a5b4fc" 
                    horizontalAlignment: Text.AlignHCenter
                    Layout.topMargin: 15
                    visible: text !== "" 
                }

                Text {
                    Layout.fillWidth: true
                    text: "No answers available."
                    font.pixelSize: 14
                    color: "#9ca3af" 
                    horizontalAlignment: Text.AlignHCenter
                    // Use processedResults for display
                    visible: !root.processedResults || !root.processedResults.questions || root.processedResults.questions.length === 0
                }

                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 20
                    text: "Come back tomorrow for a new quiz!"
                    font.pixelSize: 16
                    color: "#ec4899" 
                    horizontalAlignment: Text.AlignHCenter
                }
                
                Button {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 20
                    text: "Back to Hub"
                    background: Rectangle {
                        implicitWidth: 200
                        implicitHeight: 50
                        radius: 25
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#ec4899" }
                            GradientStop { position: 1.0; color: "#db2777" }
                        }
                    }
                    contentItem: Text {
                        text: parent.text
                        font.pixelSize: 16
                        font.bold: true
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: root.acknowledged()
                }

                Item { Layout.preferredHeight: 20 }
            }
        }
    }
}