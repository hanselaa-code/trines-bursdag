import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trines_bursdag/controllers/game_controller.dart';
import 'package:trines_bursdag/models/question.dart';
import 'package:trines_bursdag/data/dummy_questions.dart';
import '../widgets/gradient_bg.dart';

class AdminScreen extends StatefulWidget {
  final GameController controller;

  const AdminScreen({super.key, required this.controller});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  // Slider-avsløring: trinn 0=Trine, 1=Fasit, 2=Deltakere teller opp
  int _revealStep = 0;
  double _animatedDeltakerValue = 0;
  Timer? _countupTimer;
  String? _lastRevealedQuestionPhase;

  @override
  void didUpdateWidget(covariant AdminScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final phase = widget.controller.currentPhase;
    final idx = widget.controller.currentQuestionIndex;
    final key = '$idx-${phase.name}';
    // Tilbakestill avsløring når vi går til nytt spørsmål
    if (key != _lastRevealedQuestionPhase && phase != GamePhase.showingResult) {
      _revealStep = 0;
      _countupTimer?.cancel();
      _lastRevealedQuestionPhase = null;
    }
  }

  void _nextRevealStep(Question question) {
    if (_revealStep < 2) {
      setState(() => _revealStep++);
      if (_revealStep == 2) {
        _startCountup(question);
      }
    }
  }

  void _startCountup(Question question) {
    double target = widget.controller.deltakerAverageAnswer;
    if (target < 0) return;
    _animatedDeltakerValue = question.minSlider;
    _countupTimer?.cancel();
    double step = (target - question.minSlider).abs() / 40;
    if (step < 0.5) step = 0.5;
    _countupTimer = Timer.periodic(const Duration(milliseconds: 60), (t) {
      setState(() {
        if ((_animatedDeltakerValue - target).abs() <= step) {
          _animatedDeltakerValue = target;
          t.cancel();
        } else if (_animatedDeltakerValue < target) {
          _animatedDeltakerValue += step;
        } else {
          _animatedDeltakerValue -= step;
        }
      });
    });
  }

