import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/sound_controller.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/board_themes.dart';
import '../../../core/utils/persian_digits.dart';
import '../../../shared/widgets/app_background.dart';
import '../../game/domain/models/game_config.dart';
import '../settings_controller.dart';

/// App settings: sound, default AI difficulty, board theme and about.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final soundController = ref.read(soundControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppStrings.settings,
          style: TextStyle(
            color: AppPalette.ivory,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppPalette.gold),
      ),
      body: AppBackground(
        showParticles: false,
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              // ------------------------------------------------- sound
              _SettingsCard(
                icon: settings.soundOn
                    ? Icons.volume_up
                    : Icons.volume_off,
                title: AppStrings.soundSettings,
                subtitle: AppStrings.soundSettingsDesc,
                child: _LuxurySwitch(
                  value: settings.soundOn,
                  onChanged: (value) {
                    controller.setSoundOn(value);
                    soundController.enabled = value;
                  },
                ),
              ),

              // ------------------------------------------- difficulty
              _SettingsCard(
                icon: Icons.smart_toy_outlined,
                title: AppStrings.defaultDifficulty,
                subtitle: AppStrings.chooseDifficulty,
                child: _DifficultySelector(
                  value: settings.defaultDifficulty,
                  onChanged: controller.setDefaultDifficulty,
                ),
              ),

              // ----------------------------------------------- theme
              _SettingsCard(
                icon: Icons.palette_outlined,
                title: AppStrings.boardTheme,
                subtitle: settings.boardTheme.name,
                child: _ThemeSelector(
                  value: settings.boardThemeId,
                  onChanged: controller.setBoardTheme,
                ),
              ),

              // ------------------------------------------------ about
              _SettingsCard(
                icon: Icons.info_outline,
                title: AppStrings.aboutApp,
                subtitle: AppStrings.appSubtitle,
                child: LuxuryAboutButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A settings card with leading icon, texts and a trailing control.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xCC241812),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0x1FD4AF37),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppPalette.gold, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppPalette.ivory,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppPalette.textFaint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// A premium-looking switch without default Material colors.
class _LuxurySwitch extends StatelessWidget {
  const _LuxurySwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 58,
        height: 32,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: value
              ? const LinearGradient(
                  colors: [AppPalette.goldLight, AppPalette.goldDark],
                )
              : const LinearGradient(
                  colors: [Color(0xFF3A2A20), Color(0xFF241812)],
                ),
          border: Border.all(
            color: value ? AppPalette.gold : AppPalette.panelBorder,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          alignment: value ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppPalette.ivory,
              boxShadow: [BoxShadow(color: Color(0x66000000), blurRadius: 4)],
            ),
          ),
        ),
      ),
    );
  }
}

/// Segmented difficulty selector.
class _DifficultySelector extends StatelessWidget {
  const _DifficultySelector({required this.value, required this.onChanged});

  final AiDifficulty value;
  final ValueChanged<AiDifficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget segment(String label, AiDifficulty level) {
      final selected = value == level;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(level),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0x33D4AF37)
                  : const Color(0x14241812),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppPalette.gold : AppPalette.panelBorder,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                color: selected ? AppPalette.ivory : AppPalette.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        segment(AppStrings.easy, AiDifficulty.easy),
        const SizedBox(width: 8),
        segment(AppStrings.medium, AiDifficulty.medium),
        const SizedBox(width: 8),
        segment(AppStrings.hard, AiDifficulty.hard),
      ],
    );
  }
}

/// Board theme selector with live color previews.
class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final theme in BoardThemeData.all) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(theme.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0x14241812),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: value == theme.id
                        ? AppPalette.gold
                        : AppPalette.panelBorder,
                    width: value == theme.id ? 1.8 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 34,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            theme.frameLight,
                            theme.frameDark,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: theme.pointA,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: theme.pointB,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      theme.name,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (theme != BoardThemeData.all.last) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

/// The "about" action.
class LuxuryAboutButton extends StatelessWidget {
  LuxuryAboutButton();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppPalette.gold,
        side: const BorderSide(color: AppPalette.panelBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      icon: const Icon(Icons.emoji_events_outlined),
      label: const Text(
        AppStrings.aboutApp,
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      onPressed: () {
        showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text(AppStrings.aboutTitle),
            content: Text(
              AppStrings.aboutBody(
                '${AppStrings.version} ${PersianDigits.convert(
                  AppConstants.appVersion,
                )}',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text(AppStrings.ok),
              ),
            ],
          ),
        );
      },
    );
  }
}
