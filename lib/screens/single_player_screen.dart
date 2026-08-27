import 'package:flutter/material.dart';
import 'package:flutter_riverpod/widget_ref.dart';
import 'package:takhtenard/models/game_model.dart';
import 'package:takhtenard/screens/home_screen.dart';

/// Single Player Screen with AI Robot
/// Features selectable difficulty (Easy / Normal / Hard) with intelligent AI
class SinglePlayerScreen extends ConsumerStatefulWidget {
  const SinglePlayerScreen({super.key});

  @override
  SinglePlayerScreenState createState() => SinglePlayerScreenState();
}

class SinglePlayerScreenState extends ConsumerState<SinglePlayerScreen>
    with SingleTickerProviderStateMixin {
  late GameModel gameModel;
  late AnimationController _controller;
  late Animation<double> _difficultyAnimation;
  String? selectedDifficulty;
  bool isThinking = false;

  @override
  void initState() {
    super.initState();
    gameModel = ref.read(gameModelProvider);
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _difficultyAnimation = Tween(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'یک نفره (م supremacy)',
          style: TextStyle(fontFamily: 'IranSans', color: Color(0xFF2C1810)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Color(0xFF2C1810),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C1810)),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFF8E1), Color(0xFFFFF3E0)],
              ),
            ),
          ),
          
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Difficulty selection
                _buildDifficultySelection(size),
                const SizedBox(height: 30),
                
                // Game status
                _buildGameInfo(size),
                const SizedBox(height: 20),
                
                // Game board
                _buildBoardPreview(size),
                const SizedBox(height: 20),
                
                // Dice and controls
                _buildDiceControls(size),
                const SizedBox(height: 30),
                
                // Buttons
                _buildButtons(size),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build difficulty selection
  Widget _buildDifficultySelection(Size size) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC9A963), width: 1),
      ),
      child: Column(
        children: [
          Text(
            ' سطوح دشواری ',
            style: TextStyle(
              fontFamily: 'IranSans',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C1810),
            ),
          ),
          const SizedBox(height: 16),
          _difficultyButton(' facile (Easy)', Colors.green, size),
          const SizedBox(height: 8),
          _difficultyButton(' معمولی (Normal)', Colors.orange, size),
          const SizedBox(height: 8),
          _difficultyButton(' سخت (Hard)', Colors.red, size),
        ],
      ),
    );
  }

  /// Build difficulty button
  Widget _difficultyButton(String label, Color color, Size size) {
    final isSelected = selectedDifficulty == label;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          selectedDifficulty = label;
          // Apply difficulty setting
          _applyDifficulty(label);
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color.withOpacity(0.3) : Color(0xFFFFF3E0),
        foregroundColor: isSelected ? color : Color(0xFF2C1810),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        minimumSize: Size(size.width * 0.4, 40),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'IranSans',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2C1810),
        ),
      ),
    );
  }

  /// Apply difficulty setting
  void _applyDifficulty(String difficulty) {
    switch (difficulty) {
      case ' facile (Easy)':
        gameModel.difficulty = DifficultyLevel.easy;
        break;
      case ' معمولی (Normal)':
        gameModel.difficulty = DifficultyLevel.normal;
        break;
      case ' سخت (Hard)':
        gameModel.difficulty = DifficultyLevel.hard;
        break;
    }
  }

  /// Build game info
  Widget _buildGameInfo(Size size) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFC9A963), width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'بileshwarz (اب.white)',
                style: const TextStyle(fontFamily: 'IranSans', fontSize: 12, color: Color(0xFF6D4A28)),
              ),
              Text(
                'بileshwarz (ک u)',
                style: const TextStyle(fontFamily: 'IranSans', fontSize: 12, color: Color(0xFF6D4A28)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${gameModel.getPiecesAtPoint(0, PlayerColor.white)} borne off',
                style: TextStyle(fontFamily: 'IranSans', fontSize: 11, color: Color(0xFF4A3226)),
              ),
              Text(
                '${gameModel.getPiecesAtPoint(0, PlayerColor.black)} borne off',
                style: TextStyle(fontFamily: 'IranSans', fontSize: 11, color: Color(0xFF4A3226)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build board preview
  Widget _buildBoardPreview(Size size) {
    return Container(
      width: size.width * 0.8,
      height: size.width * 0.6,
      decoration: BoxDecoration(
        color: Colors.brown.shade100,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Center(
        child: Icon(
          Icons.insert_drive_time,
          size: 60,
          color: Color(0xFFC9A963),
        ),
      ),
    );
  }

  /// Build dice controls
  Widget _buildDiceControls(Size size) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFC9A963), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildDiePreview(gameModel.diceValues[0], size),
          const SizedBox(width: 12),
          _buildDiePreview(gameModel.diceValues[1], size),
        ],
      ),
    );
  }

  /// Build die preview
  Widget _buildDiePreview(int value, Size size) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFC9A963),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          value.toString(),
          style: const TextStyle(
            fontFamily: 'IranSans',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C1810),
          ),
        ),
      ),
    );
  }

  /// Build action buttons
  Widget _buildButtons(Size size) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Roll dice button
        ElevatedButton(
          onPressed: isThinking ? null : _handleRollDice,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC9A963),
            foregroundColor: Colors.black,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: Size(size.width * 0.4, 45),
          ),
          child: isThinking
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : const Text(
                  'Zدن نرد',
                  style: TextStyle(
                    fontFamily: 'IranSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C1810),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        
        // New game button
        OutlinedButton(
          onPressed: () {
            setState(() {
              gameModel = GameModel(); // Reset game
              selectedDifficulty = null;
            });
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFC9A963),
            side: const BorderSide(color: Color(0xFFC9A963), width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: Size(size.width * 0.4, 40),
          ),
          child: const Text(
            'بازی جدید',
            style: TextStyle(
              fontFamily: 'IranSans',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C1810),
            ),
          ),
        ),
      ],
    );
  }

  /// Handle roll dice (with AI thinking)
  void _handleRollDice() {
    if (isThinking) return;
    
    // Roll the dice
    gameModel.rollDice();
    
    // Check if it's white's turn (human) or black's turn (AI)
    if (gameModel.currentPlayer == PlayerColor.white) {
      // Human's turn - just enable moves
      setState(() {
        gameModel.gameState = GameState.playing;
      });
    } else {
      // AI's turn - start thinking
      isThinking = true;
      notifyListeners();
      
      // Simulate AI thinking time
      Future.delayed(const Duration(seconds: 1), () {
        _aiTurn();
      });
    }
  }

  /// AI turn - make a move based on difficulty
  void _aiTurn() {
    // Get legal moves
    var legalMoves = gameModel.getLegalMoves();
    
    if (legalMoves.isEmpty) {
      // No moves - skip turn
      isThinking = false;
      setState(() {
        gameModel.skipTurn();
      });
      notifyListeners();
      return;
    }
    
    // Select move based on difficulty
    Map<String, dynamic> selectedMove;
    
    switch (gameModel.difficulty) {
      case DifficultyLevel.easy:
        selectedMove = _easyAI(legalMoves);
        break;
      case DifficultyLevel.normal:
        selectedMove = _normalAI(legalMoves);
        break;
      case DifficultyLevel.hard:
        selectedMove = _hardAI(legalMoves);
        break;
    }
    
    // Execute AI move
    if (selectedMove != null) {
      gameModel.movePiece(
        selectedMove['from'],
        selectedMove['to'],
      );
    }
    
    // Check game over
    if (gameModel.checkGameOver()) {
      _endSinglePlayerGame(gameModel.winner!);
    } else {
      isThinking = false;
      setState(() {
        gameModel.gameState = GameState.rolling;
      });
      notifyListeners();
    }
  }

  /// Easy AI - random legal move
  Map<String, dynamic> _easyAI(List<Map<String, dynamic>> legalMoves) {
    if (legalMoves.isEmpty) return {'from': -1, 'to': -1};
    final rand = dart.math.Random();
    final idx = rand.nextInt(legalMoves.length);
    return legalMoves[idx];
  }

  /// Normal AI - prefer hitting and blocking
  Map<String, dynamic> _normalAI(List<Map<String, dynamic>> legalMoves) {
    // Priority: 1) Hit opponent piece, 2) Move to open point, 3) Random
    for (var move in legalMoves) {
      if (_isHittingMove(move)) return move;
    }
    return legalMoves.isNotEmpty ? legalMoves[0] : {'from': -1, 'to': -1};
  }

  /// Check if move is a hit
  bool _isHittingMove(Map<String, dynamic> move) {
    // A hit move sends opponent piece to bar
    final from = move['from'];
    final to = move['to'];
    
    if (from == -1 || to == -1) return false;
    
    int piecesAtTarget = gameModel.getPiecesAtPoint(to, 
      gameModel.currentPlayer == PlayerColor.white ? PlayerColor.black : PlayerColor.white);
    
    return piecesAtTarget == 1; // Hit if exactly 1 opponent piece
  }

  /// Hard AI - smart move selection
  Map<String, dynamic> _hardAI(List<Map<String, dynamic>> legalMoves) {
    // Comprehensive AI: evaluate moves based on board position
    double bestScore = -1000;
    Map<String, dynamic>? bestMove;
    
    for (var move in legalMoves) {
      double score = _evaluateMove(move);
      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }
    
    return bestMove ?? (legalMoves.isNotEmpty ? legalMoves[0] : {'from': -1, 'to': -1});
  }

  /// Evaluate a move for AI
  double _evaluateMove(Map<String, dynamic> move) {
    double score = 0;
    final from = move['from'];
    final to = move['to'];
    final dice = move['dice'];
    
    // Prioritize hitting opponent pieces
    int opponentPiecesAtTarget = gameModel.getPiecesAtPoint(to, 
      gameModel.currentPlayer == PlayerColor.white ? PlayerColor.black : PlayerColor.white);
    
    if (opponentPiecesAtTarget == 1) {
      score += 100; // High value for hitting
    }
    
    // Prioritize points with fewer own pieces (more flexible)
    int ownPiecesAtFrom = gameModel.getPiecesAtPoint(from, gameModel.currentPlayer);
    if (ownPiecesAtFrom <= 1) {
      score += 10; // Safe to move single pieces
    }
    
    // Prioritize advancing toward home
    int homeProgress = _calculateHomeProgress(to, gameModel.currentPlayer);
    score += homeProgress * 5;
    
    // Avoid leaving blots that can be hit
    // ... more evaluation logic
    
    return score;
  }

  /// Calculate home board progress
  int _calculateHomeProgress(int point, PlayerColor player) {
    if (point <= 0) return 0;
    
    if (player == PlayerColor.white) {
      // White home is points 1-6 (indices 0-5)
      // Progress = how close to home
      return (point <= 6) ? point : 6;
    } else {
      // Black home is points 19-24 (indices 18-23)
      // Progress from black's perspective
      return (point >= 19) ? (24 - point + 1) : 0;
    }
  }

  /// End single player game
  void _endSinglePlayerGame(PlayerColor winner) {
    String result;
    if (winner == PlayerColor.white) {
      result = 'شما برنده شدید! رباتerror bại.';
    } else {
      result = 'ربات برنده شد! باز хе trial again.';
    }
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          ' پایان بازی ',
          style: TextStyle(fontFamily: 'IranSans', color: Color(0xFF2C1810)),
        ),
        content: Text(
          result,
          style: TextStyle(fontFamily: 'IranSans', color: Color(0xFF2C1810)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بستن', style: TextStyle(color: Color(0xFFC9A963))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Reset game
              setState(() {
                gameModel = GameModel();
              });
            },
            child: Text('بازی مجدد', style: TextStyle(color: Color(0xFFC9A963))),
          ),
        ],
      ),
    );
  }
}