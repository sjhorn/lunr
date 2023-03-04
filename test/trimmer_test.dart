import 'package:lunr/pipeline.dart';
import 'package:test/test.dart';
import 'package:lunr/trimmer.dart' as lunr;

void main() {
  group('lunr.trimmer', () {
    test('latin characters', () {
      var token = lunr.Token('hello');
      expect(lunr.trimmer(token, 0, []).toString(), token.toString());
    });

    group('punctuation', () {
      trimmerTest(description, str, expected) {
        test(description, () {
          var token = lunr.Token(str);
          var trimmed = lunr.trimmer(token, 0, []).toString();

          expect(expected, trimmed);
        });
      }

      trimmerTest('full stop', 'hello.', 'hello');
      trimmerTest('inner apostrophe', "it's", "it's");
      trimmerTest('trailing apostrophe', "james'", 'james');
      trimmerTest('exclamation mark', 'stop!', 'stop');
      trimmerTest('comma', 'first,', 'first');
      trimmerTest('brackets', '[tag]', 'tag');
    });

    test('is a registered pipeline function', () {
      Pipeline.registerFunction(lunr.trimmer, 'trimmer');
      //expect(lunr.trimmer.label, 'trimmer');
      expect(Pipeline.registeredFunctions['trimmer'], lunr.trimmer);
    });
  });
}
