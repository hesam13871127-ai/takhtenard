import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takhtenard/models/game_model.dart';

// Game model provider
final gameModelProvider = StateNotifierProvider<GameModelNotifier, GameModel>((ref) {
  return GameModelNotifier();
});

// Game model notifier
class GameModelNotifier extends StateNotifier<GameModel> {
  GameModelNotifier() : super(GameModel());

  /// Initialize a new game
  void startNewGame({GameMode mode = GameMode.twoPlayerLocal, DifficultyLevel? difficulty}) {
    state = GameModel();
    state = state.copyWith(...);
    _initGame(mode, difficulty);
  }

  /// Initialize game with specific mode
  void _initGame(GameMode mode, DifficultyLevel? diff) {
    currentMode = mode;
    difficulty = diff ?? DifficultyLevel.normal;
    // Set up initial position based on mode
    switch (mode) {
      case GameMode.singlePlayer:
        // Single player setup
        break;
      case GameMode.twoPlayerLocal:
        _initIranianPosition();
        break;
      case GameMode.twoPlayerOnline:
        // Online will use remote state
        break;
    }
  }

  /// Get current game mode
  GameMode getCurrentMode() => currentMode;

  /// Set difficulty level
  void setDifficulty(DifficultyLevel level) {
    difficulty = level;
    notifyListeners();
  }

  /// Roll dice
  void rollDice() {
    if (state.gameState == GameState.menu || state.gameState == GameState.rolling) {
      final newDice = state.diceValues.map((d) => d == 0 ? _roll() : d).toList();
      state = state.copyWith(diceValues: newDice);
      _checkTurnProgress();
    }
  }

  int _roll() => 1 + (dart.math.Random().nextDouble() * 5).floor();

  /// Check turn progress and switch players if needed
  void _checkTurnProgress() {
    // Check if current player has moves
    var legalMoves = state.getLegalMoves();
    
    if (legalMoves.isEmpty) {
      // No moves - skip turn
      _skipTurn();
      return;
    }
    
    // Player has moves - stay in playing state
    state = state.copyWith(gameState: GameState.playing);
  }

  /// Skip turn
  void skipTurn() {
    currentPlayer = currentPlayer == PlayerColor.white ? PlayerColor.black : PlayerColor.white;
    state = state.copyWith(
      currentPlayer: currentPlayer,
      gameState: GameState.rolling,
    );
    notifyListeners();
  }

/// End game
  void endGame(PlayerColor winner) {
    state = state.copyWith(
      gameOverFlag: true,
      winner: winner,
      gameState: GameState.gameOver,
    );
    notifyListeners();
  }

  /// Undo last move
  void undoMove() {
    if (state.moveHistory.isNotEmpty) {
      final lastMove = state.moveHistory.removeLast();
      // Revert piece positions
      // ... implementation needed
      notifyListeners();
    }
  }

  // Game state fields
  PlayerColor currentPlayer = PlayerColor.white;
  GameMode currentMode = GameMode.twoPlayerLocal;
  DifficultyLevel difficulty = DifficultyLevel.normal;
  int doublingCube = 1;
  bool hasDouble = false;
  int moveCount = 0;
  int rollsCount = 0;

  // CopyWith support for partial updates
  GameModel copyWith({
    List<int>? piecePositions,
    PlayerColor? currentPlayer,
    GameMode? currentMode,
    DifficultyLevel? difficulty,
    List<int>? diceValues,
    int? doublingCube,
    bool? gameOverFlag,
    PlayerColor? winner,
    List<Map<String, dynamic>>? moveHistory,
    int? moveCount,
    int? rollsCount,
    int[]? bars,
  }) {
    final newModel = GameModel()..piecePositions = piecePositions ?? this.piecePositions;
    newModel.currentPlayer = currentPlayer ?? this.currentPlayer;
    newModel.currentMode = currentMode ?? this.currentMode;
    newModel.difficulty = difficulty ?? this.difficulty;
    newModel.diceValues = diceValues ?? this.diceValues;
    newModel.doublingCube = doublingCube ?? this.doublingCube;
    newModel.hasDouble = hasDouble ?? this.hasDouble;
    newModel.gameOverFlag = gameOverFlag ?? this.gameOverFlag;
    newModel.winner = winner ?? this.winner;
    newModel.moveHistory = moveHistory ?? this.moveHistory;
    newModel.moveCount = moveCount ?? this.moveCount;
    newModel.rollsCount = rollsCount ?? this.rollsCount;
    newModel.bars = bars ?? this.bars;
    return newModel;
  }
}