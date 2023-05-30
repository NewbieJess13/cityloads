import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/conversation.dart';
import './messages.dart';
import 'package:jiffy/jiffy.dart';
import 'package:cached_network_image/cached_network_image.dart';

class Conversations extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ConversationsState();
}

class _ConversationsState extends State<Conversations> {
  bool isLoading = true;
  String? userId;
  late SharedPreferences prefs;
  List conversations = [];

  @override
  void initState() {
    super.initState();
    getPreferences();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0.0,
          centerTitle: false,
          title: Text('MESSAGES',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 26.0)),
          actions: [
            // IconButton(
            //   onPressed: () => {},
            //   splashRadius: 20.0,
            //   icon: Icon(
            //     Ionicons.search_outline,
            //     color: Colors.black,
            //     size: 25.0,
            //   ),
            // )
          ],
        ),
        body: isLoading
            ? Center(
                child: SizedBox(
                    height: 30.0,
                    width: 30.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 1,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor),
                    )),
              )
            : conversations.length == 0
                ? Center(
                    child: Text(
                      'You don\'t have any conversations yet.',
                      style: TextStyle(fontSize: 17.0, color: Colors.black54),
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.only(top: 5.0),
                    child: ListView.builder(
                        itemCount: conversations.length,
                        itemBuilder: (BuildContext ctxt, int index) {
                          return buildItem(conversations[index]);
                        }),
                  ));
  }

  Widget buildItem(Conversation conversation) {
    Widget userPhotoUrl = (conversation.userPhotoUrl == null)
        ? CircleAvatar(
            radius: 25.0,
            backgroundImage: AssetImage('assets/images/logo.png'),
          )
        : CircleAvatar(
            radius: 25.0,
            backgroundImage:
                CachedNetworkImageProvider(conversation.userPhotoUrl!),
          );

    return ChangeNotifierProvider.value(
      value: conversation,
      child: Consumer<Conversation>(builder: (context, value, child) {
        return InkWell(
          onTap: () => {goToMessages(conversation)},
          child: Container(
            padding: EdgeInsets.only(
                left: 15.0, right: 15.0, top: 10.0, bottom: 10.0),
            child: Row(
              children: [
                Stack(
                  children: [userPhotoUrl, onlineStatus(conversation.userId)],
                ),
                Flexible(
                  child: Padding(
                    padding: EdgeInsets.only(left: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              conversation.userFullName!,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 17.0),
                            ),
                            Text(
                              parseTimestamp(conversation.lastMessageTimestamp),
                              maxLines: 1,
                              style: TextStyle(
                                  fontWeight: FontWeight.w300, fontSize: 14.0),
                            )
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 2.0),
                          child: Text(
                            conversation.lastMessage!,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                                fontWeight:
                                    conversation.lastMessageIsRead == true
                                        ? FontWeight.w400
                                        : FontWeight.w700,
                                fontSize: 14.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      }),
    );
  }

  String parseTimestamp(timestamp) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
    return Jiffy.parseFromDateTime(date).fromNow();
  }

  getPreferences() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });
    getConversations();
  }

  getConversations() async {
    List conversationsList = [];
    QuerySnapshot<Map<String, dynamic>> conversationsResult =
        await FirebaseFirestore.instance
            .collection('conversations')
            .where('userIds', arrayContains: userId)
            .get();

    final List<DocumentSnapshot<Map<String, dynamic>>> queryConversations =
        conversationsResult.docs;
    for (int i = 0; i < queryConversations.length; i++) {
      String conversationId = queryConversations[i].id;
      QuerySnapshot<Map<String, dynamic>> lastMessageResult =
          await queryConversations[i]
              .reference
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .get();
      final List<DocumentSnapshot<Map<String, dynamic>>> lastMessage =
          lastMessageResult.docs;
      if (lastMessage.length > 0) {
        var otherUserId = queryConversations[i]
            .data()!['userIds']
            .toList()
            .firstWhere((cuserId) => cuserId != userId, orElse: () => null);
        if (otherUserId != null) {
          QuerySnapshot<Map<String, dynamic>> otherUserQuery =
              await FirebaseFirestore.instance
                  .collection('users')
                  .where('id', isEqualTo: otherUserId)
                  .limit(1)
                  .get();
          if (otherUserQuery.docs.length > 0) {
            Map<String, dynamic> otherUser = otherUserQuery.docs[0].data();
            bool? lastMessageIsRead = lastMessage[0].data()!['isRead'];
            String lastMessageContent = '${lastMessage[0].data()!['message']}';
            if (lastMessage[0].data()!['userId'] == userId) {
              lastMessageIsRead = true;
              lastMessageContent = 'You: $lastMessageContent';
            }
            Conversation conversation = Conversation.fromJson({
              'id': conversationId,
              'userFullName':
                  '${otherUser['firstName']} ${otherUser['lastName']}',
              'userId': otherUserQuery.docs[0].id,
              'userPhotoUrl': otherUser['photoUrl'],
              'lastMessageId': lastMessage[0].id,
              'lastMessage': lastMessageContent,
              'lastMessageIsRead': lastMessageIsRead,
              'lastMessageTimestamp': lastMessage[0].data()!['timestamp'],
              'documentSnapshot': queryConversations[i]
            });
            setState(() {
              conversationsList.add(conversation);
            });
          }
        }
      }
    }
    setState(() {
      conversations = conversationsList;
      isLoading = false;
    });
    sortConversations();
  }

  StreamBuilder<DocumentSnapshot> onlineStatus(userId) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context,
          AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
        if (snapshot.hasData && snapshot.data!.data()!['isOnline'] == true) {
          return Positioned(
            bottom: 0.0,
            right: 0.0,
            child: Container(
              width: 12.0,
              height: 12.0,
              decoration: BoxDecoration(
                  color: Color(0XFF27AE60),
                  border: Border.all(color: Colors.white, width: 1.8),
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

  sortConversations() {
    setState(() {
      conversations.sort(
          (a, b) => b.lastMessageTimestamp.compareTo(a.lastMessageTimestamp));
    });
  }

  goToMessages(Conversation conversation) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => Messages(
                conversation: conversation,
              )),
    );
    sortConversations();
  }
}
