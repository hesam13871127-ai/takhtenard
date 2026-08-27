import 'package:flutter/material.dart';
import 'package:flutter_riverpod/widget_ref.dart';
import 'package:takhtenard/models/game_model.dart';
import 'package:takhtenard/theme/app_theme.dart';

/// Main Game Screen with Iranian Backgammon Board
/// Features the beautiful board with round pieces, animations, and full game rules
class GameScreen extends ConsumerStatefulWidget {
  final GameModel? initialModel;
  final bool isTwoPlayer;
  final DifficultyLevel? difficulty;

  const GameScreen({
    super.key,
    this.initialModel,
    this.isTwoPlayer = false,
    this.difficulty,
  });

  @override
  GameScreenState createState() => GameScreenState();
}

class GameScreenState extends ConsumerState<GameScreen>
    with TickerProviderStateMixin {
  late GameModel gameModel;
  late AnimationController _animationController;
  late Animation<double> _diceRollAnimation;
  late AnimationController _rollDiceController;
  late Animation<double> _cubeSpinAnimation;

  @override
  void initState() {
    super.initState();
    gameModel = widget.initialModel ?? GameModel();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _diceRollAnimation = Tween(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    
    _rollDiceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _cubeSpinAnimation = Tween(begin: 0, end: 2 * 3.14159).animate(
      CurvedAnimation(parent: _rollDiceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _rollDiceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      appBar: _buildAppBar(size),
      body: Stack(
        children: [
          // Game background
          _buildBackground(size),
          
          // Main game content
          SafeArea(
            child: Column(
              children: [
                // Header with game info
                _buildHeader(size),
                
                // Expanded game area
                Expanded(
                  child: Row(
                    children: [
                      // Left panel - player info and controls
                      _buildLeftPanel(size),
                      
                      // Game board
                      Expanded(
                        child: _buildBoard(size),
                      ),
                      
                      // Right panel - opponent info
                      _buildRightPanel(size),
                    ],
                  ),
                ),
                
                // Dice area
                _buildDiceArea(size),
                
                // Action buttons
                _buildActionButtons(size),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build app bar
  AppBar _buildAppBar(Size size) {
    return AppBar(
      title: const Text(
        ' تخار نرد ',
        style: TextStyle(fontFamily: 'IranSans', color: Color(0xFF2C1810)),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Color(0xFF2C1810),
      actions: [
        // Doubling cube button
        IconButton(
          icon: AnimatedRotation(
            turns: _cubeSpinAnimation.value / (2 * 3.14159),
            child: Icon(
              Icons.cube,
              color: const Color(0xFFC9A963),
              size: 28,
            ),
          ),
          onPressed: () => _showDoubleDialog(),
        ),
      ],
    );
  }

  /// Build background
  Widget _buildBackground(Size size) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFFF8E1),
            const Color(0xFFFFF3E0),
            const Color(0xFFFFF0E1),
          ],
        ),
      ),
    );
  }

  /// Build header with player info and doubling cube
  Widget _buildHeader(Size size) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Current player indicator
          _buildPlayerIndicator(currentPlayer, size),
          
          // Game status
          _buildGameStatus(size),
        ],
      ),
    );
  }

  /// Build player indicator
  Widget _buildPlayerIndicator(PlayerColor player, Size size) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC9A963), width: 1),
      ),
      child: Row(
        children: [
          Icon(
            player == PlayerColor.white ? Icons.person : Icons.person,
            size: 16,
            color: const Color(0xFFC9A963),
          ),
          const SizedBox(width: 6),
          Text(
            player == PlayerColor.white ? 'بileshwarz (اب.white)' : 'بileshwarz (ک u)',
            style: const TextStyle(
              fontFamily: 'IranSans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C1810),
            ),
          ),
        ],
      ),
    );
  }

  /// Build game status
  Widget _buildGameStatus(Size size) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC9A963), width: 1),
      ),
      child: Text(
        ' مخرب ${gameModel.diceValues[0]} - ${gameModel.diceValues[1]} ',
        style: const TextStyle(
          fontFamily: 'IranSans',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2C1810),
        ),
      ),
    );
  }

  /// Build left panel (player pieces count)
  Widget _buildLeftPanel(Size size) {
    return Container(
      width: isMobile ? size.width * 0.25 : size.width * 0.35,
      color: const Color(0xFFFFF8E1),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Player piece count
            _buildPieceCount('بileshwarz', 0, size),
            const SizedBox(height: 16),
            _buildPieceCount('ک u', 1, size),
            const SizedBox(height: 16),
            _buildBarStatus(size),
            const SizedBox(height: 24),
            _buildDoublingCube(size),
          ],
        ),
      ),
    );
  }

  /// Build piece count
  Widget _buildPieceCount(String label, int playerIndex, Size size) {
    int pieces = gameModel.getPiecesAtPoint(-1, playerIndex == 0 ? PlayerColor.white : PlayerColor.black);
    // Count all pieces not on board (borne off)
    int borneOff = 0;
    for (int i = 0; i < 6; i++) {
      borneOff += gameModel.getPiecesAtPoint(i, playerIndex == 0 ? PlayerColor.white : PlayerColor.black);
    }
    
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'IranSans',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C1810),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFC9A963),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$borneOff',
            style: const TextStyle(
              fontFamily: 'IranSans',
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C1810),
            ),
          ),
        ),
      ],
    );
  }

  /// Build bar status
  Widget _buildBarStatus(Size size) {
    return Column(
      children: [
        Text(
          ' قطعات بر اینبار (Bar)',
          style: const TextStyle(
            fontFamily: 'IranSans',
            fontSize: 12,
            color: Color(0xFF6D4A28),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBarPiece(PlayerColor.white, size),
            const SizedBox(width: 12),
            _buildBarPiece(PlayerColor.black, size),
          ],
        ),
      ],
    );
  }

  /// Build bar piece indicator
  Widget _buildBarPiece(PlayerColor player, Size size) {
    int piecesOnBar = gameModel.bars[player == PlayerColor.white ? 0 : 1];
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: player == PlayerColor.white ? Color(0xFFFFF3E0) : Color(0xFF2C1810),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$piecesOnBar',
          style: TextStyle(
            fontFamily: 'IranSans',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: player == PlayerColor.white ? Color(0xFF2C1810) : Colors.white,
          ),
        ),
      ),
    );
  }

  /// Build doubling cube
  Widget _buildDoublingCube(Size size) {
    return GestureDetector(
      onTap: () => _showDoubleDialog(),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFC9A963), width: 1),
        ),
        child: AnimatedRotation(
          turns: _cubeSpinAnimation.value / (2 * 3.14159),
          child: Icon(
            Icons.cube,
            color: const Color(0xFFC9A963),
            size: 24,
          ),
        ),
      ),
    );
  }

  /// Build right panel (opponent pieces)
  Widget _buildRightPanel(Size size) {
    return Container(
      width: isMobile ? size.width * 0.25 : size.width * 0.35,
      color: const Color(0xFFFFF8E1),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildPieceCountOpponent(0, size),
            const SizedBox(height: 16),
            _buildPieceCountOpponent(1, size),
            const SizedBox(height: 16),
            _buildBarStatus(size),
          ],
        ),
      ),
    );
  }

  /// Build opponent piece count
  Widget _buildPieceCountOpponent(int playerIndex, Size size) {
    int borneOff = 0;
    for (int i = 18; i < 24; i++) {
      borneOff += gameModel.getPiecesAtPoint(i, playerIndex == 0 ? PlayerColor.white : PlayerColor.black);
    }
    
    return Column(
      children: [
        const Text(
          ' قطعات خارج ',
          style: TextStyle(
            fontFamily: 'IranSans',
            fontSize: 12,
            color: Color(0xFF6D4A28),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFC9A963),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$borneOff',
            style: const TextStyle(
              fontFamily: 'IranSans',
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C1810),
            ),
          ),
        ),
      ],
    );
  }

  /// Build game board
  Widget _buildBoard(Size size) {
    return Container(
      color: const Color(0xFFFFF0E1),
      child: CustomPaint(
        size: Size(
          isMobile ? size.width * 0.8 : size.width * 0.9,
          isMobile ? size.width * 0.8 : size.width * 0.9,
        ),
        _BoardPainter(gameModel),
      ),
    );
  }

  /// Build dice area
  Widget _buildDiceArea(Size size) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(8),
      color: const Color(0xFFFFF8E1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Die 1
          _buildDie(
            gameModel.diceValues[0],
            size,
          ),
          const SizedBox(width: 16),
          // Die 2
          _buildDie(
            gameModel.diceValues[1],
            size,
          ),
        ],
      ),
    );
  }

  /// Build a single die
  Widget _buildDie(int value, Size size) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFC9A963),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          value.toString(),
          style: const TextStyle(
            fontFamily: 'IranSans',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C1810),
          ),
        ),
      ),
    );
  }

  /// Build action buttons (roll, resign, etc.)
  Widget _buildActionButtons(Size size) {
    return Container(
      height: 60,
      padding: const EdgeInsets.all(12),
      color: const Color(0xFFFFF8E1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Roll dice button
          ElevatedButton(
            onPressed: gameModel.gameState == GameState.rolling 
                ? null 
                : _rollDice,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC9A963),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(80, 40),
            ),
            child: const Text(
              'zählung',
              style: TextStyle(
                fontFamily: 'IranSans',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C1810),
              ),
            ),
          ),
          
          // Resign button
          OutlinedButton(
            onPressed: () => _showResignDialog(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFC9A963),
              side: const BorderSide(color: Color(0xFFC9A963), width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(80, 40),
            ),
            child: const Text(
              'استسلام',
              style: TextStyle(
                fontFamily: 'IranSans',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C1810),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show double dialog
  void _showDoubleDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          ' گامبل (Doubling Cube) ',
          style: TextStyle(fontFamily: 'IranSans', color: Color(0xFF2C1810)),
        ),
        content: const Text(
          ' doublenubelbit ',
          style: TextStyle(fontFamily: 'IranSans', color: Color(0xFF4A3226)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بستن', style: TextStyle(color: Color(0xFFC9A963))),
          ),
          TextButton(
            onPressed: () {
              // Double the cube
              gameModel.doublingCube *= 2;
              gameModel.hasDouble = true;
              Navigator.pop(context);
              notifyListeners();
            },
            child: const Text('تضاعف', style: TextStyle(color: Color(0xFFC9A963))),
          ),
        ],
      ),
    );
  }

  /// Show resign dialog
  void _showResignDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          ' استسلام ',
          style: TextStyle(fontFamily: 'IranSans', color: Color(0xFF2C1810)),
        ),
        content: const Text(
          ' آیا حتماً mendeš exit؟',
          style: TextStyle(fontFamily: 'IranSans', color: Color(0xFF4A3226)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('خیر', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Game over - opponent wins
              _endGame(currentPlayer == PlayerColor.white ? PlayerColor.black : PlayerColor.white);
            },
            child: const Text('بله', style: TextStyle(color: Color(0xFFC9A963))),
          ),
        ],
      ),
    );
  }

  /// Roll dice action
  void _rollDice() {
    if (gameModel.gameState != GameState.rolling) return;
    
    // Roll the dice
    gameModel.rollDice();
    
    // Start roll animation
    _rollDiceController.forward(from: 0);
    
    // After animation, set up the turn
    Future.delayed(const Duration(milliseconds: 500), () {
      _startTurn();
    });
  }

  /// Start a player's turn
  void _startTurn() {
    // Check if player has pieces on bar and must re-enter
    if (gameModel.bars[currentPlayer == PlayerColor.white ? 0 : 1] > 0) {
      // Must re-enter from bar first
      _tryReEnterFromBar();
      return;
    }
    
    // Get legal moves
    var legalMoves = gameModel.getLegalMoves();
    
    if (legalMoves.isEmpty) {
      // No moves available - skip turn
      _skipTurn();
      return;
    }
    
    // Player can move - set state to allow moves
    setState(() {
      gameModel.gameState = GameState.playing;
    });
  }
  
  /// Try to re-enter from bar
  void _tryReEnterFromBar() {
    int barIndex = currentPlayer == PlayerColor.white ? 0 : 1;
    int piecesOnBar = gameModel.bars[barIndex];
    
    if (piecesOnBar <= 0) return;
    
    // Try to re-enter based on dice values
    for (int diceIndex = 0; diceIndex < gameModel.diceValues.length; diceIndex++) {
      int dice = gameModel.diceValues[diceIndex];
      int target = _calculateReEnterTarget(dice, currentPlayer);
      
      if (target != -1 && gameModel.isPointOpen(target, currentPlayer)) {
        // Can re-enter
        gameModel.movePiece(-1, target); // -1 indicates from bar
        gameModel.bars[barIndex]--;
        
        // Switch player if only one die used and other moves possible
        // ... complex logic simplified
        
        break;
      }
    }
    
    // If no re-enter possible, skip turn
    _skipTurn();
  }
  
  /// Calculate target point for re-entering from bar
  int _calculateReEnterTarget(int dice, PlayerColor player) {
    // From bar, re-enter at point corresponding to dice value
    // White re-enters at points 1-6 (indices 0-5), corresponding to dice roll
    // Black re-enters at points 19-24 (indices 18-23)
    
    if (player == PlayerColor.white) {
      // White: can enter at point matching dice value (1-6)
      int point = dice; // dice 1-6 correspond to points 1-6 (indices 0-5)
      if (point >= 1 && point <= 6) {
        return point - 1; // Convert to 0-indexed
      }
      return -1;
    } else {
      // Black: can enter at points 19-24 corresponding to dice
      // From black's perspective, dice 1 means point 19, dice 6 means point 24
      int point = 24 - dice + 1; // Reverse: dice 1 → point 24, dice 6 → point 19
      if (point >= 19 && point <= 24) {
        return point - 1; // 0-indexed
      }
      return -1;
    }
  }

  /// Skip turn
  void _skipTurn() {
    // Switch player
    currentPlayer = currentPlayer == PlayerColor.white ? PlayerColor.black : PlayerColor.white;
    gameModel.gameState = GameState.rolling;
    notifyListeners();
  }

  /// End game
  void _endGame(PlayerColor winPlayer) {
    gameModel.gameOverFlag = true;
    gameModel.winner = winPlayer;
    gameModel.gameState = GameState.gameOver;
    notifyListeners();
    
    // Show game over dialog
    _showGameOverDialog(winPlayer);
  }
  
  /// Show game over dialog
  void _showGameOverDialog(PlayerColor winner) {
    String result;
    if (winner == PlayerColor.white) {
      result = 'بileshwarz wins!';
    } else {
      result = 'بileshwarz (ک u) wins!';
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
        ],
      ),
    );
  }
}

