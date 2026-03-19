import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_config.dart';
import 'controllers/game_controller.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/waiting_room_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/result_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    debugPrint('Initialiserer Firebase...');
    await Firebase.initializeApp(options: firebaseOptions);
    debugPrint('Firebase initialisert OK.');
    
    // Deaktiver persistens på web for å unngå potensielle IndexedDB-låser
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
    debugPrint('Firestore settings satt (persistens deaktivert).');
  } catch (e) {
    debugPrint('KRITISK FEIL VED START: $e');
  }
  runApp(const TrinesBursdagApp());
}

class TrinesBursdagApp extends StatefulWidget {
  const TrinesBursdagApp({super.key});

  @override
  State<TrinesBursdagApp> createState() => _TrinesBursdagAppState();
}

class _TrinesBursdagAppState extends State<TrinesBursdagApp> {
  final GameController gameController = GameController();
  bool _showSplash = true;

  @override
  void dispose() {
    gameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    );

    return MaterialApp(
      title: 'Trines Bursdag Quiz',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF8B5CF6), // En fin lilla/fiolett
        textTheme: textTheme,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent, // Nødvendig for at gradienten skal synes bak
      ),
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: AnimatedBuilder(
          animation: gameController,
          builder: (context, child) {
            if (_showSplash) {
              return SplashScreen(
                onDone: () => setState(() => _showSplash = false),
              );
            }

            if (gameController.currentUserName.isEmpty) {
              return LoginScreen(controller: gameController);
            }
            
            if (gameController.currentRole == UserRole.admin) {
              return AdminScreen(controller: gameController);
            }

            switch (gameController.currentPhase) {
              case GamePhase.waitingRoom:
                return WaitingRoomScreen(controller: gameController);
              case GamePhase.playersAnswering:
              case GamePhase.trineAnswering:
              case GamePhase.showingResult:
                return QuizScreen(controller: gameController);
              case GamePhase.finalLeaderboard:
                return ResultScreen(controller: gameController);
            }
          },
        ),
      ),
    );
  }
}
