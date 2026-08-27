import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takhtenard/theme/app_theme.dart';
import 'screens/home_screen.dart';

/// Iranian Backgammon Login Screen
/// Two attractive and professional login pages with warm golden theme
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _titleAnimation;
  late Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _titleAnimation = Tween(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _buttonAnimation = Tween(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Build the login page with Iranian architectural elements
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background with Iranian tiling pattern
          _buildIranianBackground(size),
          
          // Central content with animated glow
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated title
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -20),
                      end: Offset.zero,
                    ).animate(_titleAnimation),
                    child: FadeTransition(
                      opacity: _titleAnimation,
                      child: _buildAnimatedTitle(size),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Play button - New Game
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 20),
                      end: Offset.zero,
                    ).animate(_buttonAnimation),
                    child: _buildLoginButton(
                      context,
                      'بازی جدید',
                      Icons.gamepad,
                      () {
                        // Navigate to home after "login"
                        _navigateToHome();
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Story button
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 20),
                      end: Offset.zero,
                    ).animate(_buttonAnimation),
                    child: _buildLoginButton(
                      context,
                      'قصه و قواعد',
                      Icons.book,
                      () {
                        // Navigate to story page
                        _navigateToStory();
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Online mode button
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 20),
                      end: Offset.zero,
                    ).animate(_buttonAnimation),
                    child: _buildLoginButton(
                      context,
                      'آنلاین (فایربیس)',
                      Icons.cloud,
                      () {
                        // TODO: Navigate to online login
                        _showOnlineModeDialog();
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Two-player local button
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 20),
                      end: Offset.zero,
                      ),
                    child: _buildLoginButton(
                      context,
                      'دو نفره מקומי',
                      Icons.group,
                      () {
                        // Navigate to two-player selection
                        _navigateToTwoPlayer();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the animated golden title
  Widget _buildAnimatedSize(Size size) {
    return Container(
      width: size.width * 0.8,
      height: size.width * 0.3,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.4),
            spreadRadius: 10,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'تخار نرد',
          style: TextStyle(
            fontFamily: 'IranSans',
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C1810),
            shadows: [
              Shadow(
                color: Color(0xFFFFFFAA),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build login buttons with Iranian design
  Widget _buildLoginButton(
      BuildContext context, String iconData, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE8E4DC),
          foregroundColor: const Color(0xFF2C1810),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 3,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconData,
              size: 24,
              color: const Color(0xFFC9A963),
            ),
            const SizedBox(width: 12),
            Text(
              iconData == Icons.gamepad ? 'بازی جدید' : '',
              style: const TextStyle(
                fontFamily: 'IranSans',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C1810),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build story button
  Widget _buildStoryButton(
      BuildContext context, String text, IconData icon, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFC9A963)),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'IranSans',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6D4A28),
            ),
          ),
        ],
      ),
    );
  }

  /// Navigate to home screen
  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  /// Navigate to story screen
  void _navigateToStory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StoryScreen()),
    );
  }

  /// Show online mode dialog
  void _showOnlineModeDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          ' حالت آنلاین ',
          style: TextStyle(fontFamily: 'IranSans', color: Color(0xFF2C1810)),
        ),
        content: const Text(
          'ورود به فیربیس برای بازی دو نفره آنلاین',
          style: TextStyle(fontFamily: 'IranSans', color: Color(0xFF4A3226)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بستن', style: TextStyle(color: Color(0xFFC9A963))),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement Firebase authentication
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'ویژگی آنلاین در حال پیاده‌سازی است',
                    style: TextStyle(color: Colors.yellow),
                  ),
                ),
              );
            },
            child: const Text('ورود', style: TextStyle(color: Color(0xFFC9A963))),
          ),
        ],
      ),
    );
  }

  /// Navigate to two-player selection
  void _navigateToTwoPlayer() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TwoPlayerScreen()),
    );
  }
}

