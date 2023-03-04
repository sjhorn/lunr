import 'package:lunr/pipeline.dart';
import 'package:lunr/token.dart';
import 'package:test/test.dart';
import 'package:lunr/stop_word_filter.dart' as lunr;

void main() {
  group('lunr.stopWordFilter', () {
    test('filters stop words', () {
      var stopWords = ['the', 'and', 'but', 'than', 'when'];

      for (var word in stopWords) {
        expect(lunr.stopWordFilter(Token(word), 0, []), equals(null));
      }
    });

    test('ignores non stop words', () {
      var nonStopWords = ['interesting', 'words', 'pass', 'through'];

      for (var word in nonStopWords) {
        Token? out = lunr.stopWordFilter(Token(word), 0, []);
        expect(word, equals(out.toString()));
      }
    });

    test('ignores properties of Object.prototype', () {
      var nonStopWords = [
        'constructor',
        'hasOwnProperty',
        'toString',
        'valueOf'
      ];

      for (var word in nonStopWords) {
        Token? out = lunr.stopWordFilter(Token(word), 0, []);
        expect(word, equals(out.toString()));
      }
    });

    test('is a registered pipeline function', () {
      //expect('stopWordFilter', equals(lunr.stopWordFilter.label));
      Pipeline.registerFunction(lunr.stopWordFilter, 'stopWordFilter');

      expect(lunr.stopWordFilter,
          equals(Pipeline.registeredFunctions['stopWordFilter']));
    });
  });
}
