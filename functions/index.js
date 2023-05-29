const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp(functions.config().firebase);

const firestore = functions.firestore;

exports.onUserStatusChange = functions.database.ref('/status/{userId}').onUpdate((event, context) => {
	var db = admin.firestore();
	var fieldValue = require('firebase-admin').firestore.FieldValue;

	const usersRef = db.collection('users');
	var snapShot = event.after;

	return event.after.ref
		.once('value')
		.then(statusSnap => snapShot.val())
		.then(status => {
			if (status === 'offline') {
				usersRef.doc(context.params.userId).update({
					isOnline: false
				});
			}
			return null;
		});
});