/// Iranian themed home screen with game options
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoAnimation;
  late Animation<double> _menuAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _logoAnimation = Tween(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _menuAnimation = Tween(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
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
      body: Stack(
        children: [
          // Golden warm background
          Container(
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
          ),
          
          // Animated content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated logo
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -30),
                      end: Offset.zero,
                    ).animate(_logoAnimation),
                    child: FadeTransition(
                      opacity: _logoAnimation,
                      child: _buildAnimatedLogo(size),
                    ),
                  ),
                  const SizedBox(height: 60),
                  
                  // New Game button
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 20),
                      end: Offset.zero,
                    ).animate(_menuAnimation),
                    child: _buildHomeButton(
                      context,
                      'بازی جدید',
                      Icons.play_arrow,
                      () {
                        // TODO: Navigate to game mode selection
                        _showGameModeDialog();
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Story button
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 20),
                      end: Offset.zero,
                    ).animate(_menuAnimation),
                    child: _buildHomeButton(
                      context,
                      'قصه و_rules',
                      Icons.book,
                      () {
                        _navigateToStory();
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Settings button
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 20),
                      end: Offset.zero,
                    ).animate(_menuAnimation),
                    child: _buildHomeButton(
                      context,
                      'تنظیمات',
                      Icons.settings,
                      () {
                        _showSettingsDialog();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build animated logo
  Widget _buildAnimatedLogo(Size size) {
    return Container(
      width: size.width * 0.6,
      height: size.width * 0.6,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            spreadRadius: 8,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.insert_drive_time,
          size: 80,
          color: Color(0xFFC9A963),
        ),
      ),
    );
  }

  /// Build home screen buttons
  Widget _buildHomeButton(
      BuildContext context, String title, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFF3E0),
          foregroundColor: const Color(0xFF2C1810),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 3,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: const Color(0xFFC9A963),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'IranSans',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C1810),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show game mode selection dialog
  void _showGameModeDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          ' انتخاب حالت بازی ',
          style: TextStyle(fontFamily: 'IranSans', color: Color(0xFF2C1810)),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModeOption(
                context,
                'یک نفره ( melawan ربات )',
                Icons.bot,
                Colors.brown,
                () {
                  Navigator.pop(context);
                  // Navigate to single player with difficulty selection
                  _navigateToSinglePlayer();
                },
              ),
              const SizedBox(height: 12),
              _buildModeOption(
                context,
                'دو نفره מקומי',
                Icons.people,
                Colors.green,
                () {
                  Navigator.pop(context);
                  // Navigate to two-player local
                  _navigateToTwoPlayerLocal();
                },
              ),
              const SizedBox(height: 12),
              _buildModeOption(
                context,
                'دو نفره آنلاین',
                Icons.cloud,
                Colors.blue,
                () {
                  Navigator.pop(context);
                  // Navigate to online two-player
                  _navigateToTwoPlayerOnline();
                },
              ),
            ],
          ),
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

  /// Build mode option tile
  Widget _buildModeOption(
      BuildContext context, String title, IconData icon, Color color, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'IranSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2C1810),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Navigate to single player mode
  void _navigateToSinglePlayer() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SinglePlayerScreen()),
    );
  }

  /// Navigate to two-player local
  void _navigateToTwoPlayerLocal() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TwoPlayerLocalScreen()),
    );
  }

  /// Navigate to online two-player
  void _navigateToTwoPlayerOnline() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TwoPlayerOnlineScreen()),
    );
  }

  /// Navigate to story screen
  void _navigateToStory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StoryScreen()),
    );
  }

  /// Show settings dialog
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          ' تنظیمات ',
          style: TextStyle(fontFamily: 'IranSans', color: Color(0xFF2C1810)),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              ListTile(
                leading: Icon(Icons.brightness_6, color: Color(0xFFC9A963)),
                title: Text(' حالت شب روز'),
              ),
              ListTile(
                leading: Icon(Icons.language, color: Color(0xFFC9A963)),
                title: Text(' زبان '),
              ),
              ListTile(
                leading: Icon(Icons.notifications, color: Color(0xFFC9A963)),
                title: Text(' هشدارها '),
              ),
            ],
          ),
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