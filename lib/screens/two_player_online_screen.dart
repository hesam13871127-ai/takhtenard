import 'package:flutter/material.dart';
import 'package:flutter_riverpod/widget_ref.dart';
import 'package:takhtenard/models/game_model.dart';
import 'package:takhtenard/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Two-Player Online Screen
/// Firebase Authentication + Firestore for online two-player games
class TwoPlayerOnlineScreen extends ConsumerStatefulWidget {
  const TwoPlayerOnlineScreen({super.key});

  @override
  TwoPlayerOnlineScreenState createState() => TwoPlayerOnlineScreenState();
}

class TwoPlayerOnlineScreenState extends ConsumerState<TwoPlayerOnlineScreen>
    with SingleTickerProviderStateMixin {
  late GameModel gameModel;
  late AnimationController _controller;
  User? _user;
  String? _opponentName;
  bool _isMatching = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    gameModel = ref.read(gameModelProvider);
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _controller.forward();
    _initFirebase();
  }

  void _initFirebase() async {
    try {
      _user = FirebaseAuth.instance.currentUser;
      if (_user == null) {
        // Need to login
        await FirebaseAuth.instance.signInAnonymously();
      }
      setState(() {});
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing Firebase: $e';
      });
    }
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
          ' دو نفره آنلاین ',
          style: TextStyle(fontFamily: 'IranSans', color: Color(0xFF2C1810)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Color(0xFF2C1810),
        actions: [
          _user != null 
              ? const Icon(Icons.person, color: Color(0xFF2C1810))
              : const Icon(Icons.lock, color: Color(0xFFC9A963)),
        ],
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
                // Status area
                _buildStatusArea(size),
                const SizedBox(height: 20),
                
                // Matchmaking
                _buildMatchmaking(size),
                const SizedBox(height: 20),
                
                // Game board
                _buildBoard(size),
                const SizedBox(height: 20),
                
                // Dice
                _buildDiceArea(size),
                const SizedBox(height: 20),
                
                // Messages
                if (_errorMessage != null) ...[
                  _buildErrorMessage(),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build status area
  Widget _buildStatusArea(Size size) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFC9A963), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud, color: Color(0xFFC9A963), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _user != null 
                  ? 'ورود موفق - searching for opponent...'
                  : 'لطفاً برای بازی rejoindre کنید',
              style: TextStyle(
                fontFamily: 'IranSans',
                fontSize: 14,
                color: Color(0xFF4A3226),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build matchmaking area
  Widget _buildMatchmaking(Size size) {
    if (_user == null) {
      return ElevatedButton(
        onPressed: () async {
          await FirebaseAuth.instance.signInAnonymously();
          setState(() {});
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC9A963),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: Size(size.width * 0.4, 50),
        ),
        child: const Text(
          'ورود به فايرباسم',
          style: TextStyle(fontFamily: 'IranSans', fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );
    }
    
    if (_isMatching) {
      return const CircularProgressIndicator(color: Color(0xFFC9A963));
    }
    
    return ElevatedButton(
      onPressed: _startMatch,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFC9A963),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        minimumSize: Size(size.width * 0.4, 50),
      ),
      child: const Text(
        'شروع بازی جدید',
        style: TextStyle(fontFamily: 'IranSans', fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  /// Start a match
  void _startMatch() {
    setState(() {
      _isMatching = true;
    });
    
    // In a real implementation, we'd create a Firestore document
    // and wait for an opponent to join
    // For now, just simulate a quick match
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isMatching = false;
        _opponentName = 'بileshwarz (ض عبر opponent)';
      });
    });
  }

  /// Build board
  Widget _buildBoard(Size size) {
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
          _buildDieOnline(gameModel.diceValues[0], size),
          const SizedBox(width: 12),
          _buildDieOnline(gameModel.diceValues[1], size),
        ],
      ),
    );
  }

  /// Build online die
  Widget _buildDieOnline(int value, Size size) {
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
          style: TextStyle(
            fontFamily: 'IranSans',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  /// Build error message
  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFFFE0E0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red, width: 1),
      ),
      child: Text(
        _errorMessage!,
        style: TextStyle(color: Colors.red, fontFamily: 'IranSans', fontSize: 12),
      ),
    );
  }
}