import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/board_themes.dart';
import '../../../core/utils/persian_digits.dart';
import '../application/game_controller.dart';
import '../domain/engine/takhteh_game.dart';
import '../domain/models/player.dart';
import '../domain/models/single_move.dart';
import '../../settings/settings_controller.dart';
import 'board_geometry.dart';
import 'board_painter.dart';
import 'widgets/checker.dart';
import 'widgets/dice.dart';

const int _maxVisibleStackCheckers = 5;

/// One movable checker on the board, kept as a stable identity across state
/// changes so Flutter can animate its position.
class _CheckerToken {
  _CheckerToken({
    required this.id,
    required this.player,
    required this.location,
    required this.order,
    this.hopKey = 0,
  });

  final int id;
  final Player player;

  /// 1..24 point, 25 = bar, 0 = borne off (in the tray).
  int location;
  double order;
  int hopKey;
}

/// The interactive game board.
///
/// Renders the painted board, the animated checkers, the dice and all
/// touch interactions (tap-to-select, tap-to-move and drag & drop).
/// Illegal moves are structurally impossible: only destinations offered by
/// the rules engine respond to input.
class BoardView extends ConsumerStatefulWidget {
  const BoardView({super.key});

  @override
  ConsumerState<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends ConsumerState<BoardView> {
  final List<_CheckerToken> _tokens = [];
  int _nextTokenId = 1;
  int _processedRevision = -1;

  ui.Image? _woodTexture;
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;

  // Drag & drop state.
  int? _dragFrom;
  Player? _dragPlayer;
  Offset? _dragPointer;
  int _dragHopKey = 0;

  @override
  void initState() {
    super.initState();
    _loadWoodTexture();
  }

  void _loadWoodTexture() {
    final provider = const AssetImage('assets/images/board_wood.jpg');
    final stream = provider.resolve(const ImageConfiguration());
    _imageStream = stream;
    _imageListener = ImageStreamListener((ImageInfo info, bool _) {
      if (mounted) {
        setState(() => _woodTexture = info.image);
      }
    });
    stream.addListener(_imageListener!);
  }

  @override
  void dispose() {
    if (_imageStream != null && _imageListener != null) {
      _imageStream!.removeListener(_imageListener!);
    }
    super.dispose();
  }

  // ------------------------------------------------------------ token sync

  void _syncTokens(GameUiState ui) {
    if (ui.revision == _processedRevision) return;
    final firstSync = _processedRevision < 0;
    _processedRevision = ui.revision;

    final action = ui.lastAction;
    switch (action) {
      case GameStarted():
        _rebuildTokens(ui);
      case MoveApplied():
        _applyForward(action.move);
      case MoveUndone():
        _applyReverse(action.move);
      case OpeningRolled():
      case DiceRolled():
      case TurnEndedAction():
      case GameFinished():
        break;
      case null:
        if (firstSync) _rebuildTokens(ui);
    }

    if (!_tokensMatchPosition(ui)) {
      // Safety net (e.g. after restoring a saved game).
      _rebuildTokens(ui);
    }
  }

  void _rebuildTokens(GameUiState ui) {
    _tokens.clear();
    final position = ui.game.position;
    var order = 0.0;
    for (var p = 1; p <= 24; p++) {
      final owner = position.ownerAt(p);
      if (owner == null) continue;
      for (var i = 0; i < position.countAt(p); i++) {
        _tokens.add(
          _CheckerToken(
            id: _nextTokenId++,
            player: owner,
            location: p,
            order: order++,
          ),
        );
      }
    }
    for (var i = 0; i < position.whiteBar; i++) {
      _tokens.add(
        _CheckerToken(
          id: _nextTokenId++,
          player: Player.white,
          location: kBarFrom,
          order: order++,
        ),
      );
    }
    for (var i = 0; i < position.blackBar; i++) {
      _tokens.add(
        _CheckerToken(
          id: _nextTokenId++,
          player: Player.black,
          location: kBarFrom,
          order: order++,
        ),
      );
    }
    for (var i = 0; i < position.whiteOff; i++) {
      _tokens.add(
        _CheckerToken(
          id: _nextTokenId++,
          player: Player.white,
          location: kBearOffTo,
          order: order++,
        ),
      );
    }
    for (var i = 0; i < position.blackOff; i++) {
      _tokens.add(
        _CheckerToken(
          id: _nextTokenId++,
          player: Player.black,
          location: kBearOffTo,
          order: order++,
        ),
      );
    }
  }

  bool _tokensMatchPosition(GameUiState ui) {
    final position = ui.game.position;
    final perLocation = <int, int>{};
    for (final token in _tokens) {
      perLocation[token.location] = (perLocation[token.location] ?? 0) + 1;
    }
    for (var p = 1; p <= 24; p++) {
      if ((perLocation[p] ?? 0) != position.countAt(p)) return false;
    }
    if ((perLocation[kBarFrom] ?? 0) != position.whiteBar + position.blackBar) {
      return false;
    }
    if ((perLocation[kBearOffTo] ?? 0) != position.whiteOff + position.blackOff) {
      return false;
    }
    return true;
  }

  /// The topmost token of [player] standing on [location], or null.
  _CheckerToken? _topToken(int location, Player player) {
    _CheckerToken? best;
    for (final token in _tokens) {
      if (token.location == location && token.player == player) {
        if (best == null || token.order > best.order) best = token;
      }
    }
    return best;
  }

  double _maxOrder(int location, Player player) =>
      _topToken(location, player)?.order ?? -1;

  void _applyForward(SingleMove move) {
    if (move.hits) {
      final victim = _topToken(move.to, move.player.opponent);
      if (victim != null) {
        victim.location = kBarFrom;
        victim.order = _maxOrder(kBarFrom, move.player.opponent) + 1;
        victim.hopKey++;
      }
    }
    final mover = _topToken(move.from, move.player);
    if (mover != null) {
      mover.location = move.to;
      mover.order = _maxOrder(move.to, move.player) + 1;
      mover.hopKey++;
    }
  }

  void _applyReverse(SingleMove move) {
    final moved = _topToken(move.to, move.player);
    if (moved != null) {
      moved.location = move.from;
      moved.order = _maxOrder(move.from, move.player) + 1;
      moved.hopKey++;
    }
    if (move.hits) {
      final onBar = _topToken(kBarFrom, move.player.opponent);
      if (onBar != null) {
        onBar.location = move.to;
        onBar.order = 0;
        onBar.hopKey++;
      }
    }
  }

  // ------------------------------------------------------------- building

  @override
  Widget build(BuildContext context) {
    final ui = ref.watch(gameControllerProvider);
    final settings = ref.watch(settingsProvider);
    _syncTokens(ui);

    final theme = settings.boardTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = Size(constraints.maxWidth, constraints.maxHeight);
        final geometry = BoardGeometry(size: boardSize);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) => _handleTap(details.localPosition, ui, geometry),
          onPanStart: (details) =>
              _handleDragStart(details.localPosition, ui, geometry),
          onPanUpdate: (details) => _handleDragUpdate(details.localPosition),
          onPanEnd: (details) => _handleDragEnd(ui, geometry),
          onPanCancel: () => _cancelDrag(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(geometry.frame * 1.4),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                RepaintBoundary(
                  child: CustomPaint(
                    isComplex: true,
                    willChange: false,
                    size: boardSize,
                    painter: BoardPainter(
                      theme: theme,
                      woodTexture: _woodTexture,
                    ),
                  ),
                ),
                ..._buildCheckers(ui, geometry, theme),
                ..._buildHintDots(ui, geometry, theme),
                _buildDiceLayer(ui, geometry),
              ],
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------- checkers

  List<Widget> _buildCheckers(
    GameUiState ui,
    BoardGeometry geometry,
    BoardThemeData theme,
  ) {
    final widgets = <Widget>[];
    final movable = ui.game.phase == GamePhase.awaitingMove &&
        !ui.aiOnTurn &&
        !ui.diceRolling;
    final selectable = movable ? ui.legal.selectableFroms : const <int>[];

    // Rank tokens per (location, player).
    final groups = <String, List<_CheckerToken>>{};
    _tokenRanks.clear();
    final sorted = List<_CheckerToken>.from(_tokens)
      ..sort((a, b) => a.order.compareTo(b.order));
    for (final token in sorted) {
      final key = '${token.location}-${token.player.name}';
      final group = groups.putIfAbsent(key, () => <_CheckerToken>[]);
      _tokenRanks[token.id] = group.length;
      group.add(token);
    }

    for (final token in sorted) {
      final key = '${token.location}-${token.player.name}';
      final group = groups[key]!;
      final rank = _tokenRanks[token.id] ?? 0;
      if (_usesCappedStack(token.location) &&
          group.length > _maxVisibleStackCheckers &&
          rank >= _maxVisibleStackCheckers - 1) {
        continue;
      }

      final isDraggedOrigin = _dragFrom != null &&
          token.location == _dragFrom &&
          token == _topToken(_dragFrom!, _dragPlayer ?? token.player);
      Rect rect;
      Widget face;

      if (token.location == kBearOffTo) {
        rect = geometry.borneOffRect(token.player, rank);
        face = _buildSlab(token.player, theme);
      } else {
        final center = token.location == kBarFrom
            ? geometry.barCheckerCenter(token.player, rank)
            : geometry.checkerCenter(token.location, rank);
        final d = geometry.checkerDiameter;
        rect = Rect.fromCenter(center: center, width: d, height: d);

        final isMovable =
            movable &&
            selectable.contains(token.location) &&
            (ui.selectedFrom == null || ui.selectedFrom == token.location) &&
            _isTopOfStack(token);
        final isSelected = ui.selectedFrom == token.location && isMovable;

        Widget faceWidget = CheckerFace(
          player: token.player,
          theme: theme,
          state: isSelected
              ? CheckerVisualState.selected
              : isMovable
                  ? CheckerVisualState.movable
                  : CheckerVisualState.normal,
        );
        if (isMovable && !isSelected) {
          faceWidget = MovableChecker(
            child: faceWidget,
            color: theme.hintColor,
          );
        } else if (isSelected) {
          faceWidget = faceWidget
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .boxShadow(
                end: BoxShadow(
                  color: theme.hintColor.withAlpha(150),
                  blurRadius: 22,
                  spreadRadius: 4,
                  offset: Offset.zero,
                ),
                duration: 700.ms,
                curve: Curves.easeInOut,
              );
        }
        face = faceWidget;
      }

      final hopKey = token.hopKey;
      widgets.add(
        AnimatedPositioned(
          key: ValueKey('checker-${token.id}'),
          duration: const Duration(milliseconds: 340),
          curve: Curves.easeOutCubic,
          left: rect.left,
          top: rect.top,
          width: rect.width,
          height: rect.height,
          child: _HopWrapper(
            hopKey: hopKey,
            child: Visibility(
              visible: !(isDraggedOrigin && token.location != kBearOffTo),
              maintainState: true,
              maintainAnimation: true,
              maintainSize: true,
              maintainSemantics: false,
              maintainInteractivity: false,
              child: face,
            ),
          ),
        ),
      );
    }

    // Represent any excess checkers with a count marker instead of letting
    // their stack spill into the middle band or the opposing point.
    for (final group in groups.values) {
      final first = group.first;
      if (!_usesCappedStack(first.location) ||
          group.length <= _maxVisibleStackCheckers) {
        continue;
      }
      final count = group.length -
          (_dragFrom == first.location && _dragPlayer == first.player ? 1 : 0);
      if (count < _maxVisibleStackCheckers) continue;

      final index = _maxVisibleStackCheckers - 1;
      final center = first.location == kBarFrom
          ? geometry.barCheckerCenter(first.player, index)
          : geometry.checkerCenter(first.location, index);
      final badgeSize = geometry.checkerDiameter * 0.82;
      final isMovable =
          movable &&
          selectable.contains(first.location) &&
          (ui.selectedFrom == null || ui.selectedFrom == first.location);
      final isSelected = ui.selectedFrom == first.location && isMovable;
      widgets.add(
        Positioned(
          left: center.dx - badgeSize / 2,
          top: center.dy - badgeSize / 2,
          width: badgeSize,
          height: badgeSize,
          child: IgnorePointer(
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppPalette.gold,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isMovable ? theme.hintColor : AppPalette.goldDark,
                  width: isSelected ? 2.2 : 1.2,
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0x99000000), blurRadius: 4),
                ],
              ),
              child: Text(
                PersianDigits.format(count),
                maxLines: 1,
                style: TextStyle(
                  color: AppPalette.darkerBrown,
                  fontSize: badgeSize * 0.38,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Floating checker under the finger while dragging.
    if (_dragFrom != null && _dragPointer != null && _dragPlayer != null) {
      final d = geometry.checkerDiameter;
      widgets.add(
        Positioned(
          left: _dragPointer!.dx - d / 2,
          top: _dragPointer!.dy - d * 0.9,
          width: d,
          height: d,
          child: IgnorePointer(
            child: CheckerFace(
              player: _dragPlayer!,
              theme: theme,
              state: CheckerVisualState.selected,
            )
                .animate()
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.18, 1.18),
                  duration: 120.ms,
                ),
          ),
        ),
      );
    }

    return widgets;
  }

  bool _usesCappedStack(int location) =>
      location == kBarFrom || (location >= 1 && location <= 24);

  final Map<int, int> _tokenRanks = {};

  bool _isTopOfStack(_CheckerToken token) =>
      _topToken(token.location, token.player) == token;

  Widget _buildSlab(Player player, BoardThemeData theme) {
    final isWhite = player == Player.white;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isWhite
              ? [theme.whiteCheckerTop, theme.whiteCheckerBottom]
              : [theme.blackCheckerTop, theme.blackCheckerBottom],
        ),
        border: Border.all(
          color: isWhite ? theme.whiteCheckerRing : theme.blackCheckerRing,
          width: 0.8,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 2),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- hints

  List<Widget> _buildHintDots(
    GameUiState ui,
    BoardGeometry geometry,
    BoardThemeData theme,
  ) {
    final selectedFrom = ui.selectedFrom;
    if (ui.game.phase != GamePhase.awaitingMove ||
        ui.aiOnTurn ||
        selectedFrom == null) {
      return const <Widget>[];
    }

    final pathsByDestination = <int, List<SingleMove>>{};
    final hitDestinations = <int>{};
    for (final path in ui.legal.movePathsFrom(selectedFrom)) {
      final destination = path.last.to;
      final current = pathsByDestination[destination];
      if (current == null || path.length < current.length) {
        pathsByDestination[destination] = path;
      }
      if (path.last.hits) hitDestinations.add(destination);
    }

    final widgets = <Widget>[];
    final d = geometry.checkerDiameter;

    for (final entry in pathsByDestination.entries) {
      final destination = entry.key;
      final pathLength = entry.value.length;
      final isHit = hitDestinations.contains(destination);
      final color = isHit ? AppPalette.rubyAccent : theme.hintColor;

      if (destination == kBearOffTo) {
        final tray = ui.game.current == Player.white
            ? geometry.rightTrayRect
            : geometry.leftTrayRect;
        widgets.add(
          Positioned.fromRect(
            rect: tray,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(tray.width * 0.3),
                  border: Border.all(color: color, width: 2.4),
                  color: const Color(0x22FFD54F),
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .fadeIn(duration: 600.ms)
                  .fadeOut(duration: 600.ms),
            ),
          ),
        );
        continue;
      }

      final stackSize = ui.game.position.countFor(ui.game.current, destination);
      final blotHere = ui.game.position.countFor(
            ui.game.current.opponent,
            destination,
          ) ==
          1;
      final index = blotHere
          ? 1
          : (stackSize < _maxVisibleStackCheckers - 1
              ? stackSize
              : _maxVisibleStackCheckers - 1);
      final center = geometry.checkerCenter(destination, index);
      final hasOverflowCount = stackSize > _maxVisibleStackCheckers;
      final showPathLength = pathLength > 1 && !hasOverflowCount;
      final markerScale = hasOverflowCount
          ? 1.12
          : pathLength > 1
              ? 0.68
              : 0.44;
      final markerSize = d * markerScale;

      widgets.add(
        Positioned(
          left: center.dx - markerSize / 2,
          top: center.dy - markerSize / 2,
          width: markerSize,
          height: markerSize,
          child: IgnorePointer(
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasOverflowCount ? color.withAlpha(35) : null,
                gradient: hasOverflowCount
                    ? null
                    : RadialGradient(colors: [
                        color,
                        Color.lerp(color, Colors.black, 0.35)!,
                      ]),
                border: hasOverflowCount || pathLength > 1
                    ? Border.all(
                        color: hasOverflowCount ? color : AppPalette.ivory,
                        width: hasOverflowCount ? 2.2 : 1.2,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(color: color, blurRadius: d * 0.3),
                ],
              ),
              child: showPathLength
                  ? Text(
                      PersianDigits.format(pathLength),
                      style: TextStyle(
                        color: AppPalette.darkerBrown,
                        fontSize: markerSize * 0.46,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    )
                  : null,
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(0.85, 0.85),
                  end: const Offset(1.15, 1.15),
                  duration: 700.ms,
                  curve: Curves.easeInOut,
                ),
          ),
        ),
      );
    }
    return widgets;
  }

  // ------------------------------------------------------------- dice

  Widget _buildDiceLayer(GameUiState ui, BoardGeometry geometry) {
    final game = ui.game;

    final showOpeningResult =
        game.phase == GamePhase.awaitingRoll && ui.openingResultPending;

    // Opening roll: show both dice through the winner announcement pause.
    if (game.phase == GamePhase.openingRoll || showOpeningResult) {
      final centers = geometry.diceCenters();
      final values = [
        ui.openingWhiteDie ?? 1,
        ui.openingBlackDie ?? 1,
      ];
      return _buildOpeningDice(ui, centers, values, geometry);
    }

    if (game.dice == null && !ui.diceRolling) return const SizedBox.shrink();

    final centers = geometry.diceCenters();
    final values = ui.diceRolling
        ? const [1, 1]
        : [game.dice!.first, game.dice!.second];

    final pair = DicePairView(
      size: geometry.diceSize,
      values: values,
      rolling: ui.diceRolling,
      ivoryAccent: game.current == Player.white,
    );

    // Center the whole pair (two dice plus their gap) between the two
    // computed die centers.
    final pairWidth = geometry.diceSize * 2.42;
    final midX = (centers[0].dx + centers[1].dx) / 2;
    return Positioned(
      left: midX - pairWidth / 2,
      top: centers[0].dy - geometry.diceSize / 2,
      child: IgnorePointer(child: pair),
    );
  }

  Widget _buildOpeningDice(
    GameUiState ui,
    List<Offset> centers,
    List<int> values,
    BoardGeometry geometry,
  ) {
    final size = geometry.diceSize;
    return Stack(
      children: [
        for (var i = 0; i < 2; i++)
          Positioned(
            left: centers[i].dx - size / 2,
            top: centers[i].dy - size / 2,
            child: IgnorePointer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _OpeningDie(
                    value: values[i],
                    size: size,
                    isWhite: i == 0,
                    rolling: ui.openingRolling,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: i == 0
                          ? AppPalette.ivory
                          : AppPalette.darkerBrown,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppPalette.goldDark),
                    ),
                    child: Text(
                      i == 0 ? 'سفید' : 'مشکی',
                      style: TextStyle(
                        fontSize: size * 0.16,
                        color: i == 0 ? AppPalette.darkerBrown : AppPalette.ivory,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------- interactions

  void _handleTap(Offset local, GameUiState ui, BoardGeometry geometry) {
    final controller = ref.read(gameControllerProvider.notifier);

    if (ui.game.phase == GamePhase.openingRoll &&
        !ui.openingRolling &&
        !ui.openingResultPending) {
      controller.rollOpening();
      return;
    }
    if (ui.game.phase == GamePhase.awaitingRoll &&
        !ui.aiOnTurn &&
        !ui.diceRolling) {
      controller.rollDice();
      return;
    }
    if (ui.game.phase != GamePhase.awaitingMove || ui.aiOnTurn) return;

    final hit = geometry.hitTest(local);
    final location = _locationFromHit(hit, ui);
    if (location == null) return;

    if (ui.selectedFrom == null) {
      if (ui.legal.selectableFroms.contains(location)) {
        controller.selectChecker(location);
      }
      return;
    }

    if (location == ui.selectedFrom) {
      controller.selectChecker(null);
      return;
    }

    final path = ui.legal.pathTo(ui.selectedFrom!, location);
    if (path != null) {
      controller.playMove(ui.selectedFrom!, location);
      return;
    }

    // Tapping another movable checker switches the selection.
    if (ui.legal.selectableFroms.contains(location)) {
      controller.selectChecker(location);
    } else {
      controller.selectChecker(null);
    }
  }

  int? _locationFromHit(BoardHit hit, GameUiState ui) {
    if (hit.isPoint) return hit.point;
    if (hit.isBar) return kBarFrom;
    if (hit.isTray) {
      // Only the acting player's tray is a bear-off target.
      final isWhiteTray = hit.trayIsRight;
      final playerIsWhite = ui.game.current == Player.white;
      if (isWhiteTray == playerIsWhite) return kBearOffTo;
      return null;
    }
    return null;
  }

  void _handleDragStart(Offset local, GameUiState ui, BoardGeometry geometry) {
    if (ui.game.phase != GamePhase.awaitingMove || ui.aiOnTurn) return;
    final hit = geometry.hitTest(local);
    final location = _locationFromHit(hit, ui);
    if (location == null) return;
    final selectedFrom = ui.selectedFrom;
    final isSelectedDestination = selectedFrom != null &&
        ui.legal.pathTo(selectedFrom, location) != null;
    final from = isSelectedDestination ? selectedFrom : location;
    if (!isSelectedDestination &&
        !ui.legal.selectableFroms.contains(location)) {
      return;
    }

    setState(() {
      _dragFrom = from;
      _dragPlayer = ui.game.current;
      _dragPointer = local;
      _dragHopKey++;
    });
    if (!isSelectedDestination) {
      ref.read(gameControllerProvider.notifier).selectChecker(from);
    }
  }

  void _handleDragUpdate(Offset local) {
    if (_dragFrom == null) return;
    setState(() => _dragPointer = local);
  }

  void _handleDragEnd(GameUiState ui, BoardGeometry geometry) {
    if (_dragFrom == null) return;
    final from = _dragFrom!;
    final pointer = _dragPointer;
    setState(() {
      _dragFrom = null;
      _dragPointer = null;
      _dragPlayer = null;
    });

    if (pointer == null) return;
    final hit = geometry.hitTest(pointer);
    final location = _locationFromHit(hit, ui);
    if (location == null || location == from) return;

    ref.read(gameControllerProvider.notifier).playMove(from, location);
  }

  void _cancelDrag() {
    if (_dragFrom == null) return;
    setState(() {
      _dragFrom = null;
      _dragPointer = null;
      _dragPlayer = null;
    });
  }
}

/// Adds a small "hop" (scale + shadow) whenever [hopKey] changes.
class _HopWrapper extends StatefulWidget {
  const _HopWrapper({required this.hopKey, required this.child});

  final int hopKey;
  final Widget child;

  @override
  State<_HopWrapper> createState() => _HopWrapperState();
}

class _HopWrapperState extends State<_HopWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
  }

  @override
  void didUpdateWidget(_HopWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hopKey != oldWidget.hopKey) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final lift = Curves.easeOutCubic.transform(t) *
            (1 - Curves.easeInCubic.transform(t));
        final scale = 1 + 0.16 * lift;
        return Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A single die used in the opening roll presentation.
class _OpeningDie extends StatefulWidget {
  const _OpeningDie({
    required this.value,
    required this.size,
    required this.isWhite,
    required this.rolling,
  });

  final int value;
  final double size;
  final bool isWhite;
  final bool rolling;

  @override
  State<_OpeningDie> createState() => _OpeningDieState();
}

class _OpeningDieState extends State<_OpeningDie> {
  Timer? _timer;
  int _display = 1;

  @override
  void initState() {
    super.initState();
    _display = widget.value;
    _sync();
  }

  @override
  void didUpdateWidget(_OpeningDie oldWidget) {
    super.didUpdateWidget(oldWidget);
    _display = widget.value;
    _sync();
  }

  void _sync() {
    if (widget.rolling) {
      _timer ??= Timer.periodic(const Duration(milliseconds: 70), (timer) {
        if (mounted) {
          setState(() => _display = DateTime.now().microsecond % 6 + 1);
        }
      });
    } else {
      _timer?.cancel();
      _timer = null;
      _display = widget.value;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget die = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.size * 0.22),
        border: Border.all(
          color: widget.isWhite ? AppPalette.ivory : AppPalette.gold,
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x99000000), blurRadius: 8),
        ],
      ),
      child: CustomPaint(
        painter: _OpeningDiePainter(value: _display),
        child: const SizedBox.expand(),
      ),
    );
    if (widget.rolling) {
      die = die
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .rotate(
              // In turns; ~6 degrees of wobble while rolling.
              begin: -0.017,
              end: 0.017,
              duration: 150.ms,
            );
    }
    return die;
  }
}

