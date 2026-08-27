import 'package:flutter/material.dart';
import 'package:flutter_riverpod/widget_ref.dart';
import 'package:takhtenard/models/game_model.dart';
import 'package:takhtenard/screens/home_screen.dart';

/// Two-Player Local Screen
/// Two humans playing on the same device with touch controls
class TwoPlayerLocalScreen extends ConsumerStatefulWidget {
  const TwoPlayerLocalScreen({super.key});

  @override
  TwoPlayerLocalScreenState createState() => TwoPlayerLocalScreenState();
}

class TwoPlayerLocalScreenState extends ConsumerState<TwoPlayerLocalScreen>
    with SingleTickerProviderStateMixin {
  late GameModel gameModel;
  late AnimationController _controller;
  bool isTwoPlayerLocal = true;

  @override
  void initState() {
    super.initState();
    gameModel = ref.read(gameModelProvider);
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
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
          ' دو نفره מקומי ',
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
                // Player indicators
                _buildPlayerTurnIndicator(size),
                const SizedBox(height: 20),
                
                // Game board
                _buildBoard(size),
                const SizedBox(height: 20),
                
                // Dice
                _buildDiceArea(size),
                const SizedBox(height: 20),
                
                // Controls
                _buildLocalControls(size),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build player turn indicator
  Widget _buildPlayerTurnIndicator(Size size) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildPlayerIndicatorIcon(PlayerColor.white, gameModel.currentPlayer == PlayerColor.white, size),
        _buildPlayerIndicatorIcon(PlayerColor.black, gameModel.currentPlayer == PlayerColor.black, size),
      ],
    );
  }

  /// Build player indicator icon
  Widget _buildPlayerIndicatorIcon(PlayerColor player, bool isCurrent, Size size) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFFC9A963) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Icon(
        player == PlayerColor.white ? Icons.person : Icons.person,
        color: isCurrent ? Colors.black : Color(0xFF2C1810),
        size: 20,
      ),
    );
  }

  /// Build board
  Widget _buildBoard(Size size) {
    return Container(
      width: size.width * 0.8,
      height: size.width * 0.6,
      color: Colors.brown.shade100,
      child: const Center(
        child: Text(
          'بورد بازی',
          style: TextStyle(fontFamily: 'IranSans', fontSize: 20, color: Color(0xFF2C1810)),
        ),
      ),
    );
  }

  /// Build dice area
  Widget _buildDiceArea(Size size) {
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
          _buildDieLocal(gameModel.diceValues[0], size, isHuman: true),
          const SizedBox(width: 12),
          _buildDieLocal(gameModel.diceValues[1], size, isHuman: true),
        ],
      ),
    );
  }

  /// Build local die
  Widget _buildDieLocal(int value, Size size, {required bool isHuman}) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: isHuman ? const Color(0xFFC9A963) : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          value.toString(),
          style: TextStyle(
            fontFamily: 'IranSans',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isHuman ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }

  /// Build local controls
  Widget _buildLocalControls(Size size) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Previous move button
        OutlinedButton(
          onPressed: () => _undoMove(),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFC9A963),
            side: const BorderSide(color: Color(0xFFC9A963), width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(80, 35),
          ),
          child: const Text(' لغو حرکت ',
            style: TextStyle(fontFamily: 'IranSans', fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        
        // New game button
        OutlinedButton(
          onPressed: () {
            setState(() {
              gameModel = GameModel();
            });
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFC9A963),
            side: const BorderSide(color: Color(0xFFC9A963), width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(80, 35),
          ),
          child: const Text('بازی جدید ',
            style: TextStyle(fontFamily: 'IranSans', fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  /// Undo move
  void _undoMove() {
    if (gameModel.moveHistory.isNotEmpty) {
      final lastMove = gameModel.moveHistory.removeLast();
      // Revert the move
      setState(() {
        // Simple undo - in a full implementation, would restore piece positions
      });
    }
  }
}