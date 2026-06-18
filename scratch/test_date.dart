DateTime? parseAiDate(String? dateStr) {
  if (dateStr == null || dateStr.trim().isEmpty) return null;
  
  // Tenta parse normal (ISO 8601)
  final parsed = DateTime.tryParse(dateStr);
  if (parsed != null) return parsed;

  final normalized = dateStr.trim().toLowerCase();

  // Datas relativas em português
  if (normalized.contains('amanhã') || normalized.contains('amanha')) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }
  if (normalized.contains('hoje')) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
  if (normalized.contains('ontem')) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - 1);
  }

  // Tenta formato brasileiro DD/MM/YYYY ou DD-MM-YYYY
  final regExpBr = RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})');
  final matchBr = regExpBr.firstMatch(dateStr);
  if (matchBr != null) {
    final day = int.parse(matchBr.group(1)!);
    final month = int.parse(matchBr.group(2)!);
    final year = int.parse(matchBr.group(3)!);
    return DateTime(year, month, day);
  }

  // Tenta formato DD/MM (sem ano)
  final regExpShortBr = RegExp(r'^(\d{1,2})[-/](\d{1,2})$');
  final matchShortBr = regExpShortBr.firstMatch(dateStr.trim());
  if (matchShortBr != null) {
    final day = int.parse(matchShortBr.group(1)!);
    final month = int.parse(matchShortBr.group(2)!);
    final year = DateTime.now().year;
    return DateTime(year, month, day);
  }

  // Tenta formato escrito em português: "19 de junho" ou "19 de junho de 2026"
  final months = {
    'janeiro': 1, 'fev': 2, 'fevereiro': 2, 'março': 3, 'marco': 3,
    'abril': 4, 'maio': 5, 'junho': 6, 'julho': 7, 'agosto': 8,
    'setembro': 9, 'outubro': 10, 'novembro': 11, 'dezembro': 12
  };
  final regExpPt = RegExp(r'^(\d{1,2})\s+de\s+([a-zç]+)(?:\s+de\s+(\d{4}))?');
  final matchPt = regExpPt.firstMatch(normalized);
  if (matchPt != null) {
    final day = int.parse(matchPt.group(1)!);
    final monthStr = matchPt.group(2)!;
    final yearStr = matchPt.group(3);
    final month = months[monthStr];
    if (month != null) {
      final year = yearStr != null ? int.parse(yearStr) : DateTime.now().year;
      return DateTime(year, month, day);
    }
  }

  // Tenta formato YYYY-MM-DD
  final regExpIso = RegExp(r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})');
  final matchIso = regExpIso.firstMatch(dateStr);
  if (matchIso != null) {
    final year = int.parse(matchIso.group(1)!);
    final month = int.parse(matchIso.group(2)!);
    final day = int.parse(matchIso.group(3)!);
    return DateTime(year, month, day);
  }

  return null;
}

void main() {
  final testCases = [
    '2026-06-25T00:00:00.000Z',
    '2026-06-25',
    '25/06/2026',
    '25-06-2026',
    'amanhã',
    'amanha',
    'hoje',
    'ontem',
    '19 de junho',
    '19 de junho de 2026',
    '20 de dezembro',
    '15/08',
    'invalid-date'
  ];

  for (final tc in testCases) {
    print('Input: "$tc" -> Parsed: ${parseAiDate(tc)}');
  }
}
