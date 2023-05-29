import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ionicons/ionicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/conversation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'dart:async';
import '../helpers/notification.dart';
import 'dart:convert';
import 'package:jiffy/jiffy.dart';

class Messages extends StatefulWidget {
  final Conversation conversation;
  const Messages({Key key, this.conversation}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _MessagesState();
}

class _MessagesState extends State<Messages> {
  Conversation conversation;
  bool isLoading = true;
  String userId;
  String userFirstName;
  String userLastName;
  String photoUrl;
  SharedPreferences prefs;
  List messages = [];
  TextEditingController messageController = TextEditingController();
  String newMessage;

  @override
  void initState() {
    super.initState();
    conversation = widget.conversation;
    getPreferences();
    readLastMessage();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    prefs.setString('currentScreen', '');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.0,
        centerTitle: false,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
                splashRadius: 20.0,
                icon: Icon(
                  Ionicons.arrow_back,
                  color: Colors.black,
                  size: 30,
                ),
                onPressed: () => Navigator.of(context).pop());
          },
        ),
        title: Transform(
          transform: Matrix4.translationValues(-25, 0.0, 0.0),
          child: profileHeading(),
        ),
        actions: [
          // IconButton(
          //   onPressed: () => {},
          //   splashRadius: 20.0,
          //   icon: Icon(
          //     Ionicons.ellipsis_horizontal,
          //     color: Colors.black,
          //     size: 30.0,
          //   ),
          // )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => {hideKeyboard()},
              child: Container(
                padding: EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
                child: isLoading
                    ? Center(
                        child: SizedBox(
                            width: 20.0,
                            height: 20.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 1,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.black26),
                            )),
                      )
                    : conversation.id == null || messages.length == 0
                        ? Center(
                            child: Text(
                              'No messages yet',
                              style: TextStyle(
                                  fontSize: 17.0, color: Colors.black54),
                            ),
                          )
                        : ListView.builder(
                            itemCount: messages.length,
                            reverse: true,
                            primary: true,
                            itemBuilder: (BuildContext ctxt, int index) {
                              String nextUserId = '';
                              if (index > 0) {
                                nextUserId =
                                    messages[index - 1].data()['userId'];
                              }
                              return buildItem(
                                  messages[index].data(), nextUserId);
                            }),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.black12))),
            padding: EdgeInsets.only(
                left: 15.0, right: 15.0, top: 10.0, bottom: 15.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: TextField(
                      controller: messageController,
                      maxLines: 3,
                      minLines: 1,
                      style: TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 16.0),
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          hintText: 'Write a message..'),
                      onChanged: (String value) {
                        newMessage = value.trim();
                      }),
                ),
                IconButton(
                  splashRadius: 20.0,
                  icon: SvgPicture.asset('assets/icons/send_outlined.svg'),
                  onPressed: () => {sendMessage()},
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  hideKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Widget buildItem(Map<String, dynamic> message, String nextMessageUserId) {
    Widget messageWidget;
    if (message['userId'] == userId) {
      messageWidget = Align(
        alignment: Alignment.centerRight,
        child: Container(
            padding: EdgeInsets.all(10.0),
            decoration: BoxDecoration(
                color: Colors.black12.withOpacity(0.05),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15.0),
                    topRight: Radius.circular(15.0),
                    bottomLeft: Radius.circular(15.0))),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(message['message'], style: TextStyle(fontSize: 16.0)),
                Padding(
                  padding: EdgeInsets.only(top: 3.0),
                  child: Text(
                    parseTimestamp(message['timestamp']),
                    style: TextStyle(
                        fontSize: 11.0,
                        fontFamily: '',
                        color: Colors.black38,
                        fontWeight: FontWeight.w300),
                  ),
                ),
              ],
            )),
      );
    } else {
      messageWidget = Align(
        alignment: Alignment.centerLeft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            otherUserImage(message, nextMessageUserId),
            Container(
                margin: EdgeInsets.only(left: 10.0),
                padding: EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black12.withOpacity(0.08)),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15.0),
                        topRight: Radius.circular(15.0),
                        bottomRight: Radius.circular(15.0))),
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(message['message'], style: TextStyle(fontSize: 16.0)),
                    Padding(
                      padding: EdgeInsets.only(top: 3.0),
                      child: Text(
                        parseTimestamp(message['timestamp']),
                        style: TextStyle(
                            fontFamily: '',
                            fontSize: 11.0,
                            color: Colors.black38,
                            fontWeight: FontWeight.w300),
                      ),
                    ),
                  ],
                ))
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: 7.0),
      child: messageWidget,
    );
  }

  String parseTimestamp(timestamp) {
    DateTime now = DateTime.now();
    DateTime date = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
    int hours = Jiffy(now).diff(date, Units.HOUR);
    return hours < 24
        ? Jiffy(date).fromNow()
        : Jiffy(date).format('MMM d, yyyy, h:mma');
  }

  Widget otherUserImage(
      Map<String, dynamic> message, String nextMessageUserId) {
    if (message['userId'] == nextMessageUserId)
      return Container(
        width: 40.0,
      );
    Widget userPhotoUrl = (conversation.userPhotoUrl == null)
        ? CircleAvatar(
            radius: 20.0,
            backgroundImage: AssetImage('assets/images/logo.png'),
          )
        : CircleAvatar(
            radius: 20.0,
            backgroundImage:
                CachedNetworkImageProvider(conversation.userPhotoUrl),
          );
    return userPhotoUrl;
  }

  Widget profileHeading() {
    Widget userPhotoUrl = (conversation.userPhotoUrl != null)
        ? CircleAvatar(
            radius: 20.0,
            backgroundImage:
                CachedNetworkImageProvider(conversation.userPhotoUrl),
          )
        : CircleAvatar(
            radius: 20.0,
            backgroundImage: AssetImage('assets/images/logo.png'),
          );

    return Row(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 10.0),
          child: Stack(
            children: [userPhotoUrl, onlineStatus()],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 10.0),
          child: Text(
            conversation.userFullName,
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 17.0),
          ),
        )
      ],
    );
  }

  getPreferences() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
      userFirstName = prefs.getString('firstName');
      userLastName = prefs.getString('lastName');
      photoUrl = prefs.getString('photoUrl');
      prefs.setString('currentScreen', 'messages-${conversation.id}');
    });
    getMessages();
  }

  getMessages() async {
    if (conversation.id != null) {
      if (conversation.documentSnapshot != null) {
        Stream<QuerySnapshot> messagesSnapshot = conversation
            .documentSnapshot.reference
            .collection('messages')
            .snapshots();
        messagesSnapshot.forEach((QuerySnapshot element) {
          List messagesList = List.from(element.docs);
          messagesList.sort((a, b) {
            return b.data()['timestamp'].compareTo(a.data()['timestamp']);
          });
          setState(() {
            messages = messagesList;
            isLoading = false;
          });
        });
      } else {
        DocumentSnapshot conversationDoc = await FirebaseFirestore.instance
            .collection('conversations')
            .doc(conversation.id)
            .get();
        if (conversationDoc != null) {
          conversation.documentSnapshot = conversationDoc;
          conversation.update();
          getMessages();
        }
      }
    }
  }

  sendMessage() async {
    if (newMessage != null && newMessage.isNotEmpty) {
      if (conversation.id == null && conversation.userId == null) {
        return;
      }
      if (conversation.id == null) {
        List userIds = [userId, conversation.userId];
        QuerySnapshot<Map<String, dynamic>> conversationResult =
            await FirebaseFirestore.instance
                .collection('conversations')
                .where('userIds', isGreaterThanOrEqualTo: userIds)
                .limit(1)
                .get();

        final List<DocumentSnapshot<Map<String, dynamic>>> queryConversations =
            conversationResult.docs;
        Function deepEq = const DeepCollectionEquality.unordered().equals;
        for (DocumentSnapshot<Map<String, dynamic>> element
            in queryConversations) {
          List queryUserIds = element.data()['userIds'];
          if (queryUserIds != null &&
              deepEq(userIds, List.from(element.data()['userIds']))) {
            conversation.id = element.id;
            conversation.documentSnapshot = element;
            break;
          }
        }

        if (conversation.id == null) {
          // create new conversation
          CollectionReference conversations =
              FirebaseFirestore.instance.collection('conversations');
          DocumentReference newConversation =
              await conversations.add({'userIds': userIds});
          conversation.id = newConversation.id;
          conversation.documentSnapshot = await newConversation.get();
        }
        conversation.update();
        getMessages();
      }

      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      CollectionReference messages =
          conversation.documentSnapshot.reference.collection('messages');
      String newMessageCopy = newMessage;
      messages.add({
        'conversationId': conversation.id,
        'userId': userId,
        'message': newMessage,
        'timestamp': timestamp
      }).then((DocumentReference message) {
        conversation.lastMessage = 'You: $newMessageCopy';
        conversation.lastMessageTimestamp = timestamp;
        conversation.lastMessageIsRead = true;
        conversation.update();
      });
      messageController.text = '';
      setState(() {
        newMessage = '';
      });

      notifyUser();
    }
  }

  readLastMessage() async {
    if (conversation.lastMessageId != null &&
        conversation.lastMessageIsRead != true) {
      await conversation.documentSnapshot.reference
          .collection('messages')
          .doc(conversation.lastMessageId)
          .update({'isRead': true});
      conversation.lastMessageIsRead = true;
      conversation.update();
    }
  }

  StreamBuilder<DocumentSnapshot> onlineStatus() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(conversation.userId)
          .snapshots(),
      builder: (context,
          AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
        if (snapshot.hasData && snapshot.data.data()['isOnline'] == true) {
          return Positioned(
            bottom: 0.0,
            right: 0.0,
            child: Container(
              width: 11.0,
              height: 11.0,
              decoration: BoxDecoration(
                  color: Color(0XFF27AE60),
                  border: Border.all(color: Colors.white, width: 1.6),
                  borderRadius: BorderRadius.circular(50.0)),
            ),
          );
        }

        return Container(
          height: 0.0,
        );
      },
    );
  }

  notifyUser() async {
    Conversation convo = Conversation.fromJson(conversation.toJson());
    convo.userId = userId;
    convo.userFullName = '$userFirstName $userLastName';
    convo.userPhotoUrl = photoUrl;
    SendNotification(conversation.userId, 'Message',
        '$userFirstName $userLastName has sent you a message', {
      'type': 'new_message',
      'conversation': jsonEncode(convo.toJson()),
    });
  }
}
