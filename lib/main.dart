import 'package:chatapp/ChatScreen.dart';
import 'package:chatapp/Register.dart';
import 'package:chatapp/chatlist.dart';
import 'package:chatapp/login.dart';
import 'package:chatapp/search.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:page_transition/page_transition.dart';
import 'package:get_it/get_it.dart';

GetIt locator = GetIt();

void setupLocator() {
  locator.registerSingleton(CallsAndMessagesService());
}

void main() async {
  setupLocator();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FlutterDownloader.initialize();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool userLogin;
  @override
  void initState() {
    // getLoginState();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: 'splash',
      routes: {
        'splash': (context) => Splash(),
        'register': (context) => RegScreen(),
        'login': (context) => LoginScreen(),
        'chatlist': (context) => ChatListScreen(),
        'search': (context) => Search(),
      },
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primaryColor: Color(0xff145C9E),
        scaffoldBackgroundColor: Color(0xff1F1F1F),
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }
}

class Splash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var auth = FirebaseAuth.instance;
    return AnimatedSplashScreen(
      splash: Image(
        image: AssetImage('assets/images/source.png'),
      ),
      splashIconSize: 1000,
      nextScreen: auth.currentUser != null ? ChatListScreen() : RegScreen(),
      splashTransition: SplashTransition.fadeTransition,
      pageTransitionType: PageTransitionType.leftToRightWithFade,
      duration: 2200,
    );
  }
}
