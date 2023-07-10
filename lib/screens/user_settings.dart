import 'package:CityLoads/helpers/conn_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/svg.dart';
import '../models/user.dart' as UserModel;
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import './loader.dart';
import './payment.dart';
import './about.dart';
import './terms.dart';
import 'dart:io';

class UserSettings extends StatefulWidget {
  final UserModel.User? user;
  const UserSettings({Key? key, this.user}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _UserSettingsState();
}

class _UserSettingsState extends State<UserSettings> {
  FirebaseAuth? firebaseAuth;
  bool isLoading = true;
  String? currentUserId;
  UserModel.User? user;
  late SharedPreferences prefs;

  final firstnameFocus = FocusNode();
  final lastnameFocus = FocusNode();
  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();
  String? firstname = "";
  String? lastname = "";
  String? email = "";
  String password = "";

  TextEditingController firstnameController = TextEditingController();
  TextEditingController lastnameController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  Map<String, dynamic>? creditCard;
  final picker = ImagePicker();
  File? newProfilePicture;

  @override
  initState() {
    super.initState();
    user = widget.user;
    firstname = user!.firstName;
    lastname = user!.lastName;
    email = user!.email;
    firstnameController.text = user!.firstName!;
    lastnameController.text = user!.lastName!;
    emailController.text = user!.email!;
    getPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            elevation: 0.0,
            leading: Builder(
              builder: (BuildContext context) {
                return IconButton(
                    splashRadius: 20.0,
                    icon: SvgPicture.asset('assets/icons/back_arrow.svg'),
                    onPressed: () => Navigator.of(context).pop());
              },
            ),
            centerTitle: true,
            title: Text('SETTINGS',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 22.0)),
          ),
          body: LayoutBuilder(builder:
              (BuildContext context, BoxConstraints viewportConstraints) {
            return SingleChildScrollView(
                child: ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: viewportConstraints.maxHeight),
              child: Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    profilePicture(),
                    Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Profile',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontSize: 22.0)),
                          Container(
                              margin: EdgeInsets.only(top: 10.0),
                              child: TextField(
                                  controller: firstnameController,
                                  focusNode: firstnameFocus,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18.0),
                                  decoration: InputDecoration(
                                      labelStyle: TextStyle(
                                          fontWeight: FontWeight.w300),
                                      labelText: 'First Name'),
                                  onChanged: (String value) {
                                    this.firstname = value.trim();
                                  })),
                          Container(
                              margin: EdgeInsets.only(top: 15.0),
                              child: TextField(
                                  controller: lastnameController,
                                  focusNode: lastnameFocus,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18.0),
                                  decoration: InputDecoration(
                                      labelStyle: TextStyle(
                                          fontWeight: FontWeight.w300),
                                      labelText: 'Last Name'),
                                  onChanged: (String value) {
                                    this.lastname = value.trim();
                                  })),
                          Container(
                              margin: EdgeInsets.only(top: 15.0),
                              child: TextField(
                                  controller: emailController,
                                  focusNode: emailFocus,
                                  keyboardType: TextInputType.emailAddress,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18.0),
                                  decoration: InputDecoration(
                                      labelStyle: TextStyle(
                                          fontWeight: FontWeight.w300),
                                      labelText: 'Email'),
                                  onChanged: (String value) {
                                    this.email = value.trim();
                                  })),
                          Container(
                              margin: EdgeInsets.only(top: 15.0, bottom: 20.0),
                              child: TextField(
                                  focusNode: passwordFocus,
                                  obscureText: true,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18.0),
                                  decoration: InputDecoration(
                                      hintText: '***************',
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.always,
                                      labelStyle: TextStyle(
                                          fontWeight: FontWeight.w300),
                                      labelText: 'Password'),
                                  onChanged: (String value) {
                                    password = value.trim();
                                  })),
                          Material(
                              color: Theme.of(context).primaryColor,
                              child: InkWell(
                                  onTap: () => {updateProfile()},
                                  child: Container(
                                      margin: EdgeInsets.only(
                                          top: 17.0, bottom: 17.0),
                                      child: Text('UPDATE PROFILE',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white))))),
                        ],
                      ),
                    ),
                    Divider(
                      color: Colors.black45,
                    ),
                    // Padding(
                    //   padding: EdgeInsets.all(20.0),
                    //   child: Column(
                    //     crossAxisAlignment: CrossAxisAlignment.stretch,
                    //     children: [
                    //       Text('Payment',
                    //           style: TextStyle(
                    //               fontWeight: FontWeight.bold,
                    //               color: Colors.black,
                    //               fontSize: 22.0)),
                    //       creditCard == null
                    //           ? Container()
                    //           : Column(
                    //               crossAxisAlignment: CrossAxisAlignment.start,
                    //               children: [
                    //                 Padding(
                    //                   padding: EdgeInsets.only(top: 15.0),
                    //                   child: Text(
                    //                     'Saved payment',
                    //                     style: TextStyle(
                    //                         color:
                    //                             Theme.of(context).primaryColor,
                    //                         fontSize: 15.0,
                    //                         fontWeight: FontWeight.w500),
                    //                   ),
                    //                 ),
                    //                 Container(
                    //                   padding: EdgeInsets.only(top: 10.0),
                    //                   child: InkWell(
                    //                     onTap: () => {openPayment()},
                    //                     child: Row(
                    //                       mainAxisAlignment:
                    //                           MainAxisAlignment.spaceBetween,
                    //                       children: [
                    //                         Expanded(
                    //                           child: Text(
                    //                             '************' +
                    //                                 creditCard['cardNumber']
                    //                                     .substring(creditCard[
                    //                                                 'cardNumber']
                    //                                             .length -
                    //                                         4),
                    //                             style: TextStyle(
                    //                                 fontSize: 22.0,
                    //                                 fontWeight:
                    //                                     FontWeight.w700),
                    //                           ),
                    //                         ),
                    //                         cardIcon(creditCard['cardType'])
                    //                       ],
                    //                     ),
                    //                   ),
                    //                 )
                    //               ],
                    //             )
                    //     ],
                    //   ),
                    // ),
                    // Divider(
                    //   color: Colors.black45,
                    // ),
                    Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Alerts',
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w500)),
                          Padding(
                            padding: EdgeInsets.only(top: 7.0, bottom: 30.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Email Notifications',
                                    style: TextStyle(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.w800),
                                  ),
                                ),
                                SizedBox(
                                  height: 20.0,
                                  child: Switch(
                                    value: user!.emailNotifications == null
                                        ? false
                                        : user!.emailNotifications!,
                                    onChanged: (newValue) =>
                                        {updateEmailNotifications(newValue)},
                                  ),
                                )
                              ],
                            ),
                          ),
                          Text('Info',
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w500)),
                          Padding(
                            padding: EdgeInsets.only(top: 7.0, bottom: 30.0),
                            child: InkWell(
                              onTap: () {
                                String? about = '';
                                DbFirestore().getAboutTerms().then((_about) {
                                  setState(() {
                                    about = _about.data()!['about'];
                                  });
                                  openAbout(about);
                                });
                              },
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'About Us',
                                      style: TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  Icon(
                                    FontAwesomeIcons.chevronRight,
                                    size: 20.0,
                                    color: Colors.black38,
                                  )
                                ],
                              ),
                            ),
                          ),
                          Text('Legal',
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w500)),
                          Padding(
                            padding: EdgeInsets.only(top: 7.0, bottom: 30.0),
                            child: InkWell(
                              onTap: () {
                                String? terms = '';
                                DbFirestore().getPrivacyPolicy().then((_about) {
                                  setState(() {
                                    terms = _about.data()!['terms'];
                                  });
                                  openTerms(terms);
                                });
                              },
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Terms of Service',
                                      style: TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  Icon(
                                    FontAwesomeIcons.chevronRight,
                                    size: 20.0,
                                    color: Colors.black38,
                                  )
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ));
          }),
        ),
        isLoading
            ? Loader(
                text: 'Saving account..',
              )
            : Container(
                height: 0.0,
              )
      ],
    );
  }

  getPreferences() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId = prefs.getString('userId');
      if (currentUserId != user!.id) Navigator.of(context).pop();
      isLoading = false;
    });
    getCreditCard();
  }

  Widget profilePicture() {
    List<Color> _colors = [Colors.black, Colors.transparent];
    List<double> _stops = [0.0, 0.5];
    Widget userAvatar = newProfilePicture != null
        ? CircleAvatar(
            radius: 60.0, backgroundImage: FileImage(newProfilePicture!))
        : (user!.photoUrl != null)
            ? CircleAvatar(
                radius: 60.0,
                backgroundImage: CachedNetworkImageProvider(user!.photoUrl!),
              )
            : CircleAvatar(
                radius: 60.0,
                backgroundImage: AssetImage('assets/images/logo.png'),
              );

    return Padding(
      padding: EdgeInsets.only(top: 15.0),
      child: CircleAvatar(
        radius: 61,
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.3),
        child: GestureDetector(
          onTap: () => {pickImage()},
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              userAvatar,
              Container(
                width: 120,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: _colors,
                      stops: _stops,
                    ),
                    borderRadius: BorderRadius.circular(60.0)),
              ),
              Container(
                width: 100,
                padding: EdgeInsets.only(bottom: 10.0),
                child: Text(
                  'Edit',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 15.0),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  pickImage() async {
    PermissionStatus permissionStatus;
    if (Platform.isAndroid) {
      permissionStatus = await Permission.storage.request();
    } else {
      permissionStatus = await Permission.photos.request();
    }
    if (permissionStatus.isPermanentlyDenied) {
      showAllowGalleryDialog();
      return;
    }

    XFile? pickedImage = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
    if (pickedImage != null) {
      File image = File(pickedImage.path);
      setState(() {
        newProfilePicture = image;
      });
    }
  }

  showAllowGalleryDialog() {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext dialogContext) => StatefulBuilder(
                builder: (BuildContext context, StateSetter setModalState) {
              return SimpleDialog(
                titlePadding: EdgeInsets.only(top: 20.0),
                contentPadding: EdgeInsets.only(
                    top: 15.0, right: 15.0, bottom: 15.0, left: 15.0),
                children: [
                  Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                              'Please allow CityLoads to access your media library from your settings.',
                              style: TextStyle(fontSize: 16.0, height: 1.35)),
                          Padding(
                            padding: EdgeInsets.only(top: 15.0),
                            child: Material(
                                child: InkWell(
                                    onTap: () =>
                                        {AppSettings.openAppSettings()},
                                    child: Container(
                                      decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.black12)),
                                      child: Container(
                                          margin: EdgeInsets.only(
                                              top: 17.0, bottom: 17.0),
                                          child: Text('OPEN SETTINGS',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Theme.of(context)
                                                      .primaryColor))),
                                    ))),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 5.0),
                            child: Material(
                                child: InkWell(
                                    onTap: () => {Navigator.of(context).pop()},
                                    child: Container(
                                      decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.black12)),
                                      child: Container(
                                          margin: EdgeInsets.only(
                                              top: 17.0, bottom: 17.0),
                                          child: Text('CLOSE',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Theme.of(context)
                                                      .primaryColor))),
                                    ))),
                          )
                        ],
                      ),
                    ],
                  )
                ],
              );
            }));
  }

  openAbout(about) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => About(about: about)),
    );
  }

  openTerms(terms) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => Terms(
                terms: terms,
              )),
    );
  }

  updateEmailNotifications(bool state) async {
    setState(() => {user!.emailNotifications = state});

    await prefs.setBool('emailNotifications', state);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.id)
        .update({'emailNotifications': state});
  }

  updateProfile() async {
    if (firstname!.isEmpty || lastname!.isEmpty || email!.isEmpty) {
      if (firstname!.isEmpty) {
        firstnameFocus.requestFocus();
      } else if (lastname!.isEmpty) {
        lastnameFocus.requestFocus();
      } else if (email!.isEmpty) {
        emailFocus.requestFocus();
      }
    } else {
      setState(() {
        isLoading = true;
      });
      if (firebaseAuth == null) {
        await Firebase.initializeApp();
        firebaseAuth = FirebaseAuth.instance;
      }

      String error = '';
      await firebaseAuth!.currentUser!
          .updateEmail(email!)
          .catchError((err) => {error = err.toString()});

      if (error.isEmpty && password.isNotEmpty) {
        await firebaseAuth!.currentUser!
            .updatePassword(password)
            .catchError((err) => {error = err.toString()});
      }

      if (error.isNotEmpty) {
        setState(() {
          isLoading = false;
        });
        return Fluttertoast.showToast(
            msg: error.toString().replaceAll(RegExp(r'\[[^)]*\]'), ''),
            backgroundColor: Colors.red,
            textColor: Colors.white,
            timeInSecForIosWeb: 3);
      }

      await firebaseAuth!.currentUser!
          .updateProfile(displayName: '$firstname $lastname');

      Map<String, String?> data = {
        'firstName': firstname,
        'lastName': lastname,
        'email': email
      };

      if (newProfilePicture != null) {
        String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        String fileName = timestamp +
            '-' +
            UniqueKey().toString().replaceAll('[#', '').replaceAll(']', '');
        Reference reference = FirebaseStorage.instance.ref().child(fileName);
        UploadTask uploadTask = reference.putFile(newProfilePicture!);
        TaskSnapshot storageTaskSnapshot =
            await uploadTask.whenComplete(() => null);
        if (storageTaskSnapshot == null) {
          String imageUrl = await storageTaskSnapshot.ref.getDownloadURL();
          data['photoUrl'] = imageUrl;
          user!.photoUrl = imageUrl;
          await prefs.setString('photoUrl', imageUrl);
        }
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.id)
          .update(data);

      setState(() {
        isLoading = false;
      });

      user!.firstName = firstname;
      user!.lastName = lastname;
      user!.email = email;
      user!.update();

      await prefs.setString('firstName', firstname!);
      await prefs.setString('lastName', lastname!);
      await prefs.setString('email', email!);

      Fluttertoast.showToast(
          msg: 'Account updated successfully.',
          backgroundColor: Theme.of(context).primaryColor,
          textColor: Colors.white,
          timeInSecForIosWeb: 3);
    }
  }

  openPayment() async {
    Map<String, dynamic>? creditCardData = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => Payment(
                creditCard: creditCard,
              ),
          fullscreenDialog: true),
    );
    if (creditCardData != null) {
      setState(() {
        creditCard = creditCardData;
      });

      Fluttertoast.showToast(
          msg: 'Card saved successfully.',
          backgroundColor: Theme.of(context).primaryColor,
          textColor: Colors.white,
          timeInSecForIosWeb: 3);
    }
  }

  getCreditCard() async {
    QuerySnapshot creditCardResult = await FirebaseFirestore.instance
        .collection('creditCards')
        .where('userId', isEqualTo: prefs.getString('userId'))
        .limit(1)
        .get();
    List<QueryDocumentSnapshot> creditCards = creditCardResult.docs;
    if (creditCards.length > 0) {
      setState(() {
        creditCard = creditCards[0].data() as Map<String, dynamic>?;
        creditCard!['id'] = creditCards[0].id;
      });
    }
  }

  Widget cardIcon(String cardType) {
    Widget cardIcon = Container();
    switch (cardType) {
      case 'visa':
        cardIcon = SvgPicture.asset(
          'assets/images/visa.svg',
          height: 15.0,
        );
        break;
      case 'master_card':
        cardIcon = SvgPicture.asset(
          'assets/images/mastercard.svg',
          height: 15.0,
        );
        break;
    }

    return Row(
      children: [
        cardIcon,
        Padding(
          padding: EdgeInsets.only(left: 20.0),
          child: Icon(
            FontAwesomeIcons.chevronRight,
            size: 20.0,
            color: Colors.black38,
          ),
        )
      ],
    );
  }
}
