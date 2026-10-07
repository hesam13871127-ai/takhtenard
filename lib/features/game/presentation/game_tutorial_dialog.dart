import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/persian_digits.dart';

/// A short, first-game introduction to the rules and controls.
class GameTutorialDialog extends StatefulWidget {
  const GameTutorialDialog({super.key});

  @override
  State<GameTutorialDialog> createState() => _GameTutorialDialogState();
}

class _GameTutorialDialogState extends State<GameTutorialDialog> {
  static const _steps = <_TutorialStep>[
    _TutorialStep(
      icon: Icons.flag_outlined,
      title: AppStrings.tutorialGoalTitle,
      body: AppStrings.tutorialGoalBody,
    ),
    _TutorialStep(
      icon: Icons.casino_outlined,
      title: AppStrings.tutorialDiceTitle,
      body: AppStrings.tutorialDiceBody,
    ),
    _TutorialStep(
      icon: Icons.touch_app_outlined,
      title: AppStrings.tutorialMoveTitle,
      body: AppStrings.tutorialMoveBody,
    ),
    _TutorialStep(
      icon: Icons.gps_fixed,
      title: AppStrings.tutorialHitTitle,
      body: AppStrings.tutorialHitBody,
    ),
    _TutorialStep(
      icon: Icons.inventory_2,
      title: AppStrings.tutorialBearOffTitle,
      body: AppStrings.tutorialBearOffBody,
    ),
  ];

  int _stepIndex = 0;

  @override
  Widget build(BuildContext context) {
    final step = _steps[_stepIndex];
    final isLastStep = _stepIndex == _steps.length - 1;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.tutorialTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppPalette.ivory,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: (_stepIndex + 1) / _steps.length,
                        minHeight: 4,
                        backgroundColor: AppPalette.panelBorder,
                        color: AppPalette.gold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${PersianDigits.format(_stepIndex + 1)} از '
                    '${PersianDigits.format(_steps.length)}',
                    style: const TextStyle(
                      color: AppPalette.textFaint,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Column(
                  key: ValueKey(_stepIndex),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        color: Color(0x33D4AF37),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(step.icon, color: AppPalette.gold, size: 30),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      step.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppPalette.ivory,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step.body,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppPalette.textSecondary,
                        fontSize: 14,
                        height: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                runSpacing: 4,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text(AppStrings.tutorialSkip),
                  ),
                  if (_stepIndex > 0)
                    TextButton(
                      onPressed: () => setState(() => _stepIndex--),
                      child: const Text(AppStrings.tutorialPrevious),
                    ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppPalette.gold,
                      foregroundColor: AppPalette.darkerBrown,
                    ),
                    onPressed: () {
                      if (isLastStep) {
                        Navigator.of(context).pop(true);
                      } else {
                        setState(() => _stepIndex++);
                      }
                    },
                    child: Text(
                      isLastStep
                          ? AppStrings.tutorialStart
                          : AppStrings.tutorialNext,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorialStep {
  const _TutorialStep({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}
