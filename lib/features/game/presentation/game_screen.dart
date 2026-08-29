import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/sound_controller.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/persian_digits.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/luxury_button.dart';
import '../../rules/presentation/rules_screen.dart';
import '../../settings/settings_controller.dart';
import '../application/game_controller.dart';
import '../domain/models/game_config.dart';
import '../domain/models/player.dart';
import '../domain/engine/takhteh_game.dart';
import '../../result/presentation/result_screen.dart';
import 'board_view.dart';

/// The main game screen: HUD, board, controls, overlays and menus.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, this.newConfig, this.restore = false});

  /// When set, a fresh game starts with this configuration.
  final GameConfig? newConfig;

  /// When true, the persisted game is restored instead of starting a new
  /// one.
  final bool restore;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  String? _flashText;
  int _flashKey = 0;
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    final controller = ref.read(gameControllerProvider.notifier);
    if (widget.restore) {
      controller.restoreSavedGame();
    } else if (widget.newConfig != null) {
      controller.startGame(widget.newConfig!);
    }

    // React to game events with banners and navigation.
    ref.listenManual(gameControllerProvider, (previous, next) {
      final action = next.lastAction;
      if (action is GameFinished) {
        _navigateToResult(next);
        return;
      }
      if (next.revision == (previous?.revision ?? -1)) return;
      if (action is MoveApplied && action.move.hits && !action.won) {
        _flash(AppStrings.hitExclamation);
      } else if (action is TurnEndedAction) {
        _flash(_turnBannerText(next));
      }
    });
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  String _turnBannerText(GameUiState ui) {
    if (ui.config.mode == GameMode.vsAi) {
      return ui.aiOnTurn ? AppStrings.opponentTurn : AppStrings.yourTurn;
    }
    return AppStrings.playerTurn(_playerName(ui, ui.game.current));
  }

  String _playerName(GameUiState ui, Player player) {
    return player == Player.white ? ui.config.whiteName : ui.config.blackName;
  }

  void _flash(String text) {
    if (!mounted) return;
    setState(() {
      _flashText = text;
      _flashKey++;
    });
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() => _flashText = null);
      }
    });
  }

  Future<void> _navigateToResult(GameUiState ui) async {
    // Let the winning move animate and the sound play before moving on.
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondary) => ResultScreen(
          result: ui.game.result!,
          score: ui.score,
          config: ui.config,
        ),
        transitionsBuilder: (context, animation, secondary, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 550),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ui = ref.watch(gameControllerProvider);

    return Scaffold(
      body: AppBackground(
        showParticles: false,
        child: SafeArea(
          child: OrientationBuilder(
            builder: (context, orientation) {
              final board = _buildBoard(context, ui);
              final hudTop = _PlayerPanel(
                player: Player.black,
                name: _playerName(ui, Player.black),
                ui: ui,
              );
              final hudBottom = _PlayerPanel(
                player: Player.white,
                name: _playerName(ui, Player.white),
                ui: ui,
              );
              final controls = _ControlsBar(ui: ui);

              if (orientation == Orientation.landscape) {
                return Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: board,
                      ),
                    ),
                    SizedBox(
                      width: 280,
                      child: Column(
                        children: [
                          hudTop,
                          Expanded(
                            child: Center(
                              child: SingleChildScrollView(child: controls),
                            ),
                          ),
                          hudBottom,
                        ],
                      ),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  hudTop,
                  Expanded(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: board,
                  )),
                  controls,
                  hudBottom,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBoard(BuildContext context, GameUiState ui) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The classic board proportions: a bit wider than tall.
        const aspect = 1 / 0.84;
        var width = constraints.maxWidth;
        var height = width / aspect;
        if (height > constraints.maxHeight) {
          height = constraints.maxHeight;
          width = height * aspect;
        }
        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: [
                const BoardView(),
                _buildBannerOverlay(ui),
                _buildOpeningOverlay(ui),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Transient center banners ("your turn", "hit!", "no moves").
  Widget _buildBannerOverlay(GameUiState ui) {
    final banner = ui.banner;
    final flash = _flashText;
    final text = flash ?? banner;
    if (text == null) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Container(
            key: ValueKey('banner-$text-${flash != null ? _flashKey : 'b'}'),
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xD91E120C),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppPalette.gold),
              boxShadow: const [
                BoxShadow(color: Color(0x88000000), blurRadius: 22),
              ],
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: AppPalette.ivory,
                fontWeight: FontWeight.w800,
                fontSize: 19,
              ),
            ),
          )
              .animate(key: ValueKey('banner-$text-${flash != null ? _flashKey : 'b'}'))
              .scale(
                begin: const Offset(0.7, 0.7),
                end: const Offset(1, 1),
                duration: 300.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 220.ms),
        ),
      ),
    );
  }

  /// Opening roll hint above the dice.
  Widget _buildOpeningOverlay(GameUiState ui) {
    if (ui.game.phase != GamePhase.openingRoll) {
      return const SizedBox.shrink();
    }
    return Positioned(
      left: 0,
      right: 0,
      top: 8,
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xB31E120C),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppPalette.panelBorder),
            ),
            child: const Text(
              'تاس آغازین — عدد بزرگ‌تر شروع می‌کند',
              style: TextStyle(color: AppPalette.ivorySoft, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }
}

