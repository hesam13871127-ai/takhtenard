import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/persian_digits.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/luxury_button.dart';
import '../../game/application/game_controller.dart';
import '../../game/domain/models/game_config.dart';
import '../../game/presentation/game_screen.dart';
import '../../rules/presentation/rules_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../settings/settings_controller.dart';

/// Main menu: play buttons, difficulty selector, rules & settings.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late AiDifficulty _difficulty;
  bool _hasSave = false;

  @override
  void initState() {
    super.initState();
    // Start from the saved default; a tap on a card overrides it locally.
    _difficulty = ref.read(settingsProvider).defaultDifficulty;
    _refreshSaveState();
  }

  Future<void> _refreshSaveState() async {
    final has = await ref.read(gameControllerProvider.notifier).hasSavedGame();
    if (mounted) setState(() => _hasSave = has);
  }

  void _startVsAi() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          newConfig: GameConfig(
            mode: GameMode.vsAi,
            difficulty: _difficulty,
            whiteName: AppStrings.you,
            blackName: AppStrings.computer,
            humanPlays: PlayerSide.white,
          ),
        ),
      ),
    );
  }

  void _startLocal() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          newConfig: GameConfig(
            mode: GameMode.localMultiplayer,
            difficulty: _difficulty,
            whiteName: AppStrings.player1,
            blackName: AppStrings.player2,
          ),
        ),
      ),
    );
  }

  void _continueGame() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const GameScreen(restore: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  _buildHeader(),
                  const SizedBox(height: 26),
                  if (_hasSave) ...[
                    LuxuryButton(
                      label: AppStrings.continueGame,
                      icon: Icons.play_circle_fill,
                      small: true,
                      onPressed: _continueGame,
                    ),
                    const SizedBox(height: 14),
                  ],
                  LuxuryButton(
                    label: AppStrings.playVsAi,
                    icon: Icons.smart_toy_outlined,
                    onPressed: _startVsAi,
                  ),
                  const SizedBox(height: 14),
                  LuxuryButton(
                    label: AppStrings.playWithFriend,
                    icon: Icons.group,
                    onPressed: _startLocal,
                  ),
                  const SizedBox(height: 26),
                  _buildDifficultySelector(),
                  const SizedBox(height: 26),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LuxuryButton(
                        label: AppStrings.rules,
                        icon: Icons.menu_book,
                        small: true,
                        secondary: true,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const RulesScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      LuxuryButton(
                        label: AppStrings.settings,
                        icon: Icons.settings,
                        small: true,
                        secondary: true,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Image.asset(
            'assets/images/logo.jpg',
            width: 130,
            height: 130,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
          ),
        )
            .animate()
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1, 1),
              duration: 600.ms,
              curve: Curves.easeOutBack,
            )
            .fadeIn(),
        const SizedBox(height: 16),
        const Text(
          AppStrings.appTitle,
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: AppPalette.ivory,
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.3, end: 0),
        const SizedBox(height: 6),
        const Text(
          AppStrings.appSubtitle,
          style: TextStyle(fontSize: 15, color: AppPalette.gold),
        ).animate(delay: 200.ms).fadeIn(),
      ],
    );
  }

  Widget _buildDifficultySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          AppStrings.chooseDifficulty,
          style: TextStyle(
            color: AppPalette.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _DifficultyCard(
                label: AppStrings.easy,
                description: AppStrings.easyDesc,
                icon: Icons.sentiment_satisfied,
                selected: _difficulty == AiDifficulty.easy,
                onTap: () => setState(() => _difficulty = AiDifficulty.easy),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DifficultyCard(
                label: AppStrings.medium,
                description: AppStrings.mediumDesc,
                icon: Icons.sentiment_neutral,
                selected: _difficulty == AiDifficulty.medium,
                onTap: () => setState(() => _difficulty = AiDifficulty.medium),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DifficultyCard(
                label: AppStrings.hard,
                description: AppStrings.hardDesc,
                icon: Icons.local_fire_department,
                selected: _difficulty == AiDifficulty.hard,
                onTap: () => setState(() => _difficulty = AiDifficulty.hard),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          '${AppStrings.version} ${_faVersion()}',
          style: const TextStyle(color: AppPalette.textFaint, fontSize: 12),
        ),
        const SizedBox(height: 4),
        const Text(
          AppStrings.madeWithLove,
          style: TextStyle(color: AppPalette.textFaint, fontSize: 12),
        ),
      ],
    );
  }

  String _faVersion() => PersianDigits.convert(AppConstants.appVersion);
}

/// One selectable difficulty card.
class _DifficultyCard extends StatelessWidget {
  const _DifficultyCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xCC241812),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? AppPalette.gold : AppPalette.panelBorder,
          width: selected ? 1.8 : 1,
        ),
        boxShadow: selected
            ? const [BoxShadow(color: Color(0x55D4AF37), blurRadius: 14)]
            : null,
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 26,
            color: selected ? AppPalette.gold : AppPalette.textFaint,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: selected ? AppPalette.ivory : AppPalette.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              height: 1.5,
              color: AppPalette.textFaint,
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: card
          .animate(target: selected ? 1 : 0)
          .scaleXY(begin: 0.96, end: 1.02, duration: 240.ms),
    );
  }
}
