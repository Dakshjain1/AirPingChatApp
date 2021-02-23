import 'dart:io';
import 'package:chatapp/google.dart';
import 'package:chatapp/helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:geocoder/geocoder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';

File _image;
String url =
    "https://firebasestorage.googleapis.com/v0/b/my-project-1554107915174.appspot.com/o/ChatAppProfilePics%2Fnull.png?alt=media&token=d0f507ef-049c-4581-9628-2fa8b9a649d7";
String myPhotoURL, fcmToken;

class RegScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text('Register with us!'),
        ),
        body: Register());
  }
}

class Register extends StatefulWidget {
  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging();
  String emailid, pass, uname, mob;
  var first;
  var auth = FirebaseAuth.instance;
  var store = FirebaseFirestore.instance;
  final formKey = GlobalKey<FormState>();

  TextEditingController username = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController passwd = TextEditingController();
  TextEditingController mobile = TextEditingController();

  bool spin = false;
  bool passvalidate = false;
  bool emailvalidate = false;
  bool unamevalidate = false;
  LocationData currentLocation;

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
          return '${first.addressLine}';
        } else if (_permission == PermissionStatus.denied) {
          location = null;
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
  }

  _saveDeviceTokenandGetLoc() async {
    bool serviceEnabled;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    fcmToken = await _fcm.getToken();
    if (fcmToken != null && serviceEnabled) {
      var x = await initPlatformState();
      var tokenRef = _db.collection('users').doc(fcmToken);
      await tokenRef.set({
        'devtoken': fcmToken,
        'createdAt': FieldValue.serverTimestamp(),
        'platform': Platform.operatingSystem,
        'locationBool': serviceEnabled,
        'request': false,
        'myloc': x
      });
    } else if (fcmToken != null && !serviceEnabled) {
      var tokenRef = _db.collection('users').doc(fcmToken);
      await tokenRef.set({
        'devtoken': fcmToken,
        'createdAt': FieldValue.serverTimestamp(),
        'platform': Platform.operatingSystem,
        'locationBool': serviceEnabled,
        'request': false,
      });
    }
  }

  @override
  void initState() {
    _image = null;
    _saveDeviceTokenandGetLoc();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData queryData = MediaQuery.of(context);

    return ModalProgressHUD(
      inAsyncCall: spin,
      child: SingleChildScrollView(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(new FocusNode());
          },
          child: Container(
            height: queryData.size.height,
            alignment: Alignment.center,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                      spreadRadius: 2,
                                      blurRadius: 10,
                                      color: Colors.black.withOpacity(0.3),
                                      offset: Offset(0, 5))
                                ],
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                    image: _image == null
                                        ? CachedNetworkImageProvider(
                                            url,
                                          )
                                        : FileImage(
                                            _image,
                                          ),
                                    fit: BoxFit.cover),
                                border: Border.all(
                                  width: 4,
                                  color: Colors.white,
                                ),
                              ),
                              height: 130,
                              width: 130,
                            ),
                            Positioned(
                              child: GestureDetector(
                                onTap: () async {
                                  var image = await ImagePicker.pickImage(
                                      source: ImageSource.gallery);
                                  setState(() {
                                    _image = image;
                                  });
                                },
                                child: Container(
                                  child: Icon(
                                    Icons.camera_alt_sharp,
                                    color: Colors.white,
                                  ),
                                  decoration: BoxDecoration(
                                      color: Color(0xff1F1F1F),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        width: 4,
                                        color: Colors.white,
                                      )),
                                  height: 40,
                                  width: 40,
                                ),
                              ),
                              bottom: 0,
                              right: 0,
                            )
                          ],
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        TextFormField(
                          validator: (value) {
                            return value.isEmpty || value.length < 4
                                ? "Username less than 4 characters"
                                : null;
                          },
                          controller: username,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "username",
                            hintStyle: TextStyle(color: Colors.white),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                          ),
                          onChanged: (value) {
                            var y = value.split("");
                            var z = y[0].toUpperCase();
                            y.remove(value[0]);
                            y.insert(0, z);
                            //print(y.join());
                            uname = y.join();
                          },
                        ),
                        TextFormField(
                          validator: (value) {
                            return value.length == 10
                                ? null
                                : "Give correct mobile number";
                          },
                          controller: mobile,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "mobile number",
                            hintStyle: TextStyle(color: Colors.white),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                          ),
                          onChanged: (value) {
                            mob = value;
                          },
                        ),
                        TextFormField(
                          validator: (value) {
                            return RegExp(
                                        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                    .hasMatch(value)
                                ? null
                                : "Enter correct email";
                          },
                          keyboardType: TextInputType.emailAddress,
                          controller: email,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "email",
                            hintStyle: TextStyle(color: Colors.white),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                          ),
                          onChanged: (value) {
                            emailid = value;
                          },
                        ),
                        TextFormField(
                          validator: (val) {
                            return val.length < 8
                                ? "Password is less that 8 characters"
                                : null;
                          },
                          obscureText: true,
                          controller: passwd,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "password",
                            hintStyle: TextStyle(color: Colors.white),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                          ),
                          onChanged: (value) {
                            pass = value;
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  GestureDetector(
                    onTap: () async {
                      if (formKey.currentState.validate()) {
                        setState(() {
                          spin = true;
                        });
                        try {
                          if (_image != null) {
                            var fbstorage = FirebaseStorage.instance
                                .ref()
                                .child("ChatAppProfilePics/$uname.png");
                            await fbstorage.putFile(_image);
                            //sleep(Duration(seconds: 5));
                            myPhotoURL = await fbstorage.getDownloadURL();
                          } else {
                            myPhotoURL = url;
                          }
                          print(myPhotoURL);
                          store.collection('users').doc(fcmToken).update({
                            'username': uname,
                            'email': emailid,
                            'phone': mob,
                            '$uname': myPhotoURL
                          });
                        } catch (e) {
                          String x = e.code;
                          Scaffold.of(context)
                              .showSnackBar(SnackBar(content: Text(x)));
                        }
                        try {
                          await auth.createUserWithEmailAndPassword(
                              email: emailid, password: pass);
                          Navigator.pushReplacementNamed(context, 'login');
                          setState(() {
                            spin = false;
                          });
                        } catch (e) {
                          String x = e.code;
                          Scaffold.of(context)
                              .showSnackBar(SnackBar(content: Text(x)));
                          setState(() {
                            spin = false;
                          });
                        }
                      }
                      Constants.myName = uname;
                    },
                    child: Container(
                      width: queryData.size.width,
                      padding: EdgeInsets.all(15),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: LinearGradient(colors: [
                            const Color(0xff007EF4),
                            const Color(0xff2A75BC)
                          ])),
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  GestureDetector(
                    onTap: () async {
                      try {
                        await signInWithGoogle().then((result) {
                          if (result != null) {
                            Navigator.pushReplacementNamed(context, 'chatlist');
                          }
                        });
                      } catch (e) {
                        String x = e.code;
                        Scaffold.of(context)
                            .showSnackBar(SnackBar(content: Text(x)));
                      }
                    },
                    child: Container(
                      width: queryData.size.width,
                      padding: EdgeInsets.all(15),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Colors.white),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                              backgroundColor: Colors.transparent,
                              child:
                                  Image.asset('assets/images/google_logo.png')),
                          SizedBox(
                            width: 5,
                          ),
                          Text(
                            'Sign Up with Google',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have account? ',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, 'login');
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 16,
                              decoration: TextDecoration.underline,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
