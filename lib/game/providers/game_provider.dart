import 'package:flutter/foundation.dart';
import '../models/game_session.dart';
import '../../services/database_service.dart';

class GameProvider with ChangeNotifier {
  final DatabaseService _dbService;
  
  GameSession? _currentSession;

  GameProvider(this._dbService) {
    _loadSession();
  }

  GameSession get currentSession => _currentSession ?? GameSession(id: 'default');

  void _loadSession() {
    final sessions = _dbService.getAllGameSessions();
    if (sessions.isNotEmpty) {
      _currentSession = sessions.first;
    } else {
      _currentSession = GameSession(id: 'default');
      _dbService.saveGameSession(_currentSession!);
    }
    notifyListeners();
  }

  Future<void> updateHighScore(int newScore) async {
    if (_currentSession == null) return;
    if (newScore > _currentSession!.highScore) {
      _currentSession = _currentSession!.copyWith(
        highScore: newScore,
        lastPlayed: DateTime.now(),
      );
      await _dbService.saveGameSession(_currentSession!);
      notifyListeners();
    }
  }

  Future<void> addCoins(int amount) async {
    if (_currentSession == null) return;
    _currentSession = _currentSession!.copyWith(
      coins: _currentSession!.coins + amount,
      lastPlayed: DateTime.now(),
    );
    await _dbService.saveGameSession(_currentSession!);
    notifyListeners();
  }
}