/// Board painter for the backgammon board
class _BoardPainter extends CustomPainter {
  final GameModel gameModel;
  
  _BoardPainter(this.gameModel);
  
  @override
  void paint(Canvas canvas, Size size) {
    final double houseSize = size.width / 24;
    final centerOffset = size.width / 48; // Center the board
    
    // Draw board background (checker pattern)
    final paint = Paint();
    
    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 6; col++) {
        final x = col * 6 * houseSize + centerOffset;
        final y = row * (size.height / 4) + 20;
        
        // Alternating colors
        if ((row + col).isEven) {
          paint.color = const Color(0xFFFFF8E1);
        } else {
          paint.color = const Color(0xFFFFF0E1);
        }
        canvas.drawRect(
          Rect.fromLTWH(x + col * 6 * houseSize, y + row * (size.height / 4), houseSize * 6, houseSize),
          paint,
        );
      }
    }
    
    // Draw points (24 triangles)
    final pointPaint = Paint();
    
    for (int i = 0; i < 24; i++) {
      final x = (i % 6) * 6 * houseSize + centerOffset + (i ~/ 6) * 3 * houseSize;
      final y = (i < 12 ? 20 : size.height - 20);
      
      // Determine if this is white's side or black's side
      // Draw point highlight based on pieces
      int pieces = gameModel.piecePositions[i];
      
      if (pieces != 0) {
        // Draw piece indicators
        final pieceColor = pieces > 0 ? Color(0xFFFFF3E0) : Color(0xFF2C1810);
        final oppositeColor = pieces > 0 ? Color(0xFF2C1810) : Color(0xFFFFF3E0);
        
        // Draw pieces as circles
        int pieceCount = pieces.abs();
        double startAngle = 0;
        
        if (pieces > 0) {
          // White pieces
          for (int j = 0; j < pieceCount; j++) {
            double angle = startAngle + (j * 3.14159 / (pieceCount + 1));
            final px = x + (size.width / 24) * 0.6 * cos(angle);
            final py = y + (size.height / 8) * sin(angle);
            
            final piecePaint = Paint();
            piecePaint.color = pieceColor;
            piecePaint.style = PaintingStyle.fill;
            piecePaint.strokeWidth = 1;
            piecePaint.shadows = [
              Shadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1)),
            ];
            
            canvas.drawCircle(Offset(px, py), 8, piecePaint);
          }
        } else {
          // Black pieces
          for (int j = 0; j < pieceCount.abs(); j++) {
            double angle = startAngle + (j * 3.14159 / (pieceCount.abs() + 1));
            final px = x + (size.width / 24) * 0.6 * cos(angle);
            final py = y - (size.height / 8) * sin(angle);
            
            final piecePaint = Paint();
            piecePaint.color = oppositeColor;
            piecePaint.style = PaintingStyle.fill;
            piecePaint.strokeWidth = 1;
            piecePaint.shadows = [
              Shadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1)),
            ];
            
            canvas.drawCircle(Offset(px, py), 8, piecePaint);
          }
        }
      }
      
      // Draw point circle
      pointPaint.color = Colors.grey.shade300;
      pointPaint.style = PaintingStyle.stroke;
      pointPaint.strokeWidth = 2;
      
      final offset = Offset(x, y);
      canvas.drawCircle(offset, 12, pointPaint);
      
      // Draw point number
      final numberPaint = Paint();
      numberPaint.color = Colors.black87;
      numberPaint.style = PaintingStyle.fill;
      numberPaint.fontSize = 12;
      numberPaint.fontFamily = 'IranSans';
      
      final numStr = (i + 1).toString();
      final textSize = paint.measureText(numStr);
      canvas.drawText(
        numStr,
        x - textSize.width / 2,
        y + 4,
        numberPaint,
      );
    }
    
    // Draw home bearing off area indicators
    // ... simplified
  }
  
  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) => true;
}