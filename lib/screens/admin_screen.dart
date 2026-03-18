import 'package:flutter/material.dart';
import 'package:trines_bursdag/controllers/game_controller.dart';
import 'package:trines_bursdag/models/question.dart';
import 'package:trines_bursdag/data/dummy_questions.dart';
import '../widgets/gradient_bg.dart';

class AdminScreen extends StatelessWidget {
  final GameController controller;

  const AdminScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final phase = controller.currentPhase;
    // Forhindre crash hvis index går out of bounds ved final phase
    final question = (controller.currentQuestionIndex < dummyQuestions.length) 
        ? dummyQuestions[controller.currentQuestionIndex] 
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
                      Text('Tid: ${controller.timerSeconds}s', style: const TextStyle(fontSize: 20, color: Colors.white)),
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
                    onPressed: controller.startQuiz,
                  ),
                 ),
                 const SizedBox(height: 100),
              ],
                
              if (phase != GamePhase.waitingRoom) ...[
                Text(
                  question.text, 
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
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

                // Hvis det er resultatfase, vis rundens vinnere
                if (phase == GamePhase.showingResult) ...[
                   Container(
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
                         Text(controller.roundOutcomeTrine, style: const TextStyle(fontSize: 24, color: Colors.yellow)),
                         const SizedBox(height: 8),
                         Text(controller.roundOutcomeDeltakere, style: const TextStyle(fontSize: 24, color: Colors.greenAccent)),
                         if (question.type == QuestionType.slider) ...[
                           const SizedBox(height: 16),
                           Text('Fasit: ${question.correctNumber.toStringAsFixed(0)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                         ]
                       ],
                     ),
                   ),
                   const SizedBox(height: 24),
                   if (question.type == QuestionType.choice) _buildGraph(controller, question),
                ]
                else ...[
                   if (question.type == QuestionType.choice) _buildOptionsGrid(question),
                   if (question.type == QuestionType.slider) 
                     Container(
                       padding: const EdgeInsets.all(40),
                       decoration: BoxDecoration(
                         color: Colors.white12,
                         borderRadius: BorderRadius.circular(24)
                       ),
                       child: const Center(
                         child: Text('Gjett tallet på mobilen din!', style: TextStyle(fontSize: 32, fontStyle: FontStyle.italic, color: Colors.white70)),
                       )
                     )
                ],

                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                      ),
                      onPressed: controller.nextPhase,
                      icon: const Icon(Icons.skip_next),
                      label: Text(
                        phase == GamePhase.playersAnswering
                            ? 'Avbryt Tidtaker (Gå til Trine)'
                            : phase == GamePhase.trineAnswering
                                ? 'Vis Fasit & Grafer'
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

  Widget _buildFinalScore() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Quizen er over!', style: TextStyle(fontSize: 48, color: Colors.white)),
          const SizedBox(height: 24),
          ElevatedButton(
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(24)),
              onPressed: () => controller.nextPhase(), 
              child: const Text('Gå til Poengoversikt', style: TextStyle(fontSize: 24)),
          )
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
      shrinkWrap: true, // Forhindrer overflow i ScrollView
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
          switch(idx) {
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
                  textAlign: TextAlign.left,
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
