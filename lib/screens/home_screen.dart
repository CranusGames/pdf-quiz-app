import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:io';
import '../services/gemini_service.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _fileName;
  String? _pdfText;
  bool _isLoading = false;
  int _questionCount = 5;
  final _gemini = GeminiService();

  Future<void> _pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.single.path == null) return;

    setState(() => _isLoading = true);

    try {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();

      final document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);
      final text = extractor.extractText();
      document.dispose();

      setState(() {
        _fileName = result.files.single.name;
        _pdfText = text;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF okunamadı: $e')),
        );
      }
    }
  }

  Future<void> _generateQuiz() async {
    if (_pdfText == null) return;

    setState(() => _isLoading = true);

    try {
      final questions = await _gemini.generateQuestions(_pdfText!, _questionCount);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Soru üretilemedi. API key\'i kontrol et.')),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizScreen(questions: questions, pdfName: _fileName!),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('PDF Quiz'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('İşleniyor...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Icon(
                    Icons.picture_as_pdf,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PDF\'den Soru Üret',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PDF yükle, yapay zeka soru üretsin, quiz çöz!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _PdfCard(
                    fileName: _fileName,
                    onTap: _pickPdf,
                  ),
                  if (_pdfText != null) ...[
                    const SizedBox(height: 32),
                    Text(
                      'Kaç soru üretilsin?',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _QuestionCountSelector(
                      value: _questionCount,
                      onChanged: (v) => setState(() => _questionCount = v),
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: _generateQuiz,
                      icon: const Icon(Icons.auto_awesome),
                      label: Text('$_questionCount Soru Üret ve Başla'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _PdfCard extends StatelessWidget {
  final String? fileName;
  final VoidCallback onTap;

  const _PdfCard({this.fileName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFile = fileName != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasFile
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: hasFile ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          color: hasFile
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : theme.colorScheme.surfaceContainerHighest,
        ),
        child: Column(
          children: [
            Icon(
              hasFile ? Icons.check_circle : Icons.upload_file,
              size: 48,
              color: hasFile
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              hasFile ? fileName! : 'PDF Seç',
              style: theme.textTheme.titleMedium?.copyWith(
                color: hasFile
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (!hasFile) ...[
              const SizedBox(height: 4),
              Text(
                'Dokunarak PDF dosyası seç',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuestionCountSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _QuestionCountSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = [5, 10, 15, 20];

    return Row(
      children: options.map((count) {
        final selected = value == count;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onChanged(count),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: selected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
