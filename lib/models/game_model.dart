import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'game_model.g.dart';

/// Player colors
enum PlayerColor { white, black }

/// Game modes
enum GameMode { singlePlayer, twoPlayerLocal, twoPlayerOnline }

/// Difficulty levels
enum DifficultyLevel { easy, normal, hard }

/// Game state
enum GameState { menu, rolling, playing, gameOver, pausing }

@JsonSerializable()
class GameModel with ChangeNotifier {
  // Board: 24 points (0-23), positive = white pieces, negative = black pieces
  List<int> piecePositions = List.filled(24, 0);
  
  // Current player to move
  PlayerColor currentPlayer = PlayerColor.white;
  
  // Game mode
  GameMode currentMode = GameMode.twoPlayerLocal;
  
  // Difficulty (for single player)
  DifficultyLevel difficulty = DifficultyLevel.normal;
  
  // Dice values
  List<int> diceValues = [0, 0];
  
  // Doubling cube
  int doublingCube = 1;
  bool hasDouble = false;
  
  // Game state
  GameState gameState = GameState.menu;
  
  // Game over
  bool gameOverFlag = false;
  PlayerColor? winner;
  
  // Bars (pieces waiting to re-enter)
  int[] bars = [0, 0]; // bars[0] = white on bar, bars[1] = black on bar
  
  // Move history for undo
  List<Map<String, dynamic>> moveHistory = [];
  
  // Game statistics
  int moveCount = 0;
  int rollsCount = 0;
  
  // Initialize new game with Iranian Backgammon starting position
  GameModel() {
    _initIranianPosition();
  }
  
  /// Initialize standard Iranian Backgammon position
  /// Setup: 
  /// - Point 1 (index 0): 2 black pieces
  /// - Point 6 (index 5): 5 white pieces  
  /// - Point 8 (index 7): 3 white pieces
  /// - Point 13 (index 12): 5 black pieces
  /// - Point 17 (index 16): 3 black pieces
  /// - Point 19 (index 18): 5 white pieces
  /// - Point 24 (index 23): 2 white pieces
  void _initIranianPosition() {
    // Clear board
    for (int i = 0; i < 24; i++) {
      piecePositions[i] = 0;
    }
    
    // White pieces (positive counts)
    piecePositions[5] = 5;   // Point 6: 5 white
    piecePositions[7] = 3;   // Point 8: 3 white
    piecePositions[12] = 5;  // Point 13: 5 white
    piecePositions[23] = 2;  // Point 24: 2 white
    
    // Black pieces (negative counts)
    piecePositions[0] = -2;  // Point 1: 2 black
    piecePositions[11] = -5; // Point 12: 5 black
    piecePositions[16] = -3; // Point 17: 3 black
    piecePositions[18] = -5; // Point 19: 5 black
    
    // Initialize bars
    bars = [0, 0];
    
    // Set starting player
    currentPlayer = PlayerColor.white;
    gameState = GameState.rolling;
    moveCount = 0;
    moveHistory.clear();
  }
  
  /// Check if moving to a point hits an opponent piece
  bool _isHit(PlayerColor player, int targetPoint) {
    if (targetPoint < 0 || targetPoint > 23) return false;
    int opponentPieces = getPiecesAtPoint(targetPoint, 
      player == PlayerColor.white ? PlayerColor.black : PlayerColor.white);
    // Hit if exactly 1 opponent piece (can be landed on)
    return opponentPieces == 1;
  }

  /// Get the number of pieces at a given point for the current player
  int getPiecesAtPoint(int point, PlayerColor player) {
    if (point < 0 || point > 23) return 0;
    int pieces = piecePositions[point];
    if (player == PlayerColor.white) {
      return pieces > 0 ? pieces : 0;
    } else {
      return pieces < 0 ? -pieces : 0;
    }
  }
  
  /// Check if a point is open (has less than 2 opponent pieces)
  bool isPointOpen(int point, PlayerColor player) {
    if (point < 0 || point > 23) return false;
    int opponentPieces = getPiecesAtPoint(point, player == PlayerColor.white ? PlayerColor.black : PlayerColor.white);
    return opponentPieces <= 1; // Open if 0 or 1 opponent piece
  }
  
  /// Check if point is closed (has 2+ opponent pieces)
  bool isPointClosed(int point, PlayerColor player) {
    return !isPointOpen(point, player);
  }
  
  /// Check if player can bear off (all pieces in home board)
  bool canBearOff(PlayerColor player) {
    int homeStart = player == PlayerColor.white ? 0 : 18;
    for (int i = homeStart; i < 24; i++) {
      if (getPiecesAtPoint(i, player) == 0) continue;
      // Check if any pieces are outside home board
      for (int j = homeStart; j < i; j++) {
        if (getPiecesAtPoint(j, player) > 0) return false;
      }
    }
    return true;
  }
  
  /// Roll the dice
  void rollDice() {
    // Generate random dice values (1-6)
    diceValues = [
      _randomInt(1, 6),
      _randomInt(1, 6),
    ];
    rollsCount++;
    notifyListeners();
  }
  
  int _randomInt(int min, int max) {
    return min + (dart.math.Random().nextDouble() * (max - min + 1)).floor();
  }
  
  /// Move a piece from source to destination
  bool movePiece(int from, int to) {
    if (from < 0 || from > 23 || to < 0 || to > 23) return false;
    
    int pieces = piecePositions[from];
    
    // Check there are pieces at source
    if (currentPlayer == PlayerColor.white && pieces <= 0) return false;
    if (currentPlayer == PlayerColor.black && pieces >= 0) return false;
    
    // Check how many pieces at source
    int whitePieces = pieces > 0 ? pieces : 0;
    int blackPieces = pieces < 0 ? -pieces : 0;
    int myPieces = currentPlayer == PlayerColor.white ? whitePieces : blackPieces;
    
    if (myPieces <= 0) return false;
    
    // Move one piece
    piecePositions[from] = pieces + (currentPlayer == PlayerColor.white ? -1 : 1);
    piecePositions[to] = (piecePositions[to] ?? 0) + (currentPlayer == PlayerColor.white ? 1 : -1);
    
    // Update bars if moving from bar
    if (from == -1) { // From bar
      bars[currentPlayer == PlayerColor.white ? 0 : 1]--;
    }
    
    // Check if we hit a single opponent piece (send to bar)
    // Note: piecePositions is List<int> not List<int>?, so ?? not needed
    if (_isHit(currentPlayer, to)) {
      // Hit! Send opponent piece to bar
      bars[currentPlayer == PlayerColor.white ? 1 : 0]++;
      piecePositions[to] = 0;
    }
    
    moveHistory.add({
      'from': from,
      'to': to,
      'player': currentPlayer == PlayerColor.white ? 'white' : 'black',
      'dice1': diceValues[0],
      'dice2': diceValues[1],
    });
    
    moveCount++;
    notifyListeners();
    return true;
  }
  
  /// Check if a move is valid according to dice values
  bool isValidMove(int from, int to) {
    if (from < 0 || from > 23 || to < 0 || to > 23) return false;
    
    int distance = (_getDistance(from, to, currentPlayer) % 24);
    
    // Check if distance matches dice
    for (int dice : diceValues) {
      if (distance == dice || distance == 24 - dice) return true;
    }
    return false;
  }
  
  int _getDistance(int from, int to, PlayerColor player) {
    // Calculate distance based on player direction
    if (player == PlayerColor.white) {
      // White moves from higher to lower indices (toward home)
      return (from - to).abs();
    } else {
      // Black moves from lower to higher indices (toward home)
      return (to - from).abs();
    }
  }
  
  /// Check if player must move (force move rule)
  bool mustMove(List<int> availableMoves) {
    // If there are legal moves, player must make one
    // If no legal moves, player loses turn
    return availableMoves.isNotEmpty; // If there are moves, must move
  }
  
  /// Get all legal moves for current player
  List<Map<String, dynamic>> getLegalMoves() {
    List<Map<String, dynamic>> moves = [];
    
    for (int from = 0; from < 24; from++) {
      int piecesAt = piecePositions[from];
      
      // Check if there are current player's pieces at this point
      bool hasMyPieces = currentPlayer == PlayerColor.white && piecesAt > 0 ||
                       currentPlayer == PlayerColor.black && piecesAt < 0;
        
      if (!hasMyPieces) continue;
      
      // Check if point is not closed (has 2+ of opponent's pieces)
      if (isPointClosed(from, currentPlayer)) continue;
      
      // Try moving with each die
      for (int i = 0; i < diceValues.length; i++) {
        int dice = diceValues[i];
        int to = _calculateTarget(from, dice, currentPlayer);
        
        if (to != -1 && isPointOpen(to, currentPlayer)) {
          moves.add({
            'from': from,
            'to': to,
            'dice': dice,
          });
        }
      }
    }
    
    // Also handle bar moves
    // ... bar handling code
    
    return moves;
  }
  
