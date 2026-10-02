import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'formation_content.dart';

/// Lecture d'un module, une leçon à la fois (plus un dernier écran
/// "L'essentiel à retenir") — remplace l'ancien empilement de tout le
/// contenu dans des accordéons sur une seule page, jugé pas assez agréable
/// à lire. Même principe que [OnboardingSheet] (puces de progression,
/// Précédent/Continuer) mais en plein écran : le contenu d'une leçon est
/// trop long pour une feuille, et une vraie page permet de défiler sans
/// perdre sa place dans le reste du module.
class FormationModuleScreen extends StatefulWidget {
  final int moduleIndex;
  const FormationModuleScreen({super.key, required this.moduleIndex});

  @override
  State<FormationModuleScreen> createState() => _FormationModuleScreenState();
}

class _FormationModuleScreenState extends State<FormationModuleScreen> {
  late final PageController _pageController = PageController();
  int _page = 0;

  FormationModule get _module => formationModules[widget.moduleIndex];
  // +1 : le dernier écran du module est toujours la synthèse "L'essentiel
  // à retenir", pas une leçon comme les autres.
  int get _totalPages => _module.lessons.length + 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _pageController.animateToPage(page, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final module = _module;
    return Scaffold(
      appBar: AppBar(
        title: Text(module.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Column(children: [
        _buildProgressDots(module.color),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _totalPages,
            onPageChanged: (p) => setState(() => _page = p),
            itemBuilder: (context, index) {
              if (index == module.lessons.length) {
                return _TakeawaysPage(module: module);
              }
              return _LessonPage(lesson: module.lessons[index], module: module, index: index);
            },
          ),
        ),
        _buildNavBar(),
      ]),
    );
  }

  Widget _buildProgressDots(Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: List.generate(_totalPages, (i) {
          final active = i == _page;
          final done = i < _page;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: active || done ? color : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNavBar() {
    final isLast = _page == _totalPages - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(color: AppColors.paper, boxShadow: AppShadows.md),
      child: Row(children: [
        if (_page > 0)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton(
              onPressed: () => _goTo(_page - 1),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                side: BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              ),
              child: const Text('Précédent'),
            ),
          ),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isLast ? () => Navigator.of(context).pop() : () => _goTo(_page + 1),
            icon: Icon(isLast ? Icons.check : Icons.arrow_forward, size: 16),
            label: Text(isLast ? 'Terminer le module' : 'Leçon suivante'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _module.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ]),
    );
  }
}

class _LessonPage extends StatelessWidget {
  final FormationLesson lesson;
  final FormationModule module;
  final int index;
  const _LessonPage({required this.lesson, required this.module, required this.index});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        Text(
          'LEÇON ${index + 1}/${module.lessons.length}',
          style: AppTextStyles.mono(fontSize: 11.5, color: module.color).copyWith(letterSpacing: 1),
        ),
        const SizedBox(height: 10),
        Text(
          lesson.title,
          style: AppTextStyles.serif(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink).copyWith(height: 1.3),
        ),
        const SizedBox(height: 18),
        Text(
          lesson.body,
          style: AppTextStyles.sans(fontSize: 14.5, color: AppColors.ink.withValues(alpha: 0.82)).copyWith(height: 1.7),
        ),
      ],
    );
  }
}

class _TakeawaysPage extends StatelessWidget {
  final FormationModule module;
  const _TakeawaysPage({required this.module});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: module.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
          child: Icon(Icons.task_alt, size: 26, color: module.color),
        ),
        const SizedBox(height: 16),
        Text(
          "Module terminé — l'essentiel à retenir",
          style: AppTextStyles.serif(fontSize: 21, fontWeight: FontWeight.w700, color: AppColors.ink).copyWith(height: 1.3),
        ),
        const SizedBox(height: 18),
        for (final point in module.takeaways)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle, size: 18, color: module.color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    point,
                    style: AppTextStyles.sans(fontSize: 14, color: AppColors.ink.withValues(alpha: 0.85)).copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
