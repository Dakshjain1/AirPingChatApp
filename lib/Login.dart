import 'package:chatapp/google.dart';
import 'package:chatapp/helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text('Login...'),
        ),
        body: Login());
  }
}

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  QuerySnapshot searchSnapshot;
  var store = FirebaseFirestore.instance;
  var auth = FirebaseAuth.instance;
  final formKey = GlobalKey<FormState>();
  String emailid, pass;
  TextEditingController email = TextEditingController();
  TextEditingController passwd = TextEditingController();
  TextEditingController _c = TextEditingController();
  String resetEmail;
  bool spin = false;
  bool passvalidate = false;
  bool emailvalidate = false;
  QuerySnapshot user1Query;
  void myname() async {
    var emailLogged = auth.currentUser.email;
    await store
        .collection('users')
        .where('email', isEqualTo: emailLogged)
        .get()
        .then((value) {
      setState(() {
        user1Query = value;
      });
    });
    Constants.myName = user1Query.docs[0].get('username');
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
                    height: 10,
                  ),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                          child: new Dialog(
                            child: new Column(
                              children: <Widget>[
                                new TextField(
                                  decoration: new InputDecoration(
                                      hintText: "Enter email"),
                                  controller: _c,
                                ),
                                new FlatButton(
                                  child: new Text("Send"),
                                  onPressed: () {
                                    setState(() {
                                      resetEmail = _c.text;
                                    });
                                    Navigator.pop(context);
                                    auth.sendPasswordResetEmail(
                                        email: resetEmail);
                                    Scaffold.of(context).showSnackBar(SnackBar(
                                        content: Text(
                                            'Password Reset mail sent !')));
                                  },
                                )
                              ],
                            ),
                          ),
                          context: context);
                    },
                    child: Container(
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.all(10),
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  GestureDetector(
                    onTap: () async {
                      if (formKey.currentState.validate()) {
                        setState(() {
                          spin = true;
                        });

                        try {
                          var login = await auth.signInWithEmailAndPassword(
                              email: emailid, password: pass);

                          setState(() {
                            spin = false;
                          });

                          Navigator.pushReplacementNamed(context, "chatlist");
                        } catch (e) {
                          String x = e.code;
                          Scaffold.of(context)
                              .showSnackBar(SnackBar(content: Text(x)));
                          setState(() {
                            spin = false;
                          });
                        }
                      }
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
                        'Sign In',
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
                                child: Image.asset(
                                    'assets/images/google_logo.png')),
                            SizedBox(
                              width: 5,
                            ),
                            Text(
                              'Sign In with Google',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ]),
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Don\'t have an account? ',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, 'register');
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Register now',
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
