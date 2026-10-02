import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'formation_content.dart';

/// Lecture d'un module, un écran à la fois : les leçons, puis le quiz de
/// fin de module (une mise en situation par écran, avec explication dès
/// qu'une réponse est choisie — bonne ou mauvaise), puis la synthèse
/// "L'essentiel à retenir". Remplace l'ancien empilement de tout le
/// contenu dans des accordéons sur une seule page, jugé pas assez agréable
/// à lire. Même principe que [OnboardingSheet] (puces de progression,
/// Précédent/Continuer) mais en plein écran : le contenu est trop long
/// pour une feuille, et une vraie page permet de défiler sans perdre sa
/// place dans le reste du module.
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
  int get _lessonCount => _module.lessons.length;
  int get _quizCount => _module.quiz.length;
  // Leçons, puis quiz, puis toujours un dernier écran de synthèse
  // "L'essentiel à retenir".
  int get _totalPages => _lessonCount + _quizCount + 1;
  bool get _onTakeawaysPage => _page == _lessonCount + _quizCount;

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
              if (index < _lessonCount) {
                return _LessonPage(lesson: module.lessons[index], module: module, index: index);
              }
              if (index < _lessonCount + _quizCount) {
                final quizIndex = index - _lessonCount;
                return _QuizPage(
                  key: ValueKey('quiz-$quizIndex'),
                  question: module.quiz[quizIndex],
                  module: module,
                  index: quizIndex,
                  total: _quizCount,
                );
              }
              return _TakeawaysPage(module: module);
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
    final onQuizPage = !_onTakeawaysPage && _page >= _lessonCount;
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
            label: Text(isLast ? 'Terminer le module' : (onQuizPage ? 'Question suivante' : 'Leçon suivante')),
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

/// Une question de quiz — garde l'option choisie en état local (`_picked`)
/// pour afficher son explication et sa couleur (vert/rouge) sans jamais
/// verrouiller la réponse : on peut changer d'avis et comparer plusieurs
/// options avant de passer à la suite, plutôt qu'une seule tentative qui
/// bloquerait la lecture si on se trompe.
class _QuizPage extends StatefulWidget {
  final FormationQuizQuestion question;
  final FormationModule module;
  final int index;
  final int total;
  const _QuizPage({super.key, required this.question, required this.module, required this.index, required this.total});

  @override
  State<_QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<_QuizPage> {
  int? _picked;

  @override
  Widget build(BuildContext context) {
    final color = widget.module.color;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        Row(children: [
          Icon(Icons.quiz_outlined, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            'QUIZ · MISE EN SITUATION ${widget.index + 1}/${widget.total}',
            style: AppTextStyles.mono(fontSize: 11.5, color: color).copyWith(letterSpacing: 1),
          ),
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.paperSecondary,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            widget.question.scenario,
            style: AppTextStyles.sans(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.ink).copyWith(height: 1.55),
          ),
        ),
        const SizedBox(height: 18),
        for (int i = 0; i < widget.question.options.length; i++) _buildOption(i, color),
      ],
    );
  }

  Widget _buildOption(int i, Color color) {
    final option = widget.question.options[i];
    final picked = _picked == i;
    final revealed = _picked != null;
    // Une fois une réponse choisie, la bonne option reste visible en vert
    // même si ce n'est pas celle sélectionnée — pour qu'une mauvaise
    // réponse montre aussi, sans avoir à re-cliquer, laquelle était la
    // bonne.
    final showAsCorrect = revealed && option.correct;
    final showAsWrong = revealed && picked && !option.correct;
    final borderColor = showAsCorrect
        ? AppColors.good
        : showAsWrong
            ? AppColors.alert
            : (picked ? color : AppColors.border);
    final bgColor = showAsCorrect
        ? AppColors.good.withValues(alpha: AppColors.isDark ? 0.18 : 0.08)
        : showAsWrong
            ? AppColors.alert.withValues(alpha: AppColors.isDark ? 0.18 : 0.07)
            : AppColors.surface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => setState(() => _picked = i),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: showAsCorrect || showAsWrong ? 1.5 : 1),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(
                showAsCorrect ? Icons.check_circle : (showAsWrong ? Icons.cancel : Icons.circle_outlined),
                size: 18,
                color: showAsCorrect ? AppColors.good : (showAsWrong ? AppColors.alert : AppColors.ink.withValues(alpha: 0.3)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  option.text,
                  style: AppTextStyles.sans(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.ink).copyWith(height: 1.4),
                ),
              ),
            ]),
            if (revealed && (picked || option.correct)) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Text(
                  option.explanation,
                  style: AppTextStyles.sans(
                    fontSize: 12.5,
                    color: (option.correct ? AppColors.good : AppColors.alert).withValues(alpha: 0.9),
                  ).copyWith(height: 1.5),
                ),
              ),
            ],
          ]),
        ),
      ),
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
