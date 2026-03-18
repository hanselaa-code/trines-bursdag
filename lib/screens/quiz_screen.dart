import 'package:flutter/material.dart';
import '../controllers/game_controller.dart';
import '../models/question.dart';
import '../data/dummy_questions.dart';
import '../widgets/gradient_bg.dart';

class QuizScreen extends StatefulWidget {
  final GameController controller;

  const QuizScreen({super.key, required this.controller});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  double _sliderValue = 0;
  bool _sliderInitialized = false;

  @override
  Widget build(BuildContext context) {
    final phase = widget.controller.currentPhase;
    final role = widget.controller.currentRole;
    final question = dummyQuestions[widget.controller.currentQuestionIndex];

    if (question.type == QuestionType.slider && !_sliderInitialized) {
      _sliderValue = question.minSlider;
      _sliderInitialized = true;
    } else if (question.type == QuestionType.choice) {
      _sliderInitialized = false;
    }

    bool canIAnswer = false;
    String statusText = '';
    Color statusColor = Colors.white;

    if (phase == GamePhase.playersAnswering) {
      if (role == UserRole.player) {
         canIAnswer = true;
         statusText = 'Din tur! Se på storskjermen.';
         statusColor = Colors.yellowAccent;
      } else if (role == UserRole.trine) {
         statusText = 'Deltakerne svarer... Vent litt! ⏳';
         statusColor = Colors.white70;
      } else {
         statusText = 'Deltakerne svarer.';
      }
    } else if (phase == GamePhase.trineAnswering) {
      if (role == UserRole.trine) {
         canIAnswer = true;
         statusText = 'Nå er det din tur, Trine! 👑';
         statusColor = Colors.yellowAccent;
      } else {
         statusText = 'Trine tenker... 🤔';
         statusColor = Colors.white70;
      }
    } else if (phase == GamePhase.showingResult) {
      statusText = 'Fasit vises på storskjerm! 🎉';
      statusColor = Colors.greenAccent;
    }

    if (widget.controller.hasAnsweredCurrentQuestion && phase != GamePhase.showingResult) {
      return GradientBackground(
        child: Scaffold(
          body: Center(
            child: const Text('Svar registrert! Venter på andre...', style: TextStyle(fontSize: 28, color: Colors.yellowAccent, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ),
        ),
      );
    }
    
    if (phase == GamePhase.showingResult) {
      return GradientBackground(
        child: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Fasit!', style: TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                const Text('Se storskjerm for resultat.', style: TextStyle(fontSize: 22, color: Colors.white70)),
              ],
            ),
          ),
        ),
      );
    }
    
    return GradientBackground(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: question.type == QuestionType.choice 
              ? _buildChoiceButtons(canIAnswer)
              : _buildSliderInput(canIAnswer, question),
        ),
      ),
    );
  }

  Widget _buildChoiceButtons(bool canIAnswer) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              _buildBigButton(0, const Color(0xFFE21B3C), canIAnswer), 
              const SizedBox(width: 8),
              _buildBigButton(1, const Color(0xFF1368CE), canIAnswer), 
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            children: [
              _buildBigButton(2, const Color(0xFFD89E00), canIAnswer), 
              const SizedBox(width: 8),
              _buildBigButton(3, const Color(0xFF26890C), canIAnswer), 
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSliderInput(bool canIAnswer, Question question) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _sliderValue.toStringAsFixed(0),
          style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.deepPurpleAccent,
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.yellowAccent,
            trackHeight: 20,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 20),
          ),
          child: Slider(
            value: _sliderValue,
            min: question.minSlider,
            max: question.maxSlider,
            onChanged: canIAnswer ? (val) {
              setState(() {
                _sliderValue = val;
              });
            } : null,
          ),
        ),
        const SizedBox(height: 48),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 24),
              backgroundColor: Colors.greenAccent.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: canIAnswer ? () {
              widget.controller.answerSlider(_sliderValue);
            } : null,
            child: const Text('Send inn Svar', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
        )
      ],
    );
  }

  Widget _buildBigButton(int index, Color color, bool canIAnswer) {
    IconData getIcon(int idx) {
      switch(idx) {
        case 0: return Icons.change_history; 
        case 1: return Icons.crop_square;    
        case 2: return Icons.circle;         
        case 3: return Icons.square_foot;    
        default: return Icons.star;
      }
    }

    return Expanded(
      child: InkWell(
        onTap: (canIAnswer && !widget.controller.hasAnsweredCurrentQuestion) 
            ? () {
                widget.controller.answerChoice(index);
              }
            : null,
        child: Opacity(
          opacity: canIAnswer ? 1.0 : 0.5,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))],
            ),
            child: Center(
              child: Icon(getIcon(index), size: 100, color: Colors.white70),
            ),
          ),
        ),
      ),
    );
  }
}
