import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/dummy_questions.dart';
import '../models/question.dart';

enum GamePhase {
  waitingRoom,
  playersAnswering,
  trineAnswering,
  showingResult,
  finalLeaderboard
}

enum UserRole {
  admin,
  trine,
  player
}

class GameController extends ChangeNotifier {
  GamePhase currentPhase = GamePhase.waitingRoom;
  UserRole currentRole = UserRole.player;
  String currentUserName = '';
  
  int currentQuestionIndex = 0;
  int timerSeconds = 60;
  Timer? _timer;

  List<String> joinedUsers = [];
  int totalTrinePoints = 0;
  int totalDeltakerPoints = 0;
  List<int> answersForCurrentQuestion = [0, 0, 0, 0]; 
  bool hasAnsweredCurrentQuestion = false;
  String roundOutcomeTrine = '';
  String roundOutcomeDeltakere = '';
  // Brukt til slider-avsløring på Admin-skjermen:
  double trineSliderAnswer = -1;
  double deltakerAverageAnswer = -1;

  final FirebaseFirestore db = FirebaseFirestore.instance;
  DocumentReference get roomRef => db.collection('rooms').doc('trines_bursdag');

  Future<void> login(String name) async {
    currentUserName = name;
    if (name.toLowerCase() == 'admin') {
      currentRole = UserRole.admin;
      await _initializeRoomIfNeeded();
    } else if (name.toLowerCase() == 'trine') {
      currentRole = UserRole.trine;
      await roomRef.set({
        'joinedUsers': FieldValue.arrayUnion([name])
      }, SetOptions(merge: true));
    } else {
      currentRole = UserRole.player;
      await roomRef.set({
        'joinedUsers': FieldValue.arrayUnion([name])
      }, SetOptions(merge: true));
    }
    
    _listenToRoom();
    notifyListeners();
  }

  Future<void> _initializeRoomIfNeeded() async {
    final snap = await roomRef.get();
    if (!snap.exists) {
      await roomRef.set({
        'phase': GamePhase.waitingRoom.name,
        'currentQuestionIndex': 0,
        'timerSeconds': 60,
        'joinedUsers': [],
        'totalTrinePoints': 0,
        'totalDeltakerPoints': 0,
        'roundOutcomeTrine': '',
        'roundOutcomeDeltakere': '',
        'answersForCurrentQuestion': [0, 0, 0, 0],
      });
    }
  }

