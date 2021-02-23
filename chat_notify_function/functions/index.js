const functions = require("firebase-functions");
const admin = require('firebase-admin');

admin.initializeApp(functions.config().firebase);
var msgdata;
exports.msgTrigger = functions.firestore.document(
    'Messages/{msgId}'
).onCreate((snapshot, context) => {

    // msgdata will have the data of the Messages collection
    msgdata = snapshot.data();

    admin.firestore().collection('users').where('username', '==', msgdata.receiver).get().
        then((snapshots) => {

            if (snapshots.empty) {
                console.log('no device');
            }
            else {
                var token = snapshots.docs[0].data().devtoken;
                var payload = {
                    "notification": {
                        "title": msgdata.sendby,
                        "body": msgdata.message,
                        "sound": "default"
                    },
                    "data": {
                        "sendername": msgdata.sendby,
                        "message": msgdata.message
                    }
                }
                return admin.messaging().sendToDevice(token, payload).then((response) => {
                    console.log('sent');
                }).catch((err) => {
                    console.log(err);
                })
            }
        })
})