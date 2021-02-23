import 'dart:io';

import 'package:chatapp/ChatScreen.dart';
import 'package:chatapp/Register.dart';
import 'package:chatapp/helper.dart';
import 'package:chatapp/search.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

getChatRooms(String myname) {
  return FirebaseFirestore.instance
      .collection('Chat Room')
      .where('users', arrayContains: myname)
      .snapshots();
}

String url =
    'https://raw.githubusercontent.com/Dakshjain1/photo/master/download.jpg';
String emailLogged;

class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  var store = FirebaseFirestore.instance;
  var auth = FirebaseAuth.instance;
  MediaQueryData queryData;

  final User user = FirebaseAuth.instance.currentUser;

  QuerySnapshot user1Query;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  void showNow() {
    showGeneralDialog(
      context: context,
      pageBuilder: (BuildContext buildContext, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return Wrap(
          children: <Widget>[
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration:
                      BoxDecoration(color: Colors.black.withOpacity(0.5)),
                  width: queryData.size.width,
                  height: queryData.size.height,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Hero(
                      tag: Constants.myName,
                      child: Center(
                        child: CachedNetworkImage(
                          placeholder: (context, url) =>
                              CircularProgressIndicator(),
                          imageUrl: '${Constants.myPhotoURL}',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
    );
  }

  Stream chatRoomStream;
  Widget chatList() {
    return StreamBuilder(
      stream: chatRoomStream,
      builder: (context, snapshot) {
        return snapshot.hasData
            ? ListView.builder(
                itemCount: snapshot.data.documents.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return ListTile(
                    otheruser: user2 = snapshot.data.docs[index]
                        .data()['chatroomID']
                        .toString()
                        .replaceAll("_", "")
                        .replaceAll(Constants.myName, ""),
                    chatRoomID: snapshot.data.docs[index].data()['chatroomID'],
                  );
                })
            : Container();
      },
    );
  }

  Future<void> signOutGoogle() async {
    await googleSignIn.signOut();
    print("User Signed Out");
    print(emailLogged);
    var signOutID = user1Query.docs[0].id;
    print(signOutID);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(signOutID)
        .delete();
    await FirebaseAuth.instance.currentUser.delete();
  }

  void name() async {
    emailLogged = auth.currentUser.email;
    await store
        .collection('users')
        .where('email', isEqualTo: emailLogged)
        .get()
        .then((value) {
      setState(() {
        user1Query = value;
      });
    });
    Constants.myName = await user1Query.docs[0].get('username');
    print(emailLogged);
  }

  otherPersonChatRoom() async {
    emailLogged = auth.currentUser.email;
    await store
        .collection('users')
        .where('email', isEqualTo: emailLogged)
        .get()
        .then((value) {
      setState(() {
        user1Query = value;
      });
    });
    Constants.myName = await user1Query.docs[0].get('username');
    Constants.myPhotoURL = user1Query.docs[0].data()['${Constants.myName}'];
    print(emailLogged);
    chatRoomStream = await getChatRooms(Constants.myName);
    print(
        "we got the data + ${chatRoomStream.toString()} ${emailLogged}this is name  ${Constants.myPhotoURL}");
  }

  @override
  void initState() {
    print(auth.currentUser);
    otherPersonChatRoom();

    setState(() {});
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    queryData = MediaQuery.of(context);
    var auth = FirebaseAuth.instance;
    return Scaffold(
        floatingActionButton: FloatingActionButton(
            child: Icon(Icons.message),
            onPressed: () async {
              //Navigator.pushNamed(context, 'search');
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Search()),
              ).then((value) {
                otherPersonChatRoom();
                setState(() {});
              });
            }),
        appBar: AppBar(
          centerTitle: true,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Image(
                      height: 35,
                      width: 35,
                      image: AssetImage('assets/images/ic_launcher.png'),
                      //color: Colors.black,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 10,
              ),
              Text('Air Ping'),
            ],
          ),
          actions: [
            PopupMenuButton(
              onSelected: (result) async {
                if (result == 1) {
                } else if (result == 2) {
                  try {
                    if (auth.currentUser.providerData[0].providerId ==
                        'google.com') {
                      await signOutGoogle();
                    } else {
                      await auth.signOut();
                    }
                  } catch (e) {
                    String x = e.code;
                    print(x);
                  }
                  Navigator.pushReplacementNamed(context, 'login');
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 0,
                  child: Row(
                    children: [
                      Hero(
                        tag: Constants.myName,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            showNow();
                          },
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            backgroundImage: CachedNetworkImageProvider(
                              '${Constants.myPhotoURL}',
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(Constants.myName,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20))
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 1,
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit,
                        color: Colors.black,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text('Edit Profile')
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 2,
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout,
                        color: Colors.black,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text('Logout')
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Container(child: chatList()));
  }
}

class ListTile extends StatefulWidget {
  final String otheruser;
  final String chatRoomID;

  ListTile({this.otheruser, this.chatRoomID});

  @override
  _ListTileState createState() => _ListTileState();
}

class _ListTileState extends State<ListTile> {
  var searchSnapshot, picurl;
  Future getpic() async {
    await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: widget.otheruser)
        .get()
        .then((value) {
      setState(() {
        searchSnapshot = value;
      });
    });

    picurl = searchSnapshot.docs[0].get('${widget.otheruser}');
    print(widget.otheruser);
    print(picurl);
  }

  @override
  void initState() {
    getpic();
    // ignore: todo
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Chat(
                      chatRoomID: widget.chatRoomID,
                    )));
      },
      child: Container(
        color: Colors.black26,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Row(
          children: [
            picurl == null
                ? CircleAvatar(
                    backgroundColor: Color(0xff1F1F1F),
                  )
                : CircleAvatar(
                    backgroundColor: Color(0xff1F1F1F),
                    backgroundImage: CachedNetworkImageProvider(
                      picurl,
                    ),
                  ),
            SizedBox(
              width: 20,
            ),
            Text(
              widget.otheruser,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
