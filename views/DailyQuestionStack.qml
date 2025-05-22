import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "CallAPI.js" as CallAPI
import "./dailyQuestion/"

Item {
    id: root
    width: parent.width
    height: parent.height

    // Properties
    property string DailyQuestionResult: ""
    property string dailyQuestion: ""
    property string currentResponse: ""
    property string partnerAnswer: ""
    property string jwtToken: ""
    property string errorMessage: ""
    property string currentView: "dailyQuestion"
    property var parameters: null
    // Signals
    signal submitResponse(string response, string question)

    StackLayout {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            margins: 16
        }
        id: stackLayout
        currentIndex: {
            switch (root.currentView) {
            case "dailyQuestion":
                return 0
            case "result":
                root.dailyQuestion = root.parameters.question;
                root.currentResponse = root.parameters.userAnswer;
                root.partnerAnswer = root.parameters.partnerAnswer;
                return 1
            case "error":
                root.errorMessage = root.parameters.errorMessage;
                return 2
            default:
                return 0
            }
        }
        DailyQuestionView {
            id: dailyQuestionView
            jwtToken: root.jwtToken

            dailyQuestion: root.dailyQuestion
            currentResponse: root.currentResponse
            onSubmitResponse: function (response, question) {
                root.currentResponse = response;
                submitResponse(response, question);
            }
            onSwitchToDifferentView: function (view, parameters) {
                root.currentView = view;
                root.parameters = parameters;
            }
        }
    }
}
