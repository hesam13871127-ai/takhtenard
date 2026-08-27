import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TakhtenardApp());
}

class TakhtenardApp extends ConsumerStatefulWidget {
  const TakhtenardApp({super.key});

  @override
  ConsumerState<TakhtenardApp> createState() => _TakhtenardAppState();

  // This widget is the root of your application.
}

class _TakhtenardAppState extends ConsumerState<TakhtenardApp> {
  // Theme mode management
  @override
  void initState() {
    super.initState();
    // Initialize shared preferences for offline storage
    _initSharedPreferences();
  }

  Future<void> _initSharedPreferences() async {
    // Initialize shared preferences for offline game data
    await SharedPreferences.getInstance();
  }

  // Check if user is logged in (for offline mode)
  bool _isUserLoggedIn = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Takhtenard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC9A963), // Golden Iranian color
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F0E1),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'IranSans',
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C1810),
          ),
          titleLarge: TextStyle(
            fontFamily: 'IranSans',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3E2723),
          ),
          bodyLarge: TextStyle(
            fontFamily: 'IranSans',
            fontSize: 16,
            color: Color(0xFF4A3226),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC9A963),
            foregroundColor: Colors.black,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFC9A963),
            side: const BorderSide(color: Color(0xFFC9A963), width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC9A963),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF2C1810),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'IranSans',
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE8E4DC),
          ),
          titleLarge: TextStyle(
            fontFamily: 'IranSans',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFFCFD8DC),
          ),
          bodyLarge: TextStyle(
            fontFamily: 'IranSans',
            fontSize: 16,
            color: Color(0xFFB0BEC5),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC9A963),
            foregroundColor: Colors.black,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
      ),
      themeMode: ThemeMode.light,
      home: const LoginScreen(),
    );
  }
}