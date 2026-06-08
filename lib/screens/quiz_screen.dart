import 'package:flutter/material.dart';
import '../models/question.dart';

class QuizScreen extends StatefulWidget {
  final List<Question> questions;
  final String pdfName;

  const QuizScreen({super.key, required this.questions, required this.pdfName});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _current = 0;
  int? _selected;
  bool _answered = false;
  int _score = 0;
  bool _finished = false;

  void _selectOption(int index) {
    if (_answered) return;
    setState(() {
      _selected = index;
      _answered = true;
      if (index == widget.questions[_current].correctIndex) {
        _score++;
      }
    });
  }

  void _next() {
    if (_current < widget.questions.length - 1) {
      setState(() {
        _current++;
        _selected = null;
        _answered = false;
      });
    } else {
      setState(() => _finished = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return _ResultScreen(score: _score, total: widget.questions.length);

    final q = widget.questions[_current];
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pdfName, overflow: TextOverflow.ellipsis),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: (_current + 1) / widget.questions.length,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation(theme.colorScheme.onPrimary),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text(
              'Soru ${_current + 1} / ${widget.questions.length}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  q.question,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ...List.generate(q.options.length, (i) {
              return _OptionTile(
                label: String.fromCharCode(65 + i),
                text: q.options[i],
                state: _answered
                    ? i == q.correctIndex
                        ? _OptionState.correct
                        : i == _selected
                            ? _OptionState.wrong
                            : _OptionState.neutral
                    : _selected == i
                        ? _OptionState.selected
                        : _OptionState.neutral,
                onTap: () => _selectOption(i),
              );
            }),
            const Spacer(),
            if (_answered)
              FilledButton(
                onPressed: _next,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _current < widget.questions.length - 1
                      ? 'Sonraki Soru →'
                      : 'Sonucu Gör',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _OptionState { neutral, selected, correct, wrong }

class _OptionTile extends StatelessWidget {
  final String label;
  final String text;
  final _OptionState state;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.text,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color bg;
    Color border;
    Color textColor;

    switch (state) {
      case _OptionState.correct:
        bg = Colors.green.shade50;
        border = Colors.green;
        textColor = Colors.green.shade800;
      case _OptionState.wrong:
        bg = Colors.red.shade50;
        border = Colors.red;
        textColor = Colors.red.shade800;
      case _OptionState.selected:
        bg = theme.colorScheme.primaryContainer;
        border = theme.colorScheme.primary;
        textColor = theme.colorScheme.onPrimaryContainer;
      case _OptionState.neutral:
        bg = theme.colorScheme.surfaceContainerHighest;
        border = theme.colorScheme.outlineVariant;
        textColor = theme.colorScheme.onSurface;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: border.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: border,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(color: textColor, height: 1.4),
                ),
              ),
              if (state == _OptionState.correct)
                const Icon(Icons.check_circle, color: Colors.green),
              if (state == _OptionState.wrong)
                const Icon(Icons.cancel, color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultScreen extends StatelessWidget {
  final int score;
  final int total;

  const _ResultScreen({required this.score, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = score / total;
    final emoji = percent >= 0.8 ? '🎉' : percent >= 0.5 ? '👍' : '📚';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sonuç'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 72)),
              const SizedBox(height: 24),
              Text(
                '$score / $total',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                percent >= 0.8
                    ? 'Harika! Çok iyi biliyorsun!'
                    : percent >= 0.5
                        ? 'İyi iş! Biraz daha çalış.'
                        : 'Daha fazla çalışman gerekiyor.',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                icon: const Icon(Icons.home),
                label: const Text('Ana Sayfaya Dön'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