  @override
  void dispose() {
    _countupTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phase = widget.controller.currentPhase;
    final question = (widget.controller.currentQuestionIndex < dummyQuestions.length)
        ? dummyQuestions[widget.controller.currentQuestionIndex]
        : dummyQuestions.first;

    return GradientBackground(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard / Storskjerm', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.black45,
          elevation: 0,
        ),
        body: phase == GamePhase.finalLeaderboard
            ? _buildFinalScore()
            : _buildQuestionScreen(context, phase, question),
      ),
    );
  }

  Widget _buildQuestionScreen(BuildContext context, GamePhase phase, Question question) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - 100),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Fase-banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Fase: ${phase.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.yellowAccent)),
                    if (phase == GamePhase.playersAnswering)
                      Text('Tid: ${widget.controller.timerSeconds}s', style: const TextStyle(fontSize: 20, color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (phase == GamePhase.waitingRoom) ...[
                const SizedBox(height: 100),
                Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                      backgroundColor: Colors.greenAccent.shade700,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.play_arrow, size: 32),
                    label: const Text('Start Quiz (Alle er klare)', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    onPressed: widget.controller.startQuiz,
                  ),
                ),
                const SizedBox(height: 100),
              ],

              if (phase != GamePhase.waitingRoom) ...[
                // Spørsmålstekst
                Text(
                  question.text,
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Bilde
                if (question.imageUrl != null)
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: question.imageUrl!.startsWith('http')
                        ? Image.network(question.imageUrl!, fit: BoxFit.contain)
                        : Image.asset(question.imageUrl!, fit: BoxFit.contain),
                  ),
                const SizedBox(height: 32),

                // Resultatfase
                if (phase == GamePhase.showingResult) ...[
                  if (question.type == QuestionType.slider)
                    _buildSliderReveal(question)
                  else ...[
                    _buildResultBox(),
                    const SizedBox(height: 24),
                    _buildGraph(widget.controller, question),
                  ],
                ] else ...[
                  if (question.type == QuestionType.choice) _buildOptionsGrid(question),
                  if (question.type == QuestionType.slider)
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Text('Gjett datoen på mobilen din! 📅',
                            style: TextStyle(fontSize: 32, fontStyle: FontStyle.italic, color: Colors.white70)),
                      ),
                    ),
                ],

                const SizedBox(height: 32),
                // Neste-knapp (skjult under slider-avsløringen om vi er midt i reveal)
                if (!(phase == GamePhase.showingResult && question.type == QuestionType.slider && _revealStep < 2))
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.deepPurple,
                        ),
                        onPressed: widget.controller.nextPhase,
                        icon: const Icon(Icons.skip_next),
                        label: Text(
                          phase == GamePhase.playersAnswering
                              ? 'Avbryt Tidtaker (Gå til Trine)'
                              : phase == GamePhase.trineAnswering
                                  ? 'Vis Fasit & Start avsløring'
                                  : 'Neste Spørsmål',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- Trinnvis slider-avsløring ---
  Widget _buildSliderReveal(Question question) {
    final trine = widget.controller.trineSliderAnswer;
    final deltaker = widget.controller.deltakerAverageAnswer;
    final fasit = question.correctNumber;

    return Column(
      children: [
        // Steg 0: Trines svar
        AnimatedOpacity(
          opacity: _revealStep >= 0 ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 500),
          child: _revealCard(
            emoji: '👑',
            label: 'Trines svar',
            value: trine >= 0 ? trine.toStringAsFixed(0) : '?',
            color: Colors.purple.shade300,
          ),
        ),
        const SizedBox(height: 16),

        // Steg 1: Fasit
        AnimatedOpacity(
          opacity: _revealStep >= 1 ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 600),
          child: _revealCard(
            emoji: '✅',
            label: 'Fasit',
            value: fasit.toStringAsFixed(0),
            color: Colors.greenAccent,
          ),
        ),
        const SizedBox(height: 16),

        // Steg 2: Deltakernes gjennomsnitt (teller opp)
        AnimatedOpacity(
          opacity: _revealStep >= 2 ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 600),
          child: _revealCard(
            emoji: '🎯',
            label: 'Deltakernes snitt',
            value: _revealStep >= 2 
                ? _animatedDeltakerValue.toStringAsFixed(1) 
                : '?',
            color: Colors.orangeAccent,
          ),
        ),
        const SizedBox(height: 32),

        // Vis vinner og Neste-knapp kun etter alt er avslørt
        if (_revealStep >= 2 && _animatedDeltakerValue == deltaker) ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.yellowAccent, width: 2),
            ),
            child: Column(
              children: [
                Text(widget.controller.roundOutcomeTrine,
                    style: const TextStyle(fontSize: 22, color: Colors.yellow), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(widget.controller.roundOutcomeDeltakere,
                    style: const TextStyle(fontSize: 22, color: Colors.greenAccent), textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              backgroundColor: Colors.white,
              foregroundColor: Colors.deepPurple,
            ),
            onPressed: widget.controller.nextPhase,
            icon: const Icon(Icons.skip_next),
            label: const Text('Neste Spørsmål', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ] else if (_revealStep < 2) ...[
          // Knapp for neste avslørings-steg
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              backgroundColor: Colors.deepPurpleAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _nextRevealStep(question),
            icon: const Icon(Icons.visibility),
            label: Text(
              _revealStep == 0 ? 'Vis Fasit ➜' : 'Vis Deltakernes Svar ➜',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ],
    );
  }

  Widget _revealCard({required String emoji, required String label, required String value, required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$emoji  $label', style: TextStyle(fontSize: 24, color: color, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildResultBox() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade900.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.yellowAccent, width: 2),
      ),
      child: Column(
        children: [
          const Text('Rundens Resultat:', style: TextStyle(fontSize: 28, color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(widget.controller.roundOutcomeTrine, style: const TextStyle(fontSize: 24, color: Colors.yellow)),
          const SizedBox(height: 8),
          Text(widget.controller.roundOutcomeDeltakere, style: const TextStyle(fontSize: 24, color: Colors.greenAccent)),
        ],
      ),
    );
  }

  Widget _buildFinalScore() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Quizen er over!', style: TextStyle(fontSize: 48, color: Colors.white)),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(24)),
            onPressed: () => widget.controller.nextPhase(),
            child: const Text('Gå til Poengoversikt', style: TextStyle(fontSize: 24)),
          ),
        ],
      ),
    );
  }

  Widget _buildGraph(GameController controller, Question question) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(4, (index) {
          int count = controller.answersForCurrentQuestion[index];
          bool isCorrect = index == question.correctOptionIndex;
          Color col = _getOptionColor(index);
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('$count', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 80,
                height: 20.0 + (count * 40),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.greenAccent : col.withOpacity(0.5),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: isCorrect ? const Icon(Icons.check, color: Colors.black54, size: 40) : null,
              ),
              const SizedBox(height: 8),
              Text(question.options[index], style: const TextStyle(fontSize: 16, color: Colors.white70)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildOptionsGrid(Question question) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 5,
      ),
      itemCount: question.options.length,
      itemBuilder: (context, index) {
        IconData getIcon(int idx) {
          switch (idx) {
            case 0: return Icons.change_history;
            case 1: return Icons.crop_square;
            case 2: return Icons.circle;
            case 3: return Icons.square_foot;
            default: return Icons.star;
          }
        }
        return Container(
          decoration: BoxDecoration(
            color: _getOptionColor(index),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 4))],
          ),
          child: Row(
            children: [
              const SizedBox(width: 24),
              Icon(getIcon(index), color: Colors.white, size: 40),
              const SizedBox(width: 24),
              Expanded(
                child: Text(
                  question.options[index],
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getOptionColor(int index) {
    const optionColors = [
      Color(0xFFE21B3C),
      Color(0xFF1368CE),
      Color(0xFFD89E00),
      Color(0xFF26890C),
    ];
    return optionColors[index % 4];
  }
}
