import 'package:flutter/material.dart';
import '../controllers/game_controller.dart';
import '../widgets/gradient_bg.dart';

class ResultScreen extends StatelessWidget {
  final GameController controller;

  const ResultScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    int trinesScore = controller.totalTrinePoints;
    int deltakerScore = controller.totalDeltakerPoints;
    
    bool didTrineWin = trinesScore > deltakerScore;
    bool isDraw = trinesScore == deltakerScore;

    return GradientBackground(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Resultat! 🏆', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isDraw ? 'Det ble uavgjort! 🤝' : didTrineWin ? '👑 Trine Vant Quizen! 👑' : '🎉 Deltakerne Vant Quizen! 🎉',
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.yellowAccent),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  
                  // Score Cards
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildScoreCard('Trines Poeng', trinesScore, (didTrineWin || isDraw) ? Colors.greenAccent : Colors.white24),
                      const SizedBox(width: 16),
                      const Text('VS', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white54)),
                      const SizedBox(width: 16),
                      _buildScoreCard('Deltakernes Poeng', deltakerScore, (!didTrineWin || isDraw) ? Colors.greenAccent : Colors.white24),
                    ],
                  ),
                  
                  const SizedBox(height: 64),
                  if (controller.currentRole == UserRole.admin)
                     ElevatedButton.icon(
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.white,
                         foregroundColor: Colors.deepPurple,
                         padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                       ),
                       icon: const Icon(Icons.refresh),
                       label: const Text('Start på nytt (Admin)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                       onPressed: () {
                          // Implementer reset-logikk her, eller be systemet reloade siden
                       },
                     ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(String title, int score, Color borderColor) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 18, color: Colors.white70), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
            '$score',
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
