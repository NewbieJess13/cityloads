import 'package:CityLoads/screens/countries.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import './screens/login.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  print('Handling a background message ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // SharedPreferences.setMockInitialValues({});

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Map<int, Color> color = {
      50: Color.fromRGBO(62, 72, 100, .1),
      100: Color.fromRGBO(62, 72, 100, .2),
      200: Color.fromRGBO(62, 72, 100, .3),
      300: Color.fromRGBO(62, 72, 100, .4),
      400: Color.fromRGBO(62, 72, 100, .5),
      500: Color.fromRGBO(62, 72, 100, .6),
      600: Color.fromRGBO(62, 72, 100, .7),
      700: Color.fromRGBO(62, 72, 100, .8),
      800: Color.fromRGBO(62, 72, 100, .9),
      900: Color.fromRGBO(62, 72, 100, 1),
    };
    MaterialColor primaryColor = MaterialColor(0xFF3E4864, color);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'City Loads',
      theme: ThemeData(
        primarySwatch: primaryColor,
        buttonColor: primaryColor,
        toggleableActiveColor: primaryColor,
        fontFamily: 'TexGyreAdventor',
        inputDecorationTheme: InputDecorationTheme(
          alignLabelWithHint: true,
          focusedBorder: const UnderlineInputBorder(
            borderSide: const BorderSide(
              color: Colors.black,
              width: 1,
            ),
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: const BorderSide(
              color: Colors.grey,
              width: 0.0,
            ),
          ),
        ),
        unselectedWidgetColor: Colors.black38,
      ),
      home: Login(),
      // home: Countries(),
    );
  }
}
