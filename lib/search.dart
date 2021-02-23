import 'package:chatapp/ChatScreen.dart';
import 'package:chatapp/helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

String user2;
String id;
String user2url;

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  TextEditingController username = TextEditingController();
  QuerySnapshot searchSnapshot;
  var store = FirebaseFirestore.instance;

  String emailLogged;
  QuerySnapshot user1Query;
  var auth = FirebaseAuth.instance;
  var user1Storage;

  createChatRoom({String user2}) async {
    emailLogged = auth.currentUser.email;
    user1Storage = await store
        .collection('users')
        .where('email', isEqualTo: emailLogged)
        .get()
        .then((value) {
      setState(() {
        user1Query = value;
      });
    });
    Constants.myName = user1Query.docs[0].get('username');
    id = getChatRoomId(Constants.myName, user2);
    List<String> users = [Constants.myName, user2];
    Map<String, dynamic> chatRoom = {
      "users": users,
      "chatroomID": id,
    };
    chatRoomDB(id, chatRoom);
    print("daksh jain daksh jain $user2url");
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => Chat(
                  chatRoomID: id,
                )));
  }

  initiateSearch() {
    if (user2 != Constants.myName && user2 != null) {
      store
          .collection('users')
          .where('username', isEqualTo: user2)
          .get()
          .then((value) {
        setState(() {
          searchSnapshot = value;
          user2url = searchSnapshot.docs[0].get('$user2');
        });
      });
    }
  }

  Widget searchList() {
    if (user2 != Constants.myName) {
      return searchSnapshot != null
          ? SingleChildScrollView(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: searchSnapshot.docs.length,
                itemBuilder: (context, index) {
                  return searchTile(
                    userName: searchSnapshot.docs[index].get('username'),
                    emailID: searchSnapshot.docs[index].get('email'),
                  );
                },
              ),
            )
          : Container();
    }
  }

  chatRoomDB(String id, usermap) {
    store.collection("Chat Room").doc(id).set(usermap);
  }

  Widget searchTile({String userName, String emailID}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          user2url == null
              ? CircleAvatar()
              : CircleAvatar(
                  backgroundColor: Color(0xff1F1F1F),
                  backgroundImage: CachedNetworkImageProvider(
                    user2url,
                  ),
                  radius: 30,
                ),
          SizedBox(
            width: 20,
          ),
          Column(
            //crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                emailID,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Spacer(),
          GestureDetector(
            onTap: () {
              if (user2 != Constants.myName) {
                createChatRoom(user2: userName);
              }
            },
            child: Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(colors: [
                  const Color(0xff007EF4),
                  const Color(0xff2A75BC),
                ]),
              ),
              child: Text(
                'Message',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, () {
                setState(() {});
              });
            }),
        // title: Text('Chat Application'),
      ),
      body: Container(
          child: Column(
        children: [
          Container(
            color: Colors.grey.shade700,
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                    child: TextField(
                  controller: username,
                  style: TextStyle(fontSize: 16, color: Colors.white),
                  decoration: InputDecoration(
                      hintText: "Search Username...",
                      hintStyle: TextStyle(fontSize: 16, color: Colors.white),
                      border: InputBorder.none),
                  onChanged: (value) {
                    user2 = value;
                  },
                )),
                GestureDetector(
                  onTap: () {
                    if (user2 != Constants.myName) {
                      initiateSearch();
                    }
                  },
                  child: Container(
                      height: 40,
                      width: 40,
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(colors: [
                            Colors.grey.shade800,
                            Colors.grey.shade600
                          ])),
                      child: Image(
                          image: AssetImage('assets/images/search_white.png'))),
                )
              ],
            ),
          ),
          searchList(),
        ],
      )),
    );
  }
}

getChatRoomId(String a, String b) {
  if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
    return "$b\_$a";
  } else {
    return "$a\_$b";
  }
}