  void _listenToRoom() {
    roomRef.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;
        
        GamePhase newPhase = GamePhase.values.firstWhere(
            (e) => e.name == data['phase'], orElse: () => GamePhase.waitingRoom);
        int newQuestionIndex = data['currentQuestionIndex'] ?? 0;

        // Reset local answer status if moving to new question or new phase
        if (newPhase == GamePhase.playersAnswering && newPhase != currentPhase) {
          hasAnsweredCurrentQuestion = false;
        }
        if (newQuestionIndex != currentQuestionIndex) {
          hasAnsweredCurrentQuestion = false;
        }

        currentPhase = newPhase;
        currentQuestionIndex = newQuestionIndex;
        timerSeconds = data['timerSeconds'] ?? 60;
        joinedUsers = List<String>.from(data['joinedUsers'] ?? []);
        totalTrinePoints = data['totalTrinePoints'] ?? 0;
        totalDeltakerPoints = data['totalDeltakerPoints'] ?? 0;
        roundOutcomeTrine = data['roundOutcomeTrine'] ?? '';
        roundOutcomeDeltakere = data['roundOutcomeDeltakere'] ?? '';
        answersForCurrentQuestion = List<int>.from(data['answersForCurrentQuestion'] ?? [0, 0, 0, 0]);
        trineSliderAnswer = (data['trineSliderAnswer'] ?? -1).toDouble();
        deltakerAverageAnswer = (data['deltakerAverageAnswer'] ?? -1).toDouble();

        notifyListeners();
      }
    });
  }

  Future<void> startQuiz() async {
    if (currentRole != UserRole.admin) return;
    
    await roomRef.update({
      'phase': GamePhase.playersAnswering.name,
      'currentQuestionIndex': 0,
      'totalTrinePoints': 0,
      'totalDeltakerPoints': 0,
      'answersForCurrentQuestion': [0, 0, 0, 0],
      'roundOutcomeTrine': '',
      'roundOutcomeDeltakere': '',
      'timerSeconds': 60,
    });
    
    _startTimer();
  }

  Future<void> nextPhase() async {
    if (currentRole != UserRole.admin) return;

    if (currentPhase == GamePhase.playersAnswering) {
      _stopTimer();
      await roomRef.update({
        'phase': GamePhase.trineAnswering.name,
      });
    } else if (currentPhase == GamePhase.trineAnswering) {
       // Stop the timer fully just in case
      _stopTimer();
      await _calculateRoundPoints();
      await roomRef.update({
        'phase': GamePhase.showingResult.name,
      });
    } else    if (currentPhase == GamePhase.showingResult) {
      if (currentQuestionIndex < dummyQuestions.length - 1) { 
        await roomRef.update({
          'currentQuestionIndex': currentQuestionIndex + 1,
          'phase': GamePhase.playersAnswering.name,
          'answersForCurrentQuestion': [0, 0, 0, 0],
          'roundOutcomeTrine': '',
          'roundOutcomeDeltakere': '',
          'timerSeconds': 60,
          'trineSliderAnswer': -1,
          'deltakerAverageAnswer': -1,
        });
        _startTimer();
      } else {
        await roomRef.update({
          'phase': GamePhase.finalLeaderboard.name,
        });
      }
    }
  }

  Future<void> answerChoice(int index) async {
    if (hasAnsweredCurrentQuestion) return;
    hasAnsweredCurrentQuestion = true;
    notifyListeners(); // Uppdater lokalt raskt

    await roomRef.collection('answers').doc(currentUserName).set({
      'answer': index,
      'questionIndex': currentQuestionIndex,
    });

    final room = await roomRef.get();
    if (room.exists) {
      final data = room.data() as Map<String, dynamic>;
      List<int> currentAnswers = List<int>.from(data['answersForCurrentQuestion'] ?? [0, 0, 0, 0]);
      if (index < currentAnswers.length) {
        currentAnswers[index]++;
        await roomRef.update({'answersForCurrentQuestion': currentAnswers});
      }
    }
  }
  
  Future<void> answerSlider(double value) async {
    if (hasAnsweredCurrentQuestion) return;
    hasAnsweredCurrentQuestion = true;
    notifyListeners();

    await roomRef.collection('answers').doc(currentUserName).set({
      'answer': value,
      'questionIndex': currentQuestionIndex,
    });

    // Lagre Trines svar separat for avsløringen
    if (currentRole == UserRole.trine) {
      await roomRef.update({'trineSliderAnswer': value});
    }
  }

  Future<void> _calculateRoundPoints() async {
    final question = dummyQuestions[currentQuestionIndex];
    List<String> deltakere = joinedUsers.where((u) => u.toLowerCase() != 'trine' && u.toLowerCase() != 'admin').toList();
    
    final answersSnap = await roomRef.collection('answers').where('questionIndex', isEqualTo: currentQuestionIndex).get();
    Map<String, dynamic> playerAnswers = {};
    for (var doc in answersSnap.docs) {
       playerAnswers[doc.id] = doc.data()['answer'];
    }
    
    int roundDeltakerP = 0;
    int roundTrineP = 0;

    String rOutTrine = '';
    String rOutDeltaker = '';

    if (question.type == QuestionType.choice) {
       int correctCount = 0;
       int totalAnswers = 0;
       
       for (var d in deltakere) {
         if (playerAnswers.containsKey(d)) {
           totalAnswers++;
           if (playerAnswers[d] == question.correctOptionIndex) correctCount++;
         }
       }
       
       double pctCorrect = totalAnswers == 0 ? 0 : (correctCount / totalAnswers);
       bool trineCorrect = playerAnswers['Trine'] == question.correctOptionIndex;
       
       if (pctCorrect > 0.5) {
         roundDeltakerP += 1;
         if (!trineCorrect) roundDeltakerP += 1;
       }
       
       if (trineCorrect) {
          if (pctCorrect > 0.5) {
             roundTrineP += 1;
             if (pctCorrect >= 0.75) roundTrineP += 1;
          }
       }
       
       rOutTrine = trineCorrect ? 'Trine svarte Riktig! (+$roundTrineP poeng)' : 'Trine svarte Feil. (0 poeng)';
       rOutDeltaker = '${(pctCorrect*100).toStringAsFixed(0)}% av deltakerne svarte riktig. (+$roundDeltakerP poeng)';

    } else {
       double correctNum = question.correctNumber;
       double trineGuess = playerAnswers.containsKey('Trine') ? (playerAnswers['Trine'] as double) : double.infinity;
       double trineDiff = (trineGuess - correctNum).abs();
       
       // Beregn GJENNOMSNITTET av deltakernes svar
       double sumDeltakere = 0;
       int antallDeltakere = 0;
       for (var d in deltakere) {
         if (playerAnswers.containsKey(d)) {
           sumDeltakere += double.parse(playerAnswers[d].toString());
           antallDeltakere++;
         }
       }
       double deltakerAverage = antallDeltakere > 0 ? sumDeltakere / antallDeltakere : double.infinity;
       double deltakerDiff = deltakerAverage != double.infinity ? (deltakerAverage - correctNum).abs() : double.infinity;
       
       // Lagre til Firestore for avsløringen
       if (deltakerAverage != double.infinity) {
         await roomRef.update({'deltakerAverageAnswer': deltakerAverage});
       }
       
       if (trineGuess == double.infinity && deltakerAverage == double.infinity) {
          rOutTrine = 'Ingen svarte!';
          rOutDeltaker = 'Ingen svarte!';
       } else if (trineDiff <= deltakerDiff) {
          roundTrineP += 1;
          rOutTrine = 'Trine var nærmest! (Gjettet ${trineGuess.toStringAsFixed(0)}) → +1 poeng';
          rOutDeltaker = deltakerAverage != double.infinity 
              ? 'Snitt deltakere: ${deltakerAverage.toStringAsFixed(1)} (Diff: ${deltakerDiff.toStringAsFixed(1)})'
              : 'Ingen deltakere svarte.';
       } else {
          roundDeltakerP += 1;
          rOutTrine = trineGuess != double.infinity 
              ? 'Deltakerne vant! Trine bommet med ${trineDiff.toStringAsFixed(0)}'
              : 'Trine svarte ikke.';
          rOutDeltaker = 'Snitt deltakere: ${deltakerAverage.toStringAsFixed(1)} – Nærmest! → +1 poeng';
       }
    }
    
    await roomRef.update({
      'totalTrinePoints': FieldValue.increment(roundTrineP),
      'totalDeltakerPoints': FieldValue.increment(roundDeltakerP),
      'roundOutcomeTrine': rOutTrine,
      'roundOutcomeDeltakere': rOutDeltaker,
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timerSeconds > 0) {
        timerSeconds--;
        // Only Admin updates the timer in Firestore to keep sync centralized
        if (currentRole == UserRole.admin) {
           roomRef.update({'timerSeconds': timerSeconds});
        }
      } else {
        _stopTimer();
        if (currentPhase == GamePhase.playersAnswering && currentRole == UserRole.admin) {
           nextPhase(); 
        }
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  Future<void> resetQuiz() async {
    if (currentRole != UserRole.admin) return;
    
    // Tilbakestill hoveddokumentet
    await roomRef.update({
      'phase': GamePhase.waitingRoom.name,
      'currentQuestionIndex': 0,
      'totalTrinePoints': 0,
      'totalDeltakerPoints': 0,
      'answersForCurrentQuestion': [0, 0, 0, 0],
      'roundOutcomeTrine': '',
      'roundOutcomeDeltakere': '',
      'timerSeconds': 60,
      'trineSliderAnswer': -1,
      'deltakerAverageAnswer': -1,
    });

    // Slett alle svar fra undersamlingen
    final answers = await roomRef.collection('answers').get();
    final batch = db.batch();
    for (var doc in answers.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    
    notifyListeners();
  }
}
