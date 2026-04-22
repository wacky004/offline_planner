class GameSession {
  String id;
  int highScore;
  int coins;
  Map<String, bool> unlockedItems;
  DateTime lastPlayed;

  GameSession({
    required this.id,
    this.highScore = 0,
    this.coins = 0,
    Map<String, bool>? unlockedItems,
    DateTime? lastPlayed,
  })  : unlockedItems = unlockedItems ?? {},
        lastPlayed = lastPlayed ?? DateTime.now();

  GameSession copyWith({
    String? id,
    int? highScore,
    int? coins,
    Map<String, bool>? unlockedItems,
    DateTime? lastPlayed,
  }) {
    return GameSession(
      id: id ?? this.id,
      highScore: highScore ?? this.highScore,
      coins: coins ?? this.coins,
      unlockedItems: unlockedItems ?? this.unlockedItems,
      lastPlayed: lastPlayed ?? this.lastPlayed,
    );
  }
}
