import 'package:CityLoads/helpers/conn_firestore.dart';
import 'package:CityLoads/screens/login.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mailer/smtp_server/gmail.dart';
import './payment.dart';
import 'package:email_validator/email_validator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './loader.dart';
import 'package:CityLoads/emails/welcome.dart' as Email;
import 'package:mailer/mailer.dart';

class Signup extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  late FirebaseAuth firebaseAuth;
  final firstnameFocus = FocusNode();
  final lastnameFocus = FocusNode();
  final emailFocus = FocusNode();
  final confirmEmailFocus = FocusNode();
  final passwordFocus = FocusNode();
  final confirmPasswordFocus = FocusNode();
  String firstname = "";
  String lastname = "";
  String email = "";
  String confirmEmail = "";
  String password = "";
  String confirmPassword = "";
  bool _remember = false;
  bool _skipPayment = false;
  bool? _accept = false;
  Widget? loadingButton;
  String? role;
  bool isLoading = false;
  SharedPreferences? prefs;
  String? privacyPolicy;
  String? terms;
  @override
  void initState() {
    Firebase.initializeApp().whenComplete(() {
      this.firebaseAuth = FirebaseAuth.instance;
    });
    DbFirestore().getPrivacyPolicy().then((data) {
      privacyPolicy = data.data()!['privacy_policy'];
      terms = data.data()!['terms'];
    });
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  openPrivacyPolicy(text) {
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext context) => StatefulBuilder(
                builder: (BuildContext context, StateSetter setModalState) {
              return SafeArea(
                child: Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const SizedBox(height: 30),
                      IconButton(
                          icon: SvgPicture.asset('assets/icons/close.svg'),
                          onPressed: () {
                            Navigator.pop(context);
                          }),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10.0),
                            child: HtmlWidget(
                              '''$text''',
                              // webView: false,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(
                  Ionicons.arrow_back,
                  color: Colors.black,
                  size: 30,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              backgroundColor: Colors.white,
              elevation: 0.0,
              title: Text('SIGN UP',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 22.0)),
            ),
            body: Stack(
              children: <Widget>[
                LayoutBuilder(builder:
                    (BuildContext context, BoxConstraints viewportConstraints) {
                  return SingleChildScrollView(
                      child: ConstrainedBox(
                          constraints: BoxConstraints(
                              minHeight: viewportConstraints.maxHeight),
                          child: Column(children: [
                            Container(
                                padding: EdgeInsets.all(20),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                      Column(
                                        children: <Widget>[
                                          Container(
                                            child: Transform(
                                                transform:
                                                    Matrix4.translationValues(
                                                        0, -24.0, 0.0),
                                                child: Text(
                                                    'Create your City Loads account',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                        color: Colors.black38,
                                                        fontSize: 17.0))),
                                          )
                                        ],
                                      ),
                                      Container(
                                          child: TextField(
                                              autofocus: true,
                                              focusNode: firstnameFocus,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 18.0),
                                              decoration: InputDecoration(
                                                  labelStyle: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w300),
                                                  labelText: 'First Name'),
                                              onChanged: (String value) {
                                                this.firstname = value.trim();
                                              })),
                                      Container(
                                          margin: EdgeInsets.only(top: 15.0),
                                          child: TextField(
                                              focusNode: lastnameFocus,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 18.0),
                                              decoration: InputDecoration(
                                                  labelStyle: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w300),
                                                  labelText: 'Last Name'),
                                              onChanged: (String value) {
                                                this.lastname = value.trim();
                                              })),
                                      Container(
                                          margin: EdgeInsets.only(top: 15.0),
                                          child: TextField(
                                              focusNode: emailFocus,
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 18.0),
                                              decoration: InputDecoration(
                                                  labelStyle: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w300),
                                                  labelText: 'Email'),
                                              onChanged: (String value) {
                                                this.email = value.trim();
                                              })),
                                      Container(
                                          margin: EdgeInsets.only(top: 15.0),
                                          child: TextField(
                                              focusNode: confirmEmailFocus,
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 18.0),
                                              decoration: InputDecoration(
                                                  labelStyle: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w300),
                                                  labelText: 'Confirm Email'),
                                              onChanged: (String value) {
                                                this.confirmEmail =
                                                    value.trim();
                                              })),
                                      Container(
                                          margin: EdgeInsets.only(top: 15.0),
                                          child: TextField(
                                              focusNode: passwordFocus,
                                              obscureText: true,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 18.0),
                                              decoration: InputDecoration(
                                                  labelStyle: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w300),
                                                  labelText: 'Password'),
                                              onChanged: (String value) {
                                                this.password = value.trim();
                                              })),
                                      Container(
                                          margin: EdgeInsets.only(top: 15.0),
                                          child: TextField(
                                              focusNode: confirmPasswordFocus,
                                              obscureText: true,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 18.0),
                                              decoration: InputDecoration(
                                                  labelStyle: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w300),
                                                  labelText:
                                                      'Confirm Password'),
                                              onChanged: (String value) {
                                                this.confirmPassword =
                                                    value.trim();
                                              })),

                                      // Container(
                                      //     margin: EdgeInsets.only(top: 30, bottom: 8),
                                      //     child: Text('PAYMENT',
                                      //         style: TextStyle(
                                      //             fontWeight: FontWeight.bold,
                                      //             fontSize: 18))),
                                      // Text(
                                      //     'Select a payment method for future in app purchases',
                                      //     style: TextStyle(
                                      //         fontSize: 17, color: Colors.black54)),
                                      // selectPaymentButton(),

                                      // Container(
                                      //   margin: EdgeInsets.only(top: 10, bottom: 15),
                                      //   child: Transform(
                                      //     transform:
                                      //         Matrix4.translationValues(-4, 0.0, 0.0),
                                      //     child: Row(
                                      //       children: <Widget>[
                                      //         SizedBox(
                                      //           width: 24.0,
                                      //           height: 24.0,
                                      //           child: Checkbox(
                                      //             value: this._skipPayment,
                                      //             onChanged: (newValue) {
                                      //               setState(() {
                                      //                 this._skipPayment = newValue;
                                      //               });
                                      //             },
                                      //           ),
                                      //         ),
                                      //         Container(
                                      //           margin:
                                      //               EdgeInsets.only(left: 10, top: 30),
                                      //         ),
                                      //         Text(
                                      //           "Skip payment for now",
                                      //           style: TextStyle(
                                      //               color: Colors.black54,
                                      //               fontSize: 16),
                                      //         ),
                                      //       ],
                                      //     ),
                                      //   ),
                                      // ),
                                    ]))
                          ])));
                }),
              ],
            ),
            bottomNavigationBar: BottomAppBar(
              elevation: 0,
              child: Container(
                  padding: EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        child: Transform(
                          transform: Matrix4.translationValues(-4, 0.0, 0.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(
                                width: 24.0,
                                height: 24.0,
                                child: Checkbox(
                                  value: this._accept,
                                  onChanged: (newValue) {
                                    setState(() {
                                      this._accept = newValue;
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(left: 10.0),
                                  child: RichText(
                                    text: TextSpan(
                                        style: TextStyle(fontFamily: 'Raleway'),
                                        children: [
                                          TextSpan(
                                            text: "I accept ",
                                            style: TextStyle(
                                                color: Colors.black54,
                                                fontSize: 16),
                                          ),
                                          TextSpan(
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                openPrivacyPolicy(terms);
                                              },
                                            text: "Term of Service",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                fontSize: 16),
                                          ),
                                          TextSpan(
                                            text: " and ",
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                fontSize: 16),
                                          ),
                                          TextSpan(
                                            text: "Privacy Policy",
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                openPrivacyPolicy(
                                                    privacyPolicy);
                                              },
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                fontSize: 16),
                                          )
                                        ]),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      Container(
                          margin: EdgeInsetsDirectional.only(top: 15),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Material(
                                    child: InkWell(
                                        onTap: () => {Navigator.pop(context)},
                                        child: Container(
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.black12)),
                                          child: Container(
                                              margin: EdgeInsets.only(
                                                  top: 17.0, bottom: 17.0),
                                              child: Text('CANCEL',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Theme.of(context)
                                                          .primaryColor))),
                                        ))),
                              ),
                              Container(
                                  margin: EdgeInsets.only(left: 6, right: 6)),
                              Expanded(
                                child: Material(
                                    color: Theme.of(context).primaryColor,
                                    child: InkWell(
                                        onTap: () => {signUp()},
                                        child: Container(
                                            margin: EdgeInsets.only(
                                                top: 17.0, bottom: 17.0),
                                            child: Text('SIGN UP',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white))))),
                              ),
                            ],
                          )),
                    ],
                  )),
            )),
        Positioned(
          child: isLoading ? Loader() : Container(),
        )
      ],
    );
  }

  Widget selectPaymentButton() {
    return Container(
        margin: EdgeInsets.only(top: 25, bottom: 5),
        child: ButtonTheme(
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                disabledBackgroundColor:
                    Theme.of(context).primaryColor.withOpacity(0.5),
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0))),
            child:
                Text('SELECT PAYMENT', style: TextStyle(color: Colors.white)),
            onPressed: this._skipPayment
                ? null
                : () => {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Payment()),
                      )
                    },
          ),
        ));
  }

  Color rememberColor() {
    return this._remember ? Colors.white : Colors.white30;
  }

  signUp() {
    if (firstname.isNotEmpty &&
        lastname.isNotEmpty &&
        email.isNotEmpty &&
        confirmEmail.isNotEmpty &&
        password.isNotEmpty &&
        confirmPassword.isNotEmpty &&
        _accept!) {
      if (!EmailValidator.validate(email)) {
        FocusScope.of(context).requestFocus(emailFocus);
      } else if (!EmailValidator.validate(confirmEmail)) {
        FocusScope.of(context).requestFocus(confirmEmailFocus);
      } else if (email != confirmEmail) {
        FocusScope.of(context).requestFocus(emailFocus);
        Fluttertoast.showToast(
          msg: "Emails do not match.",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      } else if (password != confirmPassword) {
        FocusScope.of(context).requestFocus(passwordFocus);
        Fluttertoast.showToast(
          msg: "Passwords do not match.",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      } else {
        var userData = {
          'firstName': firstname,
          'lastName': lastname,
          'email': email,
          'password': password
        };
        createUser(userData);
      }
    } else {
      if (firstname.isEmpty) {
        FocusScope.of(context).requestFocus(firstnameFocus);
      } else if (lastname.isEmpty) {
        FocusScope.of(context).requestFocus(lastnameFocus);
      } else if (email.isEmpty) {
        FocusScope.of(context).requestFocus(emailFocus);
      } else if (confirmEmail.isEmpty) {
        FocusScope.of(context).requestFocus(confirmEmailFocus);
      } else if (password.isEmpty) {
        FocusScope.of(context).requestFocus(passwordFocus);
      } else if (confirmPassword.isEmpty) {
        FocusScope.of(context).requestFocus(confirmPasswordFocus);
      } else if (!_accept!) {
        Fluttertoast.showToast(
          msg: "Please accept the Terms and Policy.",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  createUser(data) async {
    prefs = await SharedPreferences.getInstance();
    this.setState(() {
      isLoading = true;
    });

    UserCredential credential = (await firebaseAuth
        .createUserWithEmailAndPassword(
      email: data['email'],
      password: data['password'],
    )
        .catchError(
      (error) {
        var errorMessage =
            error.toString().replaceAll(RegExp(r'\[[^)]*\]'), '');
        Fluttertoast.showToast(
          msg: errorMessage,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      },
    ));

    if (credential != null) {
      User? firebaseUser = credential.user;
      if (firebaseUser != null) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .set({
          'id': firebaseUser.uid,
          'firstName': data['firstName'],
          'lastName': data['lastName'],
          'email': data['email'],
          'loginType': 'form',
          'photoUrl': firebaseUser.photoURL
        }).catchError(
          (error) {
            var errorMessage =
                error.toString().replaceAll(RegExp(r'\[[^)]*\]'), '');
            Fluttertoast.showToast(
              msg: errorMessage,
              backgroundColor: Colors.red,
              textColor: Colors.white,
            );
          },
        );

        ActionCodeSettings actionCodeSettings = ActionCodeSettings(
            url:
                'https://cityloads-301009.firebaseapp.com/__/auth/action?mode=action&oobCode=code',
            androidInstallApp: true,
            androidPackageName: 'com.cityloads.app',
            androidMinimumVersion: '1.0.1+6',
            iOSBundleId: 'com.cityloads.app',
            dynamicLinkDomain: 'cityloads.page.link');
        firebaseUser.sendEmailVerification(actionCodeSettings).then((value) {
          Fluttertoast.showToast(
            msg:
                "We sent you the email for verification. You might find the email in spam or junk mail.",
            backgroundColor: Colors.white,
            timeInSecForIosWeb: 5,
            textColor: Colors.black,
          );
        });
        sendWelcomeEmail(data['email']);

        // FirebaseAuth.instance.signOut().then((value) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => Login()),
            (Route<dynamic> route) => false);
        // });
      }
    }
    this.setState(() {
      isLoading = false;
    });
  }

  sendWelcomeEmail(String email) async {
    String emailAddress = '';
    String emailPassword = '';
    DocumentSnapshot<Map<String, dynamic>> _credential =
        await DbFirestore().getAdminCredential();
    emailAddress = _credential.data()!['email'];
    emailPassword = _credential.data()!['password'];

    var options = gmail(emailAddress, emailPassword);

    // Create our mail/envelope.
    var message = Message()
      ..from = 'info@city-loads.com'
      ..recipients.add(email)
      ..subject = 'Welcome to Cityloads'
      ..html = Email.htmlContent;

    // Email it.
    try {
      final sendReport = await send(message, options);
      print('Message sent: ' + sendReport.toString());
    } on MailerException catch (e) {
      print('Message not sent.');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
    }
  }
}