/// One player's status strip.
class _PlayerPanel extends ConsumerWidget {
  const _PlayerPanel({
    required this.player,
    required this.name,
    required this.ui,
  });

  final Player player;
  final String name;
  final GameUiState ui;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = settings.boardTheme;
    final isActive =
        ui.game.current == player && ui.game.phase != GamePhase.gameOver;
    final pip = ui.game.position.pipCount(player);
    final off = ui.game.position.offCount(player);
    final score =
        player == Player.white ? ui.score.white : ui.score.black;
    final isWhite = player == Player.white;

    final chip = Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.35),
          colors: isWhite
              ? [theme.whiteCheckerTop, theme.whiteCheckerBottom]
              : [theme.blackCheckerTop, theme.blackCheckerBottom],
        ),
        border: Border.all(
          color: isWhite ? theme.whiteCheckerRing : theme.blackCheckerRing,
        ),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 5)],
      ),
    );

    Widget panel = Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xCC241812),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppPalette.gold : AppPalette.panelBorder,
          width: isActive ? 1.6 : 1,
        ),
      ),
      child: Row(
        children: [
          chip,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppPalette.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.circle,
                          size: 8, color: AppPalette.successGreen),
                    ],
                  ],
                ),
                Text(
                  '${AppStrings.pip}: ${PersianDigits.format(pip)}'
                  '   •   ${AppStrings.offCount}: ${PersianDigits.format(off)}'
                  '   •   ${AppStrings.score}: ${PersianDigits.format(score)}',
                  style: const TextStyle(
                    color: AppPalette.textFaint,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isActive) {
      panel = panel
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(
            duration: 1600.ms,
            color: const Color(0x30D4AF37),
          );
    }
    return panel;
  }
}

/// Bottom controls: undo, pause, sound, flip + roll button / status.
class _ControlsBar extends ConsumerWidget {
  const _ControlsBar({required this.ui});

