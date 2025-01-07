import 'dart:math';

class Word {
  final int index;
  final String word;
  final String phonetic;
  final String partOfSpeech;
  final String meaning;
  final String example;
  bool isMarked;
  bool isBookmarked;

  Word({
    required this.index,
    required this.word,
    required this.phonetic,
    required this.partOfSpeech,
    required this.meaning,
    required this.example,
    this.isMarked = false,
    this.isBookmarked = false,
  });

  factory Word.fromMarkdown(String markdown) {
    try {
      // 分割每行内容
      final lines = markdown.split('\n').where((line) => line.trim().isNotEmpty).toList();
      if (lines.isEmpty) {
        throw FormatException('Empty markdown content');
      }

      // 解析第一行（基本信息）
      final firstLine = lines[0].trim();
      
      // 提取序号
      final indexMatch = RegExp(r'^(\d+)\.').firstMatch(firstLine);
      if (indexMatch == null) {
        throw FormatException('No index found in line: $firstLine');
      }
      final index = int.parse(indexMatch.group(1)!);

      // 提取单词（支持带空格、括号和特殊字符的单词）
      String word = '';
      final afterIndex = firstLine.substring(indexMatch.end).trim();
      
      // 查找音标的开始位置
      final phoneticStart = afterIndex.indexOf('[');
      final phoneticStart2 = afterIndex.indexOf('/');
      final actualPhoneticStart = phoneticStart != -1 ? phoneticStart : 
                                 phoneticStart2 != -1 ? phoneticStart2 : -1;
      
      if (actualPhoneticStart != -1) {
        word = afterIndex.substring(0, actualPhoneticStart).trim();
      } else {
        // 如果没有音标，查找词性标记
        final posStart = afterIndex.lastIndexOf(RegExp(r'\s+\S+\.'));
        if (posStart != -1) {
          word = afterIndex.substring(0, posStart).trim();
        }
      }
      
      if (word.isEmpty) {
        throw FormatException('No word found in line: $firstLine');
      }

      // 提取音标（支持[]和//格式）
      String phonetic = '';
      final phoneticMatch = RegExp(r'[\[/](.*?)[\]/]').firstMatch(firstLine);
      if (phoneticMatch != null) {
        phonetic = phoneticMatch.group(1)!.trim();
      }

      // 提取词性（支持更多词性和完整词性）
      String partOfSpeech = '';
      // 先尝试匹配完整词性
      final fullPosMatch = RegExp(r'\]\s+(\w+)\.$').firstMatch(firstLine);
      if (fullPosMatch != null) {
        partOfSpeech = fullPosMatch.group(1)!;
      } else {
        // 再尝试匹配简写词性
        final shortPosMatch = RegExp(r'(?:v\.|n\.|adj\.|adv\.|prep\.|conj\.|pron\.|det\.|indefinite\.)').firstMatch(firstLine);
        if (shortPosMatch != null) {
          partOfSpeech = shortPosMatch.group(0)!.replaceAll('.', '');
        }
      }

      // 提取含义（改进的逻辑）
      String meaning = '';
      final afterPos = firstLine.indexOf(partOfSpeech + '.');
      if (afterPos != -1) {
        final meaningStart = afterPos + (partOfSpeech + '.').length;
        // 查找可能的结束标记
        final possibleEnds = [
          firstLine.indexOf(r'$\spadesuit$', meaningStart),
          firstLine.indexOf('◆', meaningStart),
          firstLine.length
        ].where((pos) => pos != -1).toList();
        
        // 使用最近的结束标记
        final meaningEnd = possibleEnds.isEmpty ? firstLine.length : possibleEnds.reduce(min);
        meaning = firstLine.substring(meaningStart, meaningEnd).trim();
      }

      // 查找例句（优先选择第一个e.g.开头的句子）
      String example = '';
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.toLowerCase().contains('e.g.')) {
          example = line;
          break;
        }
      }

      // 如果没有找到e.g.开头的例句，尝试其他格式
      if (example.isEmpty) {
        for (int i = 1; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.startsWith('◆') || line.startsWith('例：')) {
            example = line;
            break;
          }
        }
      }

      return Word(
        index: index,
        word: word,
        phonetic: phonetic,
        partOfSpeech: partOfSpeech,
        meaning: meaning,
        example: example,
      );
    } catch (e) {
      print('Error parsing markdown:\n$markdown');
      print('Error details: $e');
      rethrow;
    }
  }
} 