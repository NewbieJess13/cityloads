import 'package:CityLoads/helpers/conn_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
String? SERVER_TOKEN = '';

getApiKeys() {
  DbFirestore().getKeys().then((_keys) {
    SERVER_TOKEN = _keys.data()['firebase_messaging_token'];
  });
}

SendNotification(
    String? userId, String title, String body, Map<String, dynamic> data) async {
  DocumentSnapshot<Map<String, dynamic>> userDoc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();
  getApiKeys();
  if (userDoc != null) {
    String? deviceToken = userDoc.data()!['deviceToken'];
    data['click_action'] = 'FLUTTER_NOTIFICATION_CLICK';
    if (deviceToken != null) {
      await http
          .post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=$SERVER_TOKEN',
        },
        body: jsonEncode(
          <String, dynamic>{
            'notification': <String, dynamic>{
              'title': title,
              'body': body,
            },
            'priority': 'high',
            'data': data,
            'to': deviceToken,
          },
        ),
      )
          .then((response) {
        // Fluttertoast.showToast(
        //     msg: 'Notification: ' + response.body,
        //     backgroundColor: Colors.red,
        //     textColor: Colors.white,
        //     timeInSecForIosWeb: 5,
        //     gravity: ToastGravity.TOP);
      });
      await http
          .post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=$SERVER_TOKEN',
        },
        body: jsonEncode(
          <String, dynamic>{
            'priority': 'high',
            'data': data,
            'to': deviceToken,
          },
        ),
      )
          .then((response) {
        // Fluttertoast.showToast(
        //     msg: 'No Notification: ' + response.body,
        //     backgroundColor: Colors.red,
        //     textColor: Colors.white,
        //     timeInSecForIosWeb: 5,
        //     gravity: ToastGravity.BOTTOM);
      });
    }
  }
}
