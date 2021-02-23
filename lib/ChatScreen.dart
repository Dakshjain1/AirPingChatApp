import 'dart:async';
import 'package:chatapp/helper.dart';
import 'package:chatapp/videoplayerwidget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:location/location.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Register.dart';
import 'main.dart';
import 'package:geocoder/geocoder.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'fullsceenImg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:intl/intl.dart';

var otherUserURL,
    otherUserPhone,
    otherUserEmail,
    otherUserfcmToken,
    otherUserAddress;
bool notifyColour = false, otherUserLocBool = false;

class Chat extends StatefulWidget {
  final String chatRoomID;
  Chat({this.chatRoomID});

  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final CallsAndMessagesService _service = locator<CallsAndMessagesService>();
  TextEditingController msgControler = TextEditingController();
  var first;
  String dataurl, filename;
  LocationData currentLocation;
  String msg;
  bool notification;
  Stream chatMsgStream;
  ScrollController _controller = ScrollController();
  String otherUser;
  QuerySnapshot qs;
  bool spin = false;
  Widget chatMsgList() {
    return Container(
      margin: EdgeInsets.only(bottom: 85.0),
      child: StreamBuilder(
        builder: (context, snapshot) {
          return snapshot.hasData
              ? ListView.builder(
                  controller: _controller,
                  //reverse: true,
                  itemCount: snapshot.data.documents.length,
                  itemBuilder: (context, index) {
                    return MsgTile(
                        time: snapshot.data.documents[index].data()["time"],
                        filename:
                            snapshot.data.documents[index].data()["filename"],
                        filetype: snapshot.data.documents[index].data()["type"],
                        message:
                            snapshot.data.documents[index].data()["message"],
                        sentbyme: Constants.myName ==
                            snapshot.data.documents[index].data()["sendby"]);
                  })
              : Container();
        },
        stream: chatMsgStream,
      ),
    );
  }

  addMsg(String chatRoomID, messageMap) {
    FirebaseFirestore.instance
        .collection('Chat Room')
        .doc(chatRoomID)
        .collection('chat')
        .add(messageMap);

    FirebaseFirestore.instance.collection('Messages').add(messageMap);
  }

