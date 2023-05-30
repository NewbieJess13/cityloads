import 'dart:io';

import 'package:CityLoads/screens/cities.dart';
import 'package:CityLoads/screens/countries.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ionicons/ionicons.dart';
import './feed.dart';
import './profile.dart';
import './news.dart';
import './create_post.dart';
import './conversations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conversation.dart';
import '../models/post.dart' as PostModel;
import './messages.dart';
import './post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Home extends StatefulWidget {
  final String? city;
  final String? isoCode;
  final List<Map<String, dynamic>>? cities;
  final int selection;
  final String? countryName;

  const Home(
      {Key? key,
      this.city,
      this.isoCode,
      this.selection = 0,
      this.cities,
      this.countryName})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  DarwinNotificationDetails? iOSPlatformChannelSpecifics;
  NotificationDetails? platformChannelSpecifics;
  late InitializationSettings initializationSettings;
  DarwinInitializationSettings? initializationSettingsIOS;
  AndroidNotificationDetails? androidPlatformChannelSpecifics;
  AndroidInitializationSettings? initializationSettingsAndroid;
  int _selectedIndex = 0;
  late SharedPreferences prefs;
  String? userId;
  String? currentScreen;
  GlobalKey<FeedState> globalKey = GlobalKey();

  int _selection = 0;

  @override
  initState() {
    getPreferences();
    initNotif();
    setupInteractedMessage();
    super.initState();
  }

  initNotif() async {
    await Permission.notification.request();
    iOSPlatformChannelSpecifics = DarwinNotificationDetails();
    initializationSettingsIOS = DarwinInitializationSettings();
    androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'testid', 'testtitle',
        channelDescription: 'testdesc',
        importance: Importance.max,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(''));
    initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
    platformChannelSpecifics = NotificationDetails(
        iOS: iOSPlatformChannelSpecifics,
        android: androidPlatformChannelSpecifics);
    initializationSettings = InitializationSettings(
      iOS: initializationSettingsIOS,
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      // onDidReceiveNotificationResponse: onSelectNotification,
    );
    notificationsListener();
  }

  // It is assumed that all messages contain a data field with the key 'type'
  Future<void> setupInteractedMessage() async {
    // Get any messages which caused the application to open from
    // a terminated state.
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    // If the message also contains a data property with a "type" of "chat",
    // navigate to a chat screen
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Also handle any interaction when the app is in the background via a
    // Stream listener
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    print(message.data);
    if (message.data != null) {
      switch (message.data['type']) {
        case 'new_message':
          goToMessages(message.data['data']['conversation']);
          break;
        case 'post_comment':
          goToPost(message.data['data']['post']);
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: content(),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.black12))),
          child: BottomNavigationBar(
            elevation: 0.0,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            unselectedItemColor: Colors.black45,
            selectedIconTheme: IconThemeData(
                size: 24.0, color: Theme.of(context).primaryColor),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: SvgPicture.asset('assets/icons/home_outlined.svg'),
                label: '',
                activeIcon: SvgPicture.asset('assets/icons/home_filled.svg'),
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset('assets/icons/news_outline.svg'),
                label: '',
                activeIcon: SvgPicture.asset('assets/icons/news_filled.svg'),
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Ionicons.add_circle_sharp,
                  size: 40.0,
                  color: Theme.of(context).primaryColor,
                ),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset('assets/icons/message_outlined.svg'),
                label: '',
                activeIcon: SvgPicture.asset('assets/icons/message_filled.svg'),
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset('assets/icons/profile_outlined.svg'),
                label: '',
                activeIcon: SvgPicture.asset('assets/icons/profile_filled.svg'),
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.amber[800],
            onTap: (index) => {
              if (index == 2)
                {newPostDialog()}
              else
                {
                  setState(() => {_selectedIndex = index})
                }
            },
          ),
        ));
  }

  Widget content() {
    Widget content = Container();
    switch (_selectedIndex) {
      case 0:
        // content = Countries();
        if (widget.selection == 0) {
          content = Countries();
        } else if (widget.selection == 1) {
          content = Cities(
            cities: widget.cities!,
            countryCode: widget.isoCode,
            countryName: widget.countryName,
          );
        } else if (widget.selection == 2) {
          content =
              Feed(city: widget.city, isoCode: widget.isoCode, key: globalKey);
        }
        break;
      case 1:
        content = News();
        break;
      case 3:
        content = Conversations();
        break;
      case 4:
        content = Profile();
        break;
    }

    return content;
  }

  getPreferences() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });

    firebaseMessaging.onTokenRefresh.listen((String deviceToken) async {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc != null) {
        userDoc.reference.update({'deviceToken': deviceToken});
      }
    });
  }

  newPostDialog() async {
    bool? goToFeed = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => CreatePost(), fullscreenDialog: true),
    );

    if (goToFeed == true) {
      globalKey.currentState!.getPosts();
    }
  }

  notificationsListener() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        notify(message.notification!.toMap());
      }
    });
  }

  notify(Map<String, dynamic> message) async {
    // print(message);
    if (Platform.isIOS) {
      final bool result = (await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ))!;
      if (result) {
        var notification = message['notification'];
        if (notification == null && message['aps'] != null) {
          notification = message['aps']['alert'];
        }
        bool showNotification = true;
        String? currentScreen = prefs.getString('currentScreen');
        if (message['type'] == 'new_message') {
          var conversation = jsonDecode(message["conversation"]);
          if (currentScreen == 'messages-${conversation["id"]}') {
            showNotification = false;
          }
        } else if (message['type'] == 'post_comment') {
          var post = jsonDecode(message["post"]);
          if (currentScreen == 'post-${post["id"]}') {
            showNotification = false;
          }
        }

        if (showNotification) {
          await flutterLocalNotificationsPlugin.show(0, notification['title'],
              notification['body'], platformChannelSpecifics,
              payload: jsonEncode(message));
        }
      }
    } else if (Platform.isAndroid) {
      var notification = message['notification'];
      if (notification == null && message['aps'] != null) {
        notification = message['aps']['alert'];
      }
      bool showNotification = true;
      String? currentScreen = prefs.getString('currentScreen');
      if (message['type'] == 'new_message') {
        var conversation = jsonDecode(message["conversation"]);
        if (currentScreen == 'messages-${conversation["id"]}') {
          showNotification = false;
        }
      } else if (message['type'] == 'post_comment') {
        var post = jsonDecode(message["post"]);
        if (currentScreen == 'post-${post["id"]}') {
          showNotification = false;
        }
      }

      if (showNotification) {
        await flutterLocalNotificationsPlugin.show(
            0, message['title'], message['body'], platformChannelSpecifics,
            payload: jsonEncode(message));
      }
    }
  }

  Future onSelectNotification(NotificationResponse response) async {
    if (response.payload != null) {
      var notification = jsonDecode(response.payload!);
      print(notification);
      if (Platform.isAndroid) {
        notification = notification['data'];
      }
      switch (notification['type']) {
        case 'new_message':
          goToMessages(notification['conversation']);
          break;
        case 'post_comment':
          goToPost(notification['post']);
          break;
      }
    }
  }

  goToPost(String postData) {
    String? currentScreen = prefs.getString('currentScreen');
    PostModel.Post post = PostModel.Post.fromJson(jsonDecode(postData));
    if (currentScreen != 'post-${post.id}') {
      post.scrollToComments = true;
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => Post(
                  post: post,
                )),
      );
    }
  }

  goToMessages(String conversationData) {
    String? currentScreen = prefs.getString('currentScreen');
    Conversation conversation =
        Conversation.fromJson(jsonDecode(conversationData));
    if (currentScreen != 'messages-${conversation.id}') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => Messages(
                  conversation: conversation,
                )),
      );
    }
  }
}
