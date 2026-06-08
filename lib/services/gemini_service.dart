import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/question.dart';

class GeminiService {
  static const _apiKey = 'BURAYA_API_KEY_YAZ';

  Future<List<Question>> generateQuestions(String pdfText, int count) async {
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );

    final prompt = '''
Aşağıdaki metinden $count adet çoktan seçmeli soru üret.
Her soru için 4 şık olsun ve sadece 1 doğru cevap olsun.

Yanıtı SADECE şu JSON formatında ver, başka hiçbir şey yazma:
[
  {
    "question": "Soru metni",
    "options": ["A şıkkı", "B şıkkı", "C şıkkı", "D şıkkı"],
    "correctIndex": 0
  }
]

correctIndex 0-3 arası olmalı (0=A, 1=B, 2=C, 3=D).

Metin:
$pdfText
''';

    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text ?? '';

    return _parseQuestions(text);
  }

  List<Question> _parseQuestions(String text) {
    try {
      final jsonStart = text.indexOf('[');
      final jsonEnd = text.lastIndexOf(']') + 1;
      if (jsonStart == -1 || jsonEnd == 0) return [];

      final jsonStr = text.substring(jsonStart, jsonEnd);

      // Manuel parse (dart:convert import etmeden)
      final questions = <Question>[];
      final pattern = RegExp(
        r'"question"\s*:\s*"([^"]+)".*?"options"\s*:\s*\[([^\]]+)\].*?"correctIndex"\s*:\s*(\d)',
        dotAll: true,
      );

      for (final match in pattern.allMatches(jsonStr)) {
        final question = match.group(1)!;
        final optionsRaw = match.group(2)!;
        final correctIndex = int.parse(match.group(3)!);

        final options = RegExp(r'"([^"]+)"')
            .allMatches(optionsRaw)
            .map((m) => m.group(1)!)
            .toList();

        if (options.length == 4) {
          questions.add(Question(
            question: question,
            options: options,
            correctIndex: correctIndex,
          ));
        }
      }

      return questions;
    } catch (_) {
      return [];
    }
  }
}
