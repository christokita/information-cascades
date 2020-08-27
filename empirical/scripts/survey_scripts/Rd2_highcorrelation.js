/* 
This is the javascript code to deploy our qualtrics survey for the high-correlation news treatment.
Sections below are labeled by where in the survey the code should be pasted.
*/


// /* -------------------- 
// Get participant's Twitter username
// --------------------*/
// // Paste in question asking particpant to confirm Twitter username
// Qualtrics.SurveyEngine.addOnUnload(function()
// {
//     jQuery("#"+this.questionId+" .InputText").on('blur',function(){
//         Qualtrics.SurveyEngine.setEmbeddedData('participant_username', jQuery(this).val());
//     });                       
// });


/* -------------------- 
Follow button prep
--------------------*/
// The accounts of our participants, listed in three batches
var accounts = [
    ['ChrisTokita', 'andyguess', 'adbecks', 'JustineABecker'], //batch 1
    ['NateSilver538', 'BarackObama', 'realDonaldTrump', 'Nate_Cohn'], //batch 2
    ['KingJames', 'AntDavis23', 'Giannis_An34', 'StephenCurry30'] //batch 3
];

// Get Twitter user name of particpant currently taking survey, clean up in case of poor formatting, and remove from list of accounts
var username = "${q://QID9/ChoiceTextEntryValue}"; 
username = username.replace(" ", "") //remove leading or trailing spaces
username = username.replace("@", "") //remove twitter @ tag in case they added that
for (var i = 0; i < accounts.length; i++) {
    accounts[i] = accounts[i].filter(x => x.toLowerCase() != username.toLowerCase()); //make it case insensitive
}

// Function to create random samples from a list, without replacement
function getRandomSubarray(arr, size) {
    var shuffled = arr.slice(0);
    var i = arr.length;
    var temp, index;
    while (i--) {
        index = Math.floor((i + 1) * Math.random());
        temp = shuffled[index];
        shuffled[index] = shuffled[i];
        shuffled[i] = temp;
    }
    return shuffled.slice(0, size);
}

//Sample our the accounts to show
var displayAccounts = [];
var sampledAccounts
for (var j = 0; j < accounts.length; j++) {
    sampledAccounts = getRandomSubarray(accounts[j], 2);
    displayAccounts = displayAccounts.concat(sampledAccounts)
}


/* -------------------- 
Follow request section
--------------------*/
// Request 1: Get button twitter button from HTML and swap in our a sampled Twitter account
var button1 = document.getElementById("twitter_button1");
button1.href = 'https://twitter.com/' + displayAccounts[0] + '?ref_src=twsrc%5Etfw'
Qualtrics.SurveyEngine.setEmbeddedData('Account1', displayAccounts[0]); //record what account was shown

// Request 2: Get button twitter button from HTML and swap in our a sampled Twitter account
var button2 = document.getElementById("twitter_button2");
button2.href = 'https://twitter.com/' + displayAccounts[1] + '?ref_src=twsrc%5Etfw';
Qualtrics.SurveyEngine.setEmbeddedData('Account2', displayAccounts[1]);

// Request 3: Get button twitter button from HTML and swap in our a sampled Twitter account
var button3 = document.getElementById("twitter_button3");
button3.href = 'https://twitter.com/' + displayAccounts[2] + '?ref_src=twsrc%5Etfw';
Qualtrics.SurveyEngine.setEmbeddedData('Account3', displayAccounts[2]);

// Request 4: Get button twitter button from HTML and swap in our a sampled Twitter account
var button4 = document.getElementById("twitter_button4");
button4.href = 'https://twitter.com/' + displayAccounts[3] + '?ref_src=twsrc%5Etfw';
Qualtrics.SurveyEngine.setEmbeddedData('Account4', displayAccounts[3]);

// Request 5: Get button twitter button from HTML and swap in our a sampled Twitter account
var button5 = document.getElementById("twitter_button5");
button5.href = 'https://twitter.com/' + displayAccounts[4] + '?ref_src=twsrc%5Etfw';
Qualtrics.SurveyEngine.setEmbeddedData('Account5', displayAccounts[4]);

// Request 6: Get button twitter button from HTML and swap in our a sampled Twitter account
var button6 = document.getElementById("twitter_button6");
button6.href = 'https://twitter.com/' + displayAccounts[5] + '?ref_src=twsrc%5Etfw';
Qualtrics.SurveyEngine.setEmbeddedData('Account6', displayAccounts[5]);


