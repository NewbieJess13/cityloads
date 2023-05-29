import 'package:CityLoads/screens/countries.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import './loader.dart';
import './home.dart';
import './signup.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class Login extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: [
      'email',
    ],
  );
  FirebaseAuth firebaseAuth;
  SharedPreferences prefs;
  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();
  String _email = "";
  String _password = "";
  bool _remember = false;
  int _buttonState = 0;
  bool isLoading = false;
  User currentUser;
  String resetEmail;
  final resetEmailFocus = FocusNode();
  bool resetFormLoading = false;
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    Firebase.initializeApp().whenComplete(() {
      this.firebaseAuth = FirebaseAuth.instance;
      isSignedIn();
    });
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    //final Size screenSize = MediaQuery.of(context).size;

    return isLoading
        ? Loader()
        : Scaffold(body: LayoutBuilder(builder:
            (BuildContext context, BoxConstraints viewportConstraints) {
            return SingleChildScrollView(
                child: ConstrainedBox(
                    constraints: BoxConstraints(
                        minHeight: viewportConstraints.maxHeight),
                    child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage("assets/images/login_bg.png"),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Container(
                            margin: EdgeInsets.only(left: 30.0, right: 30.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Container(
                                  margin:
                                      EdgeInsets.only(top: 45.0, bottom: 20.0),
                                  child: Image.asset(
                                    'assets/images/logo_login.png',
                                    height: 130,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                Container(
                                    margin: EdgeInsets.only(bottom: 30.0),
                                    child: Text(
                                      "WORLD'S PROPERTIES",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14.0,
                                      ),
                                    )),
                                Container(
                                  margin: EdgeInsets.only(bottom: 25.0),
                                  child: TextField(
                                    cursorColor: Colors.white,
                                    focusNode: emailFocus,
                                    keyboardType: TextInputType.emailAddress,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18.0),
                                    decoration: InputDecoration(
                                        labelText: "Email Address",
                                        labelStyle: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w300),
                                        enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.white)),
                                        focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.white))),
                                    onChanged: (String value) {
                                      this._email = value.trim();
                                    },
                                  ),
                                ),
                                TextField(
                                    cursorColor: Colors.white,
                                    focusNode: passwordFocus,
                                    obscureText: true,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18.0),
                                    decoration: InputDecoration(
                                        labelText: "Password",
                                        labelStyle: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w300),
                                        enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.white)),
                                        focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.white))),
                                    onChanged: (String value) {
                                      this._password = value;
                                    }),
                                Container(
                                    margin:
                                        EdgeInsets.only(top: 15, bottom: 15),
                                    child: GestureDetector(
                                      onTap: () => {passwordReset()},
                                      child: Container(
                                        margin: EdgeInsets.only(
                                            top: 15.0, bottom: 15.0),
                                        child: Text(
                                          "Forgot Password?",
                                          textAlign: TextAlign.end,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    )),
                                Container(
                                    child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      minimumSize: Size.fromHeight(55),
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(0))),
                                  child: setUpButtonChild(),
                                  onPressed: () {
                                    _login();
                                  },
                                )),
                                Container(
                                  margin:
                                      EdgeInsets.only(top: 32.0, bottom: 32.0),
                                  child: Text(
                                    'OR',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.white54, fontSize: 18.0),
                                  ),
                                ),
                                Container(
                                    child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: ColoredBox(
                                          color:
                                              Color.fromRGBO(255, 255, 255, 0),
                                          child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                  onTap: () => loginFacebook(),
                                                  child: ColoredBox(
                                                      color: Color.fromRGBO(
                                                          255, 255, 255, 0.07),
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                            border: Border.all(
                                                                color: Colors
                                                                    .white)),
                                                        child: Container(
                                                            margin:
                                                                EdgeInsets.only(
                                                                    top: 12.0,
                                                                    bottom:
                                                                        12.0),
                                                            child: Icon(
                                                              FontAwesomeIcons
                                                                  .facebookF,
                                                              color:
                                                                  Colors.white,
                                                            )),
                                                      ))))),
                                    ),
                                    Container(
                                        margin:
                                            EdgeInsets.only(left: 6, right: 6)),
                                    Expanded(
                                      child: ColoredBox(
                                          color:
                                              Color.fromRGBO(255, 255, 255, 0),
                                          child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                  onTap: () => loginGoogle(),
                                                  child: ColoredBox(
                                                      color: Color.fromRGBO(
                                                          255, 255, 255, 0.07),
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                            border: Border.all(
                                                                color: Colors
                                                                    .white)),
                                                        child: Container(
                                                            margin:
                                                                EdgeInsets.only(
                                                                    top: 12.0,
                                                                    bottom:
                                                                        12.0),
                                                            child: Icon(
                                                              FontAwesomeIcons
                                                                  .google,
                                                              color:
                                                                  Colors.white,
                                                            )),
                                                      ))))),
                                    ),
                                  ],
                                )),
                                Container(
                                  margin: EdgeInsets.only(top: 30, bottom: 30),
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        Text('Don\'t have an account? ',
                                            style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.white70)),
                                        GestureDetector(
                                            onTap: () => {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            Signup()),
                                                  )
                                                },
                                            child: Text(
                                              'SIGN UP',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                  color: Colors.white),
                                            )),
                                      ]),
                                ),
                              ],
                            )))));
          }));
  }

  Color rememberColor() {
    return this._remember ? Colors.white : Colors.white30;
  }

  Widget setUpButtonChild() {
    if (_buttonState == 0) {
      return Text(
        'LOG IN',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black,
          fontSize: 16.0,
        ),
      );
    } else if (_buttonState == 1) {
      return SizedBox(
          height: 18.0,
          width: 18.0,
          child: CircularProgressIndicator(
            strokeWidth: 1,
            valueColor:
                AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ));
    }
    return Container();
  }

  void isSignedIn() async {
    this.setState(() {
      isLoading = true;
    });

    prefs = await SharedPreferences.getInstance();
    var firebaseUser = firebaseAuth.currentUser;

    if (firebaseUser != null) {
      if (firebaseUser.emailVerified) {
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .get();
        Map<String, dynamic> userData = userDoc.data();
        if (userData != null) {
          updateCfmToken(userDoc);
          // Write data to local
          await prefs.setString('userId', userData['id']);
          await prefs.setString('firstName', userData['firstName']);
          await prefs.setString('lastName', userData['lastName']);
          await prefs.setString('email', userData['email']);
          await prefs.setString('loginType', userData['loginType']);
          await prefs.setString('photoUrl', userData['photoUrl'] ?? '');
          await prefs.setBool(
              'emailNotifications', userData['emailNotifications'] ?? true);
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => Home()),
              (Route<dynamic> route) => false);
        } else {
          this.setState(() {
            isLoading = false;
          });
        }
      } else {
        this.setState(() {
          isLoading = false;
        });
      }
    } else {
      this.setState(() {
        isLoading = false;
      });
    }
  }

  _login() async {
    if (_email.isNotEmpty &&
        EmailValidator.validate(_email) &&
        _password.isNotEmpty) {
      if (_buttonState == 0) {
        setState(() {
          _buttonState = 1;
        });
        UserCredential credential = await firebaseAuth
            .signInWithEmailAndPassword(email: _email, password: _password)
            .catchError((error) {
          Fluttertoast.showToast(
            msg: "Invalid email and/or password.",
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
          setState(() {
            _buttonState = 0;
          });
        });

        if (credential != null) {
          User firebaseUser = credential.user;
          print(firebaseUser.email);
          if (firebaseUser.emailVerified) {
            final DocumentSnapshot userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(firebaseUser.uid)
                .get();
            Map<String, dynamic> userData = userDoc.data();
            if (userData != null) {
              updateCfmToken(userDoc);
              Map<String, dynamic> userData = userDoc.data();
              // Write data to local
              await prefs.setString('userId', userData['id']);
              await prefs.setString('firstName', userData['firstName']);
              await prefs.setString('lastName', userData['lastName']);
              await prefs.setString('email', userData['email']);
              await prefs.setString('loginType', userData['loginType']);
              if (userData['photoUrl'] != null) {
                await prefs.setString('photoUrl', userData['photoUrl']);
              }
              if (userData['emailNotifications'] != null) {
                await prefs.setBool(
                    'emailNotifications', userData['emailNotifications']);
              }
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => Home()),
                  (Route<dynamic> route) => false);
            }
          } else {
            setState(() {
              _buttonState = 0;
            });
            Fluttertoast.showToast(
              msg: "Please verify your email first.",
              backgroundColor: Colors.red,
              timeInSecForIosWeb: 2,
              textColor: Colors.white,
            );
          }
        }
      }
    } else {
      setState(() {
        _buttonState = 0;
      });
      if (_email.isEmpty || !EmailValidator.validate(_email)) {
        FocusScope.of(context).requestFocus(emailFocus);
      } else if (_password.isEmpty) {
        FocusScope.of(context).requestFocus(passwordFocus);
      }
    }
  }

  loginFacebook() async {
    final LoginResult result = await FacebookAuth.instance.login();
    if (result.status == LoginStatus.success) {
      final OAuthCredential credential =
          FacebookAuthProvider.credential(result.accessToken.token);
      // Once signed in, return the UserCredential
      return await FirebaseAuth.instance.signInWithCredential(credential);
    }
    // final facebookLogin = FacebookLogin();
    // final result = await facebookLogin.logIn(['email']);
    // this.setState(() {
    //   isLoading = true;
    // });
    // if (result.status == FacebookLoginStatus.loggedIn) {
    //   var graphResponse = await http.get(Uri.parse(
    //       'https://graph.facebook.com/v2.12/me?fields=first_name,last_name,email,picture&access_token=${result.accessToken.token}'));
    //   var profile = json.decode(graphResponse.body);
    //   var photoUrl = profile['picture']['data']['url'];

    //   final FacebookAuthCredential credential =
    //       FacebookAuthProvider.credential(result.accessToken.token);

    //   User firebaseUser =
    //       (await firebaseAuth.signInWithCredential(credential)).user;
    //   if (firebaseUser != null) {
    //     // Check if already signed up

    //     final DocumentSnapshot userDoc = await FirebaseFirestore.instance
    //         .collection('users')
    //         .doc(firebaseUser.uid)
    //         .get();
    //     Map<String, dynamic> userData = userDoc.data();
    //     if (userData == null) {
    //       // Insert data to server if new user

    //       await FirebaseFirestore.instance
    //           .collection('users')
    //           .doc(firebaseUser.uid)
    //           .set({
    //         'id': firebaseUser.uid,
    //         'firstName': profile['first_name'],
    //         'lastName': profile['last_name'],
    //         'email': profile['email'],
    //         'loginType': 'facebook',
    //         'photoUrl': photoUrl
    //       });
    //       currentUser = firebaseUser;
    //       final DocumentSnapshot userDoc = await FirebaseFirestore.instance
    //           .collection('users')
    //           .doc(firebaseUser.uid)
    //           .get();
    //       updateCfmToken(userDoc);
    //       await prefs.setString('userId', currentUser.uid);
    //       await prefs.setString('firstName', profile['first_name']);
    //       await prefs.setString('lastName', profile['last_name']);
    //       await prefs.setString('email', profile['email']);
    //       await prefs.setString('loginType', profile['loginType']);
    //       await prefs.setString('photoUrl', currentUser.photoURL);
    //     } else {
    //       updateCfmToken(userDoc);
    //       Map<String, dynamic> userData = userDoc.data();
    //       // Write data to local
    //       await prefs.setString('userId', userData['id']);
    //       await prefs.setString('firstName', userData['firstName']);
    //       await prefs.setString('lastName', userData['lastName']);
    //       await prefs.setString('email', userData['email']);
    //       await prefs.setString('loginType', userData['loginType']);
    //       await prefs.setString('photoUrl', userData['photoUrl']);
    //       await prefs.setBool(
    //           'emailNotifications', userData['emailNotifications']);
    //     }
    //     Navigator.of(context).pushAndRemoveUntil(
    //         MaterialPageRoute(builder: (context) => Home()),
    //         (Route<dynamic> route) => false);
    //   } else {
    //     this.setState(() {
    //       isLoading = false;
    //     });
    //   }
    // } else {
    //   this.setState(() {
    //     isLoading = false;
    //   });
    // }
  }

  loginGoogle() async {
    GoogleSignInAccount googleUser = await googleSignIn.signIn();
    if (googleUser != null) {
      GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      this.setState(() {
        isLoading = true;
      });
      Map<String, dynamic> profile = parseJwt(googleAuth.idToken);

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      User firebaseUser =
          (await firebaseAuth.signInWithCredential(credential)).user;

      if (firebaseUser != null) {
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .get();
        Map<String, dynamic> userData = userDoc.data();
        print(userData);
        if (userData == null) {
          // Insert data to server if new user
          await FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseUser.uid)
              .set({
            'id': firebaseUser.uid,
            'firstName': profile['given_name'],
            'lastName': profile['family_name'],
            'email': profile['email'],
            'loginType': 'google',
            'photoUrl': firebaseUser.photoURL
          });
          currentUser = firebaseUser;
          final DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseUser.uid)
              .get();
          updateCfmToken(userDoc);
          await prefs.setString('userId', currentUser.uid);
          await prefs.setString('firstName', profile['first_name']);
          await prefs.setString('lastName', profile['last_name']);
          await prefs.setString('email', profile['email']);
          await prefs.setString('loginType', profile['loginType']);
          await prefs.setString('photoUrl', currentUser.photoURL);
        } else {
          updateCfmToken(userDoc);
          Map<String, dynamic> userData = userDoc.data();
          // Write data to local
          await prefs.setString('userId', userData['id']);
          await prefs.setString('firstName', userData['firstName']);
          await prefs.setString('lastName', userData['lastName']);
          await prefs.setString('email', userData['email']);
          await prefs.setString('loginType', userData['loginType']);
          if (userData['photoUrl'] != null) {
            await prefs.setString('photoUrl', userData['photoUrl']);
          }
          if (userData['emailNotifications'] != null) {
            await prefs.setBool(
                'emailNotifications', userData['emailNotifications']);
          }
        }
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => Home()),
            (Route<dynamic> route) => false);
      } else {
        this.setState(() {
          isLoading = false;
        });
      }
      // Check if already signed up
    }
  }

  updateCfmToken(DocumentSnapshot userDoc) async {
    String deviceToken = await firebaseMessaging.getToken();
    print(deviceToken);
    // Fluttertoast.showToast(
    //     msg: 'updateCfmToken: ' + deviceToken,
    //     backgroundColor: Colors.red,
    //     textColor: Colors.white,
    //     timeInSecForIosWeb: 2,
    //     gravity: ToastGravity.BOTTOM);
    userDoc.reference.update({'deviceToken': deviceToken, 'isOnline': true});
  }

  static Map<String, dynamic> parseJwt(String token) {
    // validate token
    if (token == null) return null;
    final List<String> parts = token.split('.');
    if (parts.length != 3) {
      return null;
    }
    // retrieve token payload
    final String payload = parts[1];
    final String normalized = base64Url.normalize(payload);
    final String resp = utf8.decode(base64Url.decode(normalized));
    // convert to Map
    final payloadMap = json.decode(resp);
    if (payloadMap is! Map<String, dynamic>) {
      return null;
    }
    return payloadMap;
  }

  passwordReset() {
    resetEmail = '';
    setState(() {
      resetFormLoading = false;
    });
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext dialogContext) => StatefulBuilder(
                builder: (BuildContext context, StateSetter setModalState) {
              return SimpleDialog(
                title: Text(
                  'Forgot Password',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                titlePadding: EdgeInsets.only(top: 20.0),
                contentPadding: EdgeInsets.only(
                    top: 15.0, right: 15.0, bottom: 15.0, left: 15.0),
                children: [
                  Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                              autofocus: true,
                              focusNode: resetEmailFocus,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 18.0),
                              decoration: InputDecoration(
                                  labelStyle:
                                      TextStyle(fontWeight: FontWeight.w300),
                                  labelText: 'Email'),
                              onChanged: (String value) {
                                resetEmail = value.trim();
                              }),
                          Padding(
                            padding: EdgeInsets.only(top: 15.0),
                            child: Material(
                                color: Theme.of(context).primaryColor,
                                child: InkWell(
                                    onTap: () => {
                                          submitPasswordReset(
                                              dialogContext, setModalState)
                                        },
                                    child: Container(
                                        margin: EdgeInsets.only(
                                            top: 17.0, bottom: 17.0),
                                        child: Text('RESET PASSWORD',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white))))),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 5.0),
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
                                                  fontWeight: FontWeight.w600,
                                                  color: Theme.of(context)
                                                      .primaryColor))),
                                    ))),
                          )
                        ],
                      ),
                      resetFormLoading
                          ? Positioned.fill(
                              child: Center(
                              child: Container(
                                color: Colors.white,
                                child: Center(
                                  child: SizedBox(
                                      height: 30.0,
                                      width: 30.0,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Theme.of(context).primaryColor),
                                      )),
                                ),
                              ),
                            ))
                          : Container(
                              height: 0.0,
                            )
                    ],
                  )
                ],
              );
            }));
  }

  submitPasswordReset(
      BuildContext dialogContext, StateSetter setModalState) async {
    if (resetEmail.isNotEmpty && EmailValidator.validate(resetEmail)) {
      setState(() {
        resetFormLoading = true;
      });
      setModalState(() {
        resetFormLoading = true;
      });
      bool error = false;
      await firebaseAuth
          .sendPasswordResetEmail(email: resetEmail)
          .catchError((e) => {error = true});

      if (error == false) {
        Navigator.pop(dialogContext);
        Fluttertoast.showToast(
          msg: "A password reset link has been sent to your email.",
          backgroundColor: Colors.white,
          textColor: Theme.of(context).primaryColor,
        );
      } else {
        setState(() {
          resetFormLoading = false;
        });
        setModalState(() {
          resetFormLoading = false;
        });
        Fluttertoast.showToast(
          msg: "Email does not exists in our records.",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } else {
      Fluttertoast.showToast(
        msg: "Please enter a valid email addresss.",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      resetEmailFocus.requestFocus();
    }
  }
}
