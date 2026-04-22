import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/game_provider.dart';
import '../../widgets/app_drawer.dart';
import 'gameplay_screen.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final session = provider.currentSession;
    final cs = Theme.of(context).colorScheme;

    // Use a default date if lastPlayed is right now (meaning newly created)
    // For a cleaner look, we just format whatever is there.
    final lastPlayedStr = DateFormat('MMM d, y - h:mm a').format(session.lastPlayed);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Space Invaders'),
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // High Score Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(Icons.emoji_events_rounded, size: 48, color: Colors.amber.shade600),
                    const SizedBox(height: 8),
                    const Text('High Score', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '${session.highScore}',
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: cs.primary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Stats Row
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(Icons.monetization_on_rounded, size: 32, color: Colors.yellow.shade700),
                          const SizedBox(height: 8),
                          const Text('Coins', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('${session.coins}', style: const TextStyle(fontSize: 20)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(Icons.history_rounded, size: 32, color: cs.secondary),
                          const SizedBox(height: 8),
                          const Text('Last Played', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            lastPlayedStr,
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const Spacer(),

            // Play Button
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GameplayScreen()),
                );
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 32),
              label: const Text('PLAY', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