class _OpeningDiePainter extends CustomPainter {
  _OpeningDiePainter({required this.value});

  final int value;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size.width * 0.22),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7EFDE), Color(0xFFE6D9BC), Color(0xFFC9B98F)],
        ).createShader(rect),
    );

    final pips = _pipOffsets(value);
    final pipRadius = size.width * 0.085;
    for (final relative in pips) {
      canvas.drawCircle(
        Offset(relative.dx * size.width, relative.dy * size.height),
        pipRadius,
        Paint()..color = const Color(0xFF33221A),
      );
    }
  }

  List<Offset> _pipOffsets(int value) {
    switch (value) {
      case 1:
        return const [Offset(0.5, 0.5)];
      case 2:
        return const [Offset(0.26, 0.26), Offset(0.74, 0.74)];
      case 3:
        return const [
          Offset(0.25, 0.25),
          Offset(0.5, 0.5),
          Offset(0.75, 0.75),
        ];
      case 4:
        return const [
          Offset(0.27, 0.27),
          Offset(0.73, 0.27),
          Offset(0.27, 0.73),
          Offset(0.73, 0.73),
        ];
      case 5:
        return const [
          Offset(0.26, 0.26),
          Offset(0.74, 0.26),
          Offset(0.5, 0.5),
          Offset(0.26, 0.74),
          Offset(0.74, 0.74),
        ];
      default:
        return const [
          Offset(0.27, 0.22),
          Offset(0.73, 0.22),
          Offset(0.27, 0.5),
          Offset(0.73, 0.5),
          Offset(0.27, 0.78),
          Offset(0.73, 0.78),
        ];
    }
  }

  @override
  bool shouldRepaint(_OpeningDiePainter oldDelegate) =>
      oldDelegate.value != value;
}
