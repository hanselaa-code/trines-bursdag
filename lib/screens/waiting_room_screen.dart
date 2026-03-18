import 'package:flutter/material.dart';
import '../controllers/game_controller.dart';
import '../widgets/gradient_bg.dart';

class WaitingRoomScreen extends StatelessWidget {
  final GameController controller;

  const WaitingRoomScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Venterom', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.people_alt, size: 80, color: Colors.white70),
              const SizedBox(height: 16),
              const Text(
                'Er dere klare? 🤩',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Venter på at Spilleder starter quizen...',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text(
                    'Deltakere',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                   Container(
                     padding: const EdgeInsets.all(12),
                     decoration: const BoxDecoration(
                       color: Colors.white24,
                       shape: BoxShape.circle,
                     ),
                     child: Text(
                      '${controller.joinedUsers.length}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                     ),
                   ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: controller.joinedUsers.length,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Center(
                        child: Text(
                          controller.joinedUsers[index],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