  viewLoc() async {
    await FirebaseFirestore.instance
        .collection("users")
        .where("username", isEqualTo: otherUser)
        .get()
        .then((value) {
      setState(() {
        qs = value;
        otherUserAddress = qs.docs[0].data()['myloc'];
      });
    });
    print('Address is $otherUserAddress');
    if (otherUserAddress == null) {
      Scaffold.of(context).showSnackBar(
          SnackBar(content: Text('$otherUser\'s Location is not shared...')));
    } else {
      String url = 'https://www.google.com/maps/place/$otherUserAddress';
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw 'Could not launch $url';
      }
    }
  }

  reqLoc() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(otherUserfcmToken)
        .update({'request': true});
  }

  bool notifyColourFunc() {
    FirebaseFirestore.instance
        .collection("users")
        .where("username", isEqualTo: Constants.myName)
        .get()
        .then((value) {
      setState(() {
        qs = value;
        notifyColour = qs.docs[0].data()["request"];
      });
    });
    return notifyColour;
  }

  bool requestOrViewLoc() {
    FirebaseFirestore.instance
        .collection("users")
        .where("username", isEqualTo: otherUser)
        .get()
        .then((value) {
      setState(() {
        qs = value;
        otherUserLocBool = qs.docs[0].data()["locationBool"];
        otherUserAddress = qs.docs[0].data()["myloc"];
      });
    });
    if (otherUserLocBool && otherUserAddress != null) {
      return true;
    } else {
      return false;
    }
  }

  initPlatformState() async {
    LocationData location;
    bool serviceStatus;
    try {
      var _permission;
      serviceStatus = await Geolocator.isLocationServiceEnabled();
      print("Service status: $serviceStatus");
      if (serviceStatus) {
        _permission = await Location().requestPermission();
        print("Permission: $_permission");

        if (_permission == PermissionStatus.granted) {
          location = await Location().getLocation();
          print(location); //LocationData<lat: 28.4260107, long: 76.9453705>

        }
      } else {
        bool serviceStatusResult = await Location().requestService();
        print("Service status activated after request: $serviceStatusResult");
        if (serviceStatusResult) {
          initPlatformState();
        }
      }
    } on PlatformException catch (e) {
      print(e);
      if (e.code == 'PERMISSION_DENIED') {
        var error = e.message;
        print(error);
      } else if (e.code == 'SERVICE_STATUS_ERROR') {
        var error = e.message;
        print(error);
      }
      location = null;
    }

    setState(() {
      currentLocation = location;
    });

    print(currentLocation.toString());
    final coordinates =
        Coordinates(currentLocation.latitude, currentLocation.longitude);
    var addresses =
        await Geocoder.local.findAddressesFromCoordinates(coordinates);
    //print(addresses.first.);
    first = addresses.first;
    print('${first.addressLine}');

    FirebaseFirestore.instance.collection('users').doc(fcmToken).update({
      'myloc': '${first.addressLine}',
      'request': false,
      'locationBool': serviceStatus,
    });
  }

  showAttachmentBottomSheet(context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Container(
            child: Wrap(
              children: <Widget>[
                ListTile(
                    leading: Icon(Icons.image),
                    title: Text('Image'),
                    onTap: () => showFilePicker(FileType.image)),
                ListTile(
                    leading: Icon(Icons.videocam),
                    title: Text('Video'),
                    onTap: () => showFilePicker(FileType.video)),
                ListTile(
                  leading: Icon(Icons.insert_drive_file),
                  title: Text('File'),
                  onTap: () => showFilePicker(FileType.any),
                ),
              ],
            ),
          );
        });
  }

  storeImage2FirebaseStorage(_image) async {
    var fbstorage = FirebaseStorage.instance
        .ref()
        .child("ChatData/${DateTime.now().millisecondsSinceEpoch}");
    await fbstorage.putFile(_image);
    //sleep(const Duration(seconds: 5));
    dataurl = await fbstorage.getDownloadURL();
    print("1 $dataurl");
  }

  storeFile2FirebaseStorage(file, filetype) async {
    var fbstorage = FirebaseStorage.instance
        .ref()
        .child("ChatData/${DateTime.now().millisecondsSinceEpoch}");
    await fbstorage.putFile(file);
    //sleep(const Duration(seconds: 5));
    dataurl = await fbstorage.getDownloadURL();
    filename = fbstorage.name;
    print("1 $dataurl");
  }

  storeData2FirestoreDB(String chatRoomID, messageMap) async {
    await FirebaseFirestore.instance
        .collection('Chat Room')
        .doc(chatRoomID)
        .collection('chat')
        .add(messageMap);

    await FirebaseFirestore.instance.collection('Messages').add(messageMap);
  }

  showFilePicker(FileType fileType) async {
    var file;
    if (fileType == FileType.image) {
      file = await ImagePicker.pickImage(source: ImageSource.gallery);
      setState(() {
        spin = true;
      });
      await storeImage2FirebaseStorage(file);
      print(dataurl);
      setState(() {
        spin = false;
      });
      Map<String, dynamic> msgMap = {
        "sendby": Constants.myName,
        "message": dataurl,
        "type": "picture",
        "time": DateTime.now().millisecondsSinceEpoch,
        "receiver": otherUser
      };

      await storeData2FirestoreDB(widget.chatRoomID, msgMap);
    } else if (fileType == FileType.video) {
      file = await FilePicker.getFile(type: fileType);
      setState(() {
        spin = true;
      });
      await storeFile2FirebaseStorage(file, fileType);
      print(dataurl);
      setState(() {
        spin = false;
      });
      Map<String, dynamic> msgMap = {
        "sendby": Constants.myName,
        "message": dataurl,
        "type": "video",
        "time": DateTime.now().millisecondsSinceEpoch,
        "receiver": otherUser
      };
      await storeData2FirestoreDB(widget.chatRoomID, msgMap);
    } else if (fileType == FileType.any) {
      file = await FilePicker.getFile(type: fileType);
      setState(() {
        spin = true;
      });
      await storeFile2FirebaseStorage(file, fileType);
      print(dataurl);
      print(filename);
      setState(() {
        spin = false;
      });
      Map<String, dynamic> msgMap = {
        "sendby": Constants.myName,
        "message": dataurl,
        "type": "file",
        "filename": filename,
        "time": DateTime.now().millisecondsSinceEpoch,
        "receiver": otherUser
      };
      await storeData2FirestoreDB(widget.chatRoomID, msgMap);
    }

    if (file == null) {
      return;
    }

    //chatBloc.dispatch(SendAttachmentEvent(chat.chatId, file, fileType));
    Navigator.pop(context);
    Scaffold.of(context)
        .showSnackBar(SnackBar(content: Text('Sending Attachment...')));
    // GradientSnackBar.showMessage(context, 'Sending attachment..');
  }

  showDial() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$otherUser has requested you to share location'),
          actions: <Widget>[
            FlatButton(
              child: Text("ACCEPT"),
              onPressed: () async {
                setState(() {
                  initPlatformState();
                });

                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text("DENY"),
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(fcmToken)
                    .update({'request': false});

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  getotherUserDetails() async {
    otherUser =
        widget.chatRoomID.replaceAll("_", "").replaceAll(Constants.myName, "");
    await FirebaseFirestore.instance
        .collection("users")
        .where("username", isEqualTo: otherUser)
        .get()
        .then((value) {
      setState(() {
        qs = value;
        otherUserURL = qs.docs[0].data()['$otherUser'];
        otherUserPhone = qs.docs[0].data()["phone"];
        otherUserEmail = qs.docs[0].data()["email"];
        otherUserfcmToken = qs.docs[0].data()["devtoken"];
        // notifyColour = qs.docs[0].data()["request"];
      });
    });
    print("eqwertyui $otherUserPhone");
  }

  getMsg(String chatRoomID) {
    return FirebaseFirestore.instance
        .collection('Chat Room')
        .doc(chatRoomID)
        .collection('chat')
        .orderBy('time')
        .snapshots();
  }

  sendMsg() {
    if (msgControler.text.isNotEmpty) {
      Map<String, dynamic> msgMap = {
        "sendby": Constants.myName,
        "message": msg,
        "type": "string",
        "time": DateTime.now().millisecondsSinceEpoch,
        "receiver": otherUser
      };
      addMsg(widget.chatRoomID, msgMap);
      setState(() {
        msgControler.clear();
      });
    }
    Timer(Duration(milliseconds: 100),
        () => _controller.jumpTo(_controller.position.maxScrollExtent));
  }

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
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Hero(
                      tag: Constants.myName,
                      child: Center(
                        child: CachedNetworkImage(
                          placeholder: (context, url) =>
                              CircularProgressIndicator(),
                          imageUrl: otherUserURL,
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

  @override
  void initState() {
    chatMsgStream = getMsg(widget.chatRoomID);
    getotherUserDetails();
    Timer(Duration(milliseconds: 100),
        () => _controller.jumpTo(_controller.position.maxScrollExtent));
    setState(() {});
    super.initState();
  }

  @override
  void dispose() {
    setState(() {
      FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserfcmToken)
          .update({'myloc': null});
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: spin,
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
                highlightColor: Colors.transparent,
                //focusColor: Colors.transparent,
                splashColor: Colors.transparent,
                // disabledColor: Colors.transparent,

                icon: Icon(
                  Icons.notifications,
                  color: notifyColourFunc()
                      ? Colors.red.shade400
                      : Color(0xff145C9E),
                ),
                onPressed: () {
                  notifyColourFunc()
                      ? showDial()
                      : print("No notifications !!");
                }),
            PopupMenuButton(
              onSelected: (result) {
                if (result == 0) {
                  _service.call(otherUserPhone);
                } else if (result == 1) {
                  _service.sendEmail(otherUserEmail);
                } else if (result == 2) {
                  requestOrViewLoc() ? viewLoc() : reqLoc();
                  // Navigator.of(context).pop();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 0,
                  child: Row(
                    children: [
                      Icon(
                        Icons.call,
                        color: Colors.black,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text('Call')
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 1,
                  child: Row(
                    children: [
                      Icon(
                        Icons.email,
                        color: Colors.black,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text('Send Email')
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 2,
                  child: Row(
                    children: [
                      Icon(
                        requestOrViewLoc()
                            ? Icons.location_on
                            : Icons.add_location_alt,
                        color: Colors.black,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      requestOrViewLoc()
                          ? Text('View Location')
                          : Text('Request Location')
                    ],
                  ),
                ),
              ],
            ),
          ],
          leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context, () {
                  setState(() {});
                });
              }),
          title: Row(
            children: [
              otherUserURL == null
                  ? CircleAvatar()
                  : Hero(
                      tag: otherUser,
                      child: GestureDetector(
                        onTap: () {
                          showNow();
                        },
                        child: CircleAvatar(
                          backgroundImage: CachedNetworkImageProvider(
                            otherUserURL,
                          ),
                        ),
                      ),
                    ),
              SizedBox(
                width: 12,
              ),
              Text(otherUser),
            ],
          ),
        ),
        body: Container(
          child: Stack(
            children: [
              chatMsgList(),
              Container(
                alignment: Alignment.bottomCenter,
                child: Container(
                  child: Container(
                    color: Colors.grey.shade700,
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                            child: TextField(
                          maxLines: null,
                          controller: msgControler,
                          style: TextStyle(fontSize: 16, color: Colors.white),
                          decoration: InputDecoration(
                              hintText: "Message...",
                              hintStyle:
                                  TextStyle(fontSize: 16, color: Colors.white),
                              border: InputBorder.none),
                          onTap: () {
                            Timer(
                                Duration(milliseconds: 100),
                                () => _controller.jumpTo(
                                    _controller.position.maxScrollExtent));
                          },
                          onChanged: (value) {
                            msg = value;
                          },
                        )),
                        GestureDetector(
                          onTap: () {
                            showAttachmentBottomSheet(context);
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
                                  image: AssetImage(
                                      'assets/images/Picture1.png'))),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        GestureDetector(
                          onTap: () {
                            sendMsg();
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
                                  image: AssetImage('assets/images/send.png'))),
                        )
                      ],
                    ),
                  ),
                ),
              ), //searchList(),
            ],
          ),
        ),
      ),
    );
  }
}

class MsgTile extends StatelessWidget {
  final message;
  final filename;
  final filetype;
  final bool sentbyme;
  final time;
  MsgTile(
      {this.message, this.sentbyme, this.filetype, this.filename, this.time});

  @override
  Widget build(BuildContext context) {
    Widget imgMsgContainer() {
      //picture
      return Container(
          margin: sentbyme
              ? EdgeInsets.fromLTRB(150, 8, 12, 8)
              // EdgeInsets.symmetric(vertical: 8, horizontal: 12)
              : EdgeInsets.fromLTRB(12, 8, 150, 8),
          width: MediaQuery.of(context).size.width,
          alignment: sentbyme ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: sentbyme
                      ? [const Color(0xff007EF4), const Color(0xff2A75BC)]
                      : [const Color(0x1AFFFFFF), const Color(0x1AFFFFFF)],
                ),
                borderRadius: sentbyme
                    ? BorderRadius.only(
                        topLeft: Radius.circular(23),
                        topRight: Radius.circular(23),
                        bottomLeft: Radius.circular(23),
                      )
                    : BorderRadius.only(
                        topLeft: Radius.circular(23),
                        topRight: Radius.circular(23),
                        bottomRight: Radius.circular(23),
                      ),
              ),
              child: GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ImageFullScreen(
                            '${DateTime.now().millisecondsSinceEpoch}',
                            message))),
                child: Hero(
                    tag: '${DateTime.now().millisecondsSinceEpoch}',
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image(
                          image: CachedNetworkImageProvider(
                            message,
                          ),
                        ))),
              )));
    }

    Widget videoMsgContainer() {
      //video
      return Container(
          margin: sentbyme
              ? EdgeInsets.fromLTRB(100, 8, 12, 8)
              // EdgeInsets.symmetric(vertical: 8, horizontal: 12)
              : EdgeInsets.fromLTRB(12, 8, 100, 8),
          width: MediaQuery.of(context).size.width,
          alignment: sentbyme ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: sentbyme
                      ? [const Color(0xff007EF4), const Color(0xff2A75BC)]
                      : [const Color(0x1AFFFFFF), const Color(0x1AFFFFFF)],
                ),
                borderRadius: sentbyme
                    ? BorderRadius.only(
                        topLeft: Radius.circular(23),
                        topRight: Radius.circular(23),
                        bottomLeft: Radius.circular(23),
                      )
                    : BorderRadius.only(
                        topLeft: Radius.circular(23),
                        topRight: Radius.circular(23),
                        bottomRight: Radius.circular(23),
                      ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Stack(
                      alignment: AlignmentDirectional.center,
                      children: <Widget>[
                        Container(
                          width: 245,
                          color: Colors.black,
                          height: 80,
                        ),
                        Column(
                          children: <Widget>[
                            Icon(
                              Icons.videocam,
                              color: Colors.white,
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            Text(
                              'Video',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                        height: 40,
                        child: IconButton(
                            icon: Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                            ),
                            onPressed: () => showVideoPlayer(context, message)))
                  ],
                ),
              )));
    }

    Widget fileMsgContainer() {
      //file
      Future<bool> _checkPermission() async {
        //if (widget.platform == TargetPlatform.android) {

        final status = await perm.Permission.storage.status;
        if (status != perm.PermissionStatus.granted) {
          final result = await perm.Permission.storage.request();
          if (result == perm.PermissionStatus.granted) {
            return true;
          }
        } else {
          return true;
        }
        return false;
      }

      void _requestDownload() async {
        await FlutterDownloader.enqueue(
          url: message,
          fileName: this.filename,
          savedDir: "/storage/emulated/0/Download/",
          showNotification: true,
          openFileFromNotification: true,
        );
      }

      return Container(
          margin: sentbyme
              ? EdgeInsets.fromLTRB(150, 8, 12, 8)
              // EdgeInsets.symmetric(vertical: 8, horizontal: 12)
              : EdgeInsets.fromLTRB(12, 8, 150, 8),
          width: MediaQuery.of(context).size.width,
          alignment: sentbyme ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: sentbyme
                    ? [const Color(0xff007EF4), const Color(0xff2A75BC)]
                    : [const Color(0x1AFFFFFF), const Color(0x1AFFFFFF)],
              ),
              borderRadius: sentbyme
                  ? BorderRadius.only(
                      topLeft: Radius.circular(23),
                      topRight: Radius.circular(23),
                      bottomLeft: Radius.circular(23),
                    )
                  : BorderRadius.only(
                      topLeft: Radius.circular(23),
                      topRight: Radius.circular(23),
                      bottomRight: Radius.circular(23),
                    ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Stack(
                    alignment: AlignmentDirectional.center,
                    children: <Widget>[
                      Container(
                        color: Colors.black,
                        height: 80,
                      ),
                      Column(
                        children: <Widget>[
                          Icon(
                            Icons.insert_drive_file,
                            color: Colors.white,
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Text(
                            "File",
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                      height: 40,
                      child: IconButton(
                          icon: Icon(
                            Icons.file_download,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            bool permission = await _checkPermission();
                            if (permission) {
                              _requestDownload();
                            } else {
                              await _checkPermission();
                            }
                          }))
                ],
              ),
            ),
          ));
    }

    Widget textMsgContainer() {
      //string
      return Container(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        width: MediaQuery.of(context).size.width,
        alignment: sentbyme ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: sentbyme
                  ? [const Color(0xff007EF4), const Color(0xff2A75BC)]
                  : [const Color(0x1AFFFFFF), const Color(0x1AFFFFFF)],
            ),
            borderRadius: sentbyme
                ? BorderRadius.only(
                    topLeft: Radius.circular(23),
                    topRight: Radius.circular(23),
                    bottomLeft: Radius.circular(23),
                  )
                : BorderRadius.only(
                    topLeft: Radius.circular(23),
                    topRight: Radius.circular(23),
                    bottomRight: Radius.circular(23),
                  ),
          ),
          child: Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    Row buildTimeStamp(BuildContext context, bool sentbyme, int time) {
      return Row(
          mainAxisAlignment:
              sentbyme ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: <Widget>[
            Container(
              child: Text(
                  DateFormat('dd MMM kk:mm')
                      .format(DateTime.fromMillisecondsSinceEpoch(time)),
                  style: TextStyle(color: Colors.white, fontSize: 12)),
              margin: EdgeInsets.only(
                  left: sentbyme ? 0.0 : 12.0,
                  right: sentbyme ? 12.0 : 0.0,
                  top: 0,
                  bottom: 5.0),
            )
          ]);
    }

    if (filetype == "string") {
      return Column(
        children: [textMsgContainer(), buildTimeStamp(context, sentbyme, time)],
      );
    } else if (filetype == "picture") {
      return Column(
        children: [imgMsgContainer(), buildTimeStamp(context, sentbyme, time)],
      );
      //return imgMsgContainer();
    } else if (filetype == "video") {
      return Column(
        children: [
          videoMsgContainer(),
          buildTimeStamp(context, sentbyme, time)
        ],
      );
    } else if (filetype == "file") {
      return Column(
        children: [fileMsgContainer(), buildTimeStamp(context, sentbyme, time)],
      );
    }
  }
}

void showVideoPlayer(parentContext, String videoUrl) async {
  await showModalBottomSheet(
      context: parentContext,
      builder: (BuildContext bc) {
        return VideoPlayerWidget(videoUrl);
      });
}

class CallsAndMessagesService {
  void call(String number) => launch("tel:$number");
  // void sendSms(String number) => launch("sms:$number");
  void sendEmail(String email) => launch("mailto:$email");
}
