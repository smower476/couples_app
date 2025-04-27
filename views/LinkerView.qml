import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "CallAPI.js" as CallAPI // Import the API functions

Item {
    id: root
    width: parent.width
    height: parent.height
    
    // Properties
    property bool partnerLinked: false
    property string inviteCode: ""
    property string jwtToken: "" // Add property to hold the JWT token
    property string userLinkCode: "Loading..." // Property to hold the fetched link code
    property string errorMessage: "" // Property to hold error messages
    property string partnerName: "" // Property to hold the partner's name

    // Signals
    signal linkPartner()

    // Function to fetch the link code
    function fetchLinkCode() {
        if (jwtToken !== "") {
            //console.log("Fetching link code with token:", jwtToken)
            CallAPI.getLinkCode(jwtToken, function(success, result) {
                if (success) {
                    //console.log("Link code received:", result)
                    userLinkCode = result;
                } else {
                    // Handle 409 (already connected) with new error object
                    if (result && typeof result === "object" && result.status === 409) {
                        //console.log("409 error received in fetchLinkCode. Attempting to fetch partner info."); // Debug statement
                        CallAPI.getPartnerInfo(jwtToken, function(partnerSuccess, partnerResult) {
                            if (partnerSuccess && partnerResult && partnerResult.username) {
                                partnerName = partnerResult.username;
                                partnerLinked = true;
                                errorMessage = "";
                            } else {
                                //console.error("Failed to get partner info after 409:", partnerResult);
                                partnerLinked = true; // Still show linked screen even if name fetch fails
                                partnerName = "Partner"; // Default name
                                errorMessage = "Could not fetch partner name.";
                            }
                        });
                    } else if (typeof result === "string" && result.indexOf("409") !== -1) {
                        // fallback for string error
                        //console.log("409 error (string fallback) received in fetchLinkCode. Attempting to fetch partner info."); // Debug statement
                         CallAPI.getPartnerInfo(jwtToken, function(partnerSuccess, partnerResult) {
                            if (partnerSuccess && partnerResult && partnerResult.username) {
                                partnerName = partnerResult.username;
                                partnerLinked = true;
                                errorMessage = "";
                            } else {
                                //console.error("Failed to get partner info after 409 string:", partnerResult);
                                partnerLinked = true; // Still show linked screen even if name fetch fails
                                partnerName = "Partner"; // Default name
                                errorMessage = "Could not fetch partner name.";
                             }
                         });
                     } else {
                         //console.error("Failed to get link code:", result);
                         userLinkCode = "Error"; // Display error in UI
                         errorMessage = "Failed to get link code: " + (result && result.message ? result.message : result);
                     }
                 }
             });
         } else {
             //console.log("JWT token not available yet for fetching link code.");
             userLinkCode = "Login Required"; // Indicate user needs to be logged in
             errorMessage = "Please log in first to get your invite code.";
         }
     }

    // Fetch the code when the component is ready AND token is available
    Component.onCompleted: {
        fetchLinkCode();
    }

    // Also fetch if the token becomes available later
    Connections {
        target: root
        function onJwtTokenChanged() {
            if (userLinkCode === "Loading..." || userLinkCode === "Login Required" || userLinkCode === "Error") {
                 fetchLinkCode();
            }
        }
    }
    
    ColumnLayout {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            margins: 16
        }
        spacing: 20
        
        // Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            color: "transparent"
            
            Text {
                anchors.centerIn: parent
                text: root.partnerLinked ? "💕 Connected" : "🔗 Link Your Partner"
                font.pixelSize: 24
                font.bold: true
                color: "white"
            }
        }
        
        // Content depends on linked status
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            // Not linked UI
            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width
                spacing: 20
                visible: !root.partnerLinked
                
                // Input field
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    Layout.maximumWidth: 300
                    Layout.alignment: Qt.AlignHCenter
                    color: "#1f1f1f" // gray-800
                    radius: 8
                    
                    TextField {
                        id: inviteCodeField
                        anchors.fill: parent
                        anchors.margins: 4
                        placeholderText: "Enter partner's invite code"
                        placeholderTextColor: "#9ca3af"
                        horizontalAlignment: TextInput.AlignHCenter
                        color: "#9ca3af" // Changed from white to gray color
                        background: null
                        
                        onTextChanged: {
                            root.inviteCode = text
                            root.errorMessage = "" // Clear error message when text changes
                        }
                    }
                }
                
                // Error message display
                Text {
                    id: errorText
                    text: root.errorMessage
                    color: "#ef4444" // Red color for error
                    font.pixelSize: 14
                    visible: root.errorMessage !== ""
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 300
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                }
                
                // Link button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    Layout.maximumWidth: 300
                    Layout.alignment: Qt.AlignHCenter
                    color: "#ec4899" // pink-600
                    radius: 8
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Link Partner 💑"
                        font.pixelSize: 16
                        font.bold: true
                        color: "white"
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            var codeToLink = root.inviteCode.trim();
                            if (codeToLink !== "" && root.jwtToken !== "") {
                                //console.log("Attempting to link with code:", codeToLink);
                                CallAPI.linkUsers(root.jwtToken, codeToLink, function(success, result) {
                                    if (success) {
                                        //console.log("Successfully linked partners:", result);
                                        CallAPI.getPartnerInfo(root.jwtToken, function(partnerSuccess, partnerResult) {
                                            if (partnerSuccess && partnerResult && partnerResult.username) {
                                                root.partnerName = partnerResult.username;
                                                root.partnerLinked = true;
                                                root.errorMessage = "";
                                                root.linkPartner(); // Emit signal after getting partner name
                                            } else {
                                                //console.error("Failed to get partner info after linking:", partnerResult);
                                                root.partnerLinked = true; // Still show linked screen even if name fetch fails
                                                root.partnerName = "Partner"; // Default name
                                                root.errorMessage = "Successfully linked, but could not fetch partner name.";
                                                root.linkPartner(); // Emit signal even if name fetch fails
                                            }
                                        });
                                    } else {
                                        //console.error("Failed to link partners:", result);
                                        // Handle 409 error (already linked)
                                        if (result && typeof result === "object" && result.status === 409) {
                                            console.log("409 error received in linkUsers. Attempting to fetch partner info."); // Debug statement
                                            root.errorMessage = "You are already linked with a partner.";
                                            // Optionally fetch partner info here too if linking fails due to already linked
                                            CallAPI.getPartnerInfo(root.jwtToken, function(partnerSuccess, partnerResult) {
                                                if (partnerSuccess && partnerResult && partnerResult.username) {
                                                    root.partnerName = partnerResult.username;
                                                    root.partnerLinked = true;
                                                    root.errorMessage = "You are already linked with " + root.partnerName + ".";
                                                } else {
                                                    root.partnerLinked = true;
                                                    root.partnerName = "Partner";
                                                    root.errorMessage = "You are already linked with a partner, but could not fetch their name.";
                                                }
                                            });
                                        } else if (typeof result === "string" && result.indexOf("409") !== -1) {
                                            console.log("409 error (string fallback) received in linkUsers. Attempting to fetch partner info."); // Debug statement
                                            root.errorMessage = "You are already linked with a partner.";
                                            // Optionally fetch partner info here too if linking fails due to already linked (string fallback)
                                            CallAPI.getPartnerInfo(root.jwtToken, function(partnerSuccess, partnerResult) {
                                                if (partnerSuccess && partnerResult && partnerResult.username) {
                                                    root.partnerName = partnerResult.username;
                                                    root.partnerLinked = true;
                                                    root.errorMessage = "You are already linked with " + root.partnerName + ".";
                                                } else {
                                                    root.partnerLinked = true;
                                                    root.partnerName = "Partner";
                                                    root.errorMessage = "You are already linked with a partner, but could not fetch their name.";
                                                }
                                            });
                                        } else {
                                            // Show error message to user in the UI
                                            root.errorMessage = "Failed to link: " + (result && result.message ? result.message : result);
                                        }
                                    }
                                });
                            } else if (root.jwtToken === "") {
                                //console.error("Cannot link: User not logged in (no JWT token).");
                                // Show message: "Please log in first."
                                root.errorMessage = "Please log in first to link with your partner.";
                            } else {
                                //console.log("Cannot link: Invite code field is empty.");
                                // Show message: "Please enter partner's code."
                                root.errorMessage = "Please enter your partner's invite code.";
                            }
                        }
                    }
                }
                
                // Your invite code
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 100
                    Layout.maximumWidth: 300
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 40
                    color: "#1f1f1f" // gray-800
                    radius: 8
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        
                        Text {
                            text: "Your invite code:"
                            font.pixelSize: 14
                            color: "#9ca3af" // gray-400
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        Text {
                            id: linkCodeText
                            text: root.userLinkCode // Bind to the userLinkCode property
                            font.pixelSize: 24
                            font.bold: true
                            color: "#ec4899" // pink-600
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        Text {
                            text: "Share this with your partner"
                            font.pixelSize: 12
                            color: "#9ca3af" // gray-400
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }
            
            // Linked UI
            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width
                spacing: 20
                visible: root.partnerLinked
                
                Image {
                    source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='100' height='100' viewBox='0 0 24 24' fill='none' stroke='%23ec4899' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z'/></svg>"
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 100
                }
                
                Text {
                    id: connectedText // Added ID for easier reference
                    text: "Connected with " + root.partnerName // Use the partnerName property
                    font.pixelSize: 24
                    font.bold: true
                    color: "white"
                    Layout.alignment: Qt.AlignHCenter
                }
                
                Text {
                    text: "You're now linked! Share moments, take quizzes, and grow together."
                    font.pixelSize: 16
                    color: "#9ca3af" // gray-400
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    Layout.maximumWidth: 300
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}