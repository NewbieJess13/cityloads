import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mailer/smtp_server.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mailer/mailer.dart';
import 'package:CityLoads/helpers/conn_firestore.dart';

class HelpScreen extends StatefulWidget {
  @override
  _HelpScreenState createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  FocusNode subjectFocus = FocusNode();
  TextEditingController subjectController = TextEditingController();
  FocusNode emailFocus = FocusNode();
  TextEditingController emailController = TextEditingController();
  FocusNode concernFocus = FocusNode();
  TextEditingController concernController = TextEditingController();
  SharedPreferences? prefs;
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    subjectFocus.dispose();
    subjectController.dispose();
    concernFocus.dispose();
    concernController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(15, 5, 15, 0),
        child: SafeArea(
          child: Column(children: [
            Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Ionicons.close,
                      size: 30,
                    ))),
            const SizedBox(height: 10),
            Text('We are here to help. Please let us know about your concern.',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            TextField(
              focusNode: emailFocus,
              controller: emailController,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18.0),
              decoration: InputDecoration(
                focusedBorder: OutlineInputBorder(borderSide: BorderSide()),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide()),
                labelStyle: TextStyle(fontWeight: FontWeight.w300),
                labelText: 'Email',
              ),
            ),
            SizedBox(
              height: 10,
            ),
            TextField(
              focusNode: subjectFocus,
              controller: subjectController,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18.0),
              decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide()),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide()),
                  labelStyle: TextStyle(fontWeight: FontWeight.w300),
                  labelText: 'Subject'),
            ),
            const SizedBox(height: 10),
            TextField(
              focusNode: concernFocus,
              controller: concernController,
              maxLines: 10,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18.0,
              ),
              decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide()),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide()),
                  labelStyle: TextStyle(fontWeight: FontWeight.w300),
                  hintText: 'Can you ellaborate your concern?',
                  hintStyle:
                      TextStyle(fontWeight: FontWeight.w300, fontSize: 13),
                  labelText: 'Message'),
            ),
            const SizedBox(height: 10),
            Material(
              color: Theme.of(context).primaryColor,
              child: InkWell(
                onTap: () => submitConcern(),
                child: Container(
                  margin: EdgeInsets.only(top: 17.0, bottom: 17.0),
                  width: double.infinity,
                  child: Text(
                    'SUBMIT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  submitConcern() async {
    if (subjectController.text.isEmpty) {
      subjectFocus.requestFocus();
    } else if (concernController.text.isEmpty) {
      concernFocus.requestFocus();
    } else if (emailController.text.isEmpty) {
      emailFocus.requestFocus();
    }
    // else if (EmailValidator.validate(emailController.text)) {
    //   Fluttertoast.showToast(
    //     msg: "Invalid Email. ",
    //     backgroundColor: Colors.red,
    //     timeInSecForIosWeb: 3,
    //     textColor: Colors.white,
    //   );
    //   return;
    // }
    String emailAddress = '';
    String emailPassword = '';

    await DbFirestore().getAdminCredential().then((_credential) {
      emailAddress = _credential.data()!['email'];
      emailPassword = _credential.data()!['password'];
    });

    var options = gmail(emailAddress, emailPassword);
    // ..username = emailAddress!
    // ..password = emailPassword!;

    // Create our mail/envelope.
    var message = new Message()
      ..from = 'noreply@city-loads.com'
      ..recipients.add('info@city-loads.com')
      ..envelopeTos = [emailController.text]
      ..subject = 'Help Inquiry: ${subjectController.text}'
      ..html =
          '<div><strong>From: </strong>${emailController.text}</div><div><strong>Message: </strong>${concernController.text}</div>';

    try {
      var sendReport = await send(message, options);
      print('Message sent: ' + sendReport.toString());
    } on MailerException catch (e) {
      print('Message not sent.');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
    }
    // Email it.

    Fluttertoast.showToast(
      msg:
          "Your concern has been submitted. We will get back to you as soon as possible. ",
      backgroundColor: Colors.black,
      timeInSecForIosWeb: 3,
      textColor: Colors.white,
    );

    Navigator.of(context).pop();

    // FirebaseFirestore.instance.collection('concerns').add({
    //   'subject': subjectController.text,
    //   'message': concernController.text,
    //   'user_email': emailController.text,
    // }).then((value) {
    //   Fluttertoast.showToast(
    //     msg:
    //         "Your concern has been submitted. We will get back to you as soon as possible. ",
    //     backgroundColor: Colors.black,
    //     timeInSecForIosWeb: 3,
    //     textColor: Colors.white,
    //   );
    //   Navigator.of(context).pop();
    // });
  }
}