  final GameUiState ui;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(gameControllerProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final sound = ref.read(soundControllerProvider);

    final canUndo = ui.game.canUndo && !ui.aiOnTurn;
    final canRoll = ui.game.phase == GamePhase.awaitingRoll &&
        !ui.aiOnTurn &&
        !ui.diceRolling;
    final isOpening = ui.game.phase == GamePhase.openingRoll;
    final isLocal = ui.config.mode == GameMode.localMultiplayer;

    Widget center;
    if (isOpening) {
      center = LuxuryButton(
        label: 'تاس آغازین',
        icon: Icons.casino,
        small: true,
        onPressed: () => controller.rollOpening(),
      );
    } else if (canRoll) {
      center = LuxuryButton(
        label: AppStrings.rollDice,
        icon: Icons.casino,
        onPressed: () => controller.rollDice(),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(0.97, 0.97),
            end: const Offset(1.03, 1.03),
            duration: 800.ms,
            curve: Curves.easeInOut,
          );
    } else if (ui.aiThinking || ui.aiOnTurn) {
      center = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppPalette.gold,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            AppStrings.aiThinking,
            style: const TextStyle(color: AppPalette.textSecondary),
          ),
        ],
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .fadeIn(duration: 500.ms)
          .fadeOut(duration: 500.ms);
    } else if (ui.game.phase == GamePhase.awaitingMove) {
      center = const Text(
        'مهرهٔ پررنگ را انتخاب کنید و به خانهٔ درخشان ببرید',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppPalette.textFaint, fontSize: 12.5),
      );
    } else {
      center = const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(10, 2, 10, 8),
      child: Row(
        children: [
          LuxuryIconButton(
            icon: Icons.undo,
            tooltip: AppStrings.undo,
            enabled: canUndo,
            onPressed: controller.undo,
          ),
          const SizedBox(width: 6),
          LuxuryIconButton(
            icon: Icons.pause,
            tooltip: AppStrings.menu,
            onPressed: () => _openPauseMenu(context, ref),
          ),
          const SizedBox(width: 6),
          LuxuryIconButton(
            icon: settings.soundOn ? Icons.volume_up : Icons.volume_off,
            tooltip: AppStrings.soundSettings,
            onPressed: () {
              ref
                  .read(settingsProvider.notifier)
                  .setSoundOn(!settings.soundOn);
              sound.enabled = !settings.soundOn;
            },
          ),
          if (isLocal) ...[
            const SizedBox(width: 6),
            LuxuryIconButton(
              icon: Icons.screen_rotation_alt_outlined,
              tooltip: AppStrings.flipBoard,
              onPressed: controller.toggleManualFlip,
            ),
          ],
          const SizedBox(width: 12),
          Expanded(child: Center(child: center)),
        ],
      ),
    );
  }

  Future<void> _openPauseMenu(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(gameControllerProvider.notifier);
    controller.setPaused(true);
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _PauseMenuDialog(controller: controller),
    );
    controller.setPaused(false);
  }
}

class _PauseMenuDialog extends ConsumerWidget {
  const _PauseMenuDialog({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = ref.watch(gameControllerProvider);
    final settings = ref.watch(settingsProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              AppStrings.pauseTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${AppStrings.score}:'
              ' ${PersianDigits.format(ui.score.white)}'
              ' – ${PersianDigits.format(ui.score.black)}',
              style: const TextStyle(color: AppPalette.textSecondary),
            ),
            const SizedBox(height: 18),
            LuxuryButton(
              label: AppStrings.resume,
              icon: Icons.play_arrow,
              small: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 10),
            LuxuryButton(
              label: AppStrings.restart,
              icon: Icons.refresh,
              small: true,
              secondary: true,
              onPressed: () {
                Navigator.of(context).pop();
                controller.startGame(
                  ui.config,
                  carryScore: ui.score,
                );
              },
            ),
            const SizedBox(height: 10),
            LuxuryButton(
              label: AppStrings.rules,
              icon: Icons.menu_book,
              small: true,
              secondary: true,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const RulesScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            LuxuryButton(
              label: AppStrings.exitToHome,
              icon: Icons.home,
              small: true,
              secondary: true,
              onPressed: () => Navigator.of(context).popUntil(
                (route) => route.isFirst,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '${AppStrings.soundSettings}:',
                  style: TextStyle(color: AppPalette.textSecondary),
                ),
                Switch(
                  value: settings.soundOn,
                  activeColor: AppPalette.gold,
                  onChanged: (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .setSoundOn(value);
                    ref.read(soundControllerProvider).enabled = value;
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