  /// Calculate target point for a move
  int _calculateTarget(int from, int dice, PlayerColor player) {
    if (player == PlayerColor.white) {
      // White moves toward lower indices (home)
      int target = from - dice;
      if (target < 0) {
        // Bearing off - if all pieces in home board
        if (canBearOff(currentPlayer)) {
          return target; // Negative means borne off
        }
        return -1; // Can't move
      }
      return target;
    } else {
      // Black moves toward higher indices (home)
      int target = from + dice;
      if (target > 23) {
        // Bearing off
        if (canBearOff(currentPlayer)) {
          return target;
        }
        return -1;
      }
      return target;
    }
  }
  
  /// Check if game is over
  bool checkGameOver() {
    // Check if current player has no legal moves
    List<Map<String, dynamic>> legal = getLegalMoves();
    if (legal.isEmpty) {
      // Player cannot move - check if they have pieces on bar
      if (bars[currentPlayer == PlayerColor.white ? 0 : 1] > 0) {
        // Must re-enter from bar first
        return false;
      }
      // No moves available - player loses turn
      gameOverFlag = true;
      winner = currentPlayer == PlayerColor.white ? PlayerColor.black : PlayerColor.white;
      return true;
    }
    return false;
  }
  
  /// Check for gammon/backgammon
  String checkWinType() {
    if (!gameOverFlag) return 'ongoing';
    
    // Check winning player
    PlayerColor winningPlayer = this.winner!;
    PlayerColor losingPlayer = winningPlayer == PlayerColor.white ? PlayerColor.black : PlayerColor.white;
    
    // Check if losing player has pieces in winning player's home board
    // White's home: points 1-6 (indices 0-5)
    // Black's home: points 19-24 (indices 18-23)
    int whiteHomeStart = 0;
    int whiteHomeEnd = 5;
    int blackHomeStart = 18;
    int blackHomeEnd = 23;
    
    // Check if losing player has pieces in winning player's home
    if (winningPlayer == PlayerColor.white) {
      // White won - check if black has pieces in white's home (points 1-6)
      for (int i = whiteHomeStart; i <= whiteHomeEnd; i++) {
        int pieces = getPiecesAtPoint(i, losingPlayer);
        if (pieces > 0) return 'Backgammon'; // Opponent has pieces in home
      }
    } else {
      // Black won - check if white has pieces in black's home (points 19-24)
      for (int i = blackHomeStart; i <= blackHomeEnd; i++) {
        int pieces = getPiecesAtPoint(i, losingPlayer);
        if (pieces > 0) return 'Backgammon'; // Opponent has pieces in home
      }
    }
    
    // Check gammon: opponent has not borne off any pieces
    // Simple win: opponent has borne off some pieces
    int borneOffByLoser = 0;
    if (winningPlayer == PlayerColor.white) {
      // White bear off is points 0-5
      for (int i = whiteHomeStart; i <= whiteHomeEnd; i++) {
        borneOffByLoser += getPiecesAtPoint(i, losingPlayer);
      }
    } else {
      // Black bear off is points 18-23
      for (int i = blackHomeStart; i <= blackHomeEnd; i++) {
        borneOffByLoser += getPiecesAtPoint(i, losingPlayer);
      }
    }
    
    if (borneOffByLoser == 0) {
      return 'Gammon'; // Opponent has not borne off any pieces
    }
    
    return 'Simple Win'; // Opponent has borne off some pieces
  }
  
  // Save game locally
  void saveGame(Box box) {
    box.put('gameModel', this);
  }
  
  /// Load game from local storage
  static GameModel loadGame(Box box) {
    return box.get('gameModel') ?? GameModel();
  }
  
  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    notifyListeners();
  }
  
  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
  }
}