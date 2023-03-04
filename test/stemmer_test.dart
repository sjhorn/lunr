import 'dart:convert';
import 'dart:io';
import 'package:lunr/pipeline.dart';
import 'package:lunr/token.dart';
import 'package:test/test.dart';
import 'package:lunr/stemmer.dart' as lunr;

withFixture(String file, Function(Exception? err, String fixture) func) {
  try {
    String json =
        File('${Directory.current.path}/test/fixture/$file').readAsStringSync();
    func(null, json);
  } on Exception catch (e) {
    func(e, '');
  }
}

void main() {
  group('lunr.stemmer', () {
    group('reduces words to their stem #', () {
      withFixture('stemming_vocab.json', (err, fixture) {
        if (err != null) {
          throw err;
        }

        Map<String, dynamic> testData = json.decode(fixture);

        for (var word in testData.keys) {
          var expected = testData[word],
              token = Token(word),
              result = lunr.stemmer(token, 0, []).toString();
          test('$word to $expected', () {
            expect(result, equals(expected), reason: 'Comparing $word');
          });
        }
      });
    });

    test('is a registered pipeline function', () {
      Pipeline.registerFunction(lunr.stemmer, 'stemmer');
      //expect('stemmer',equals(lunr.stemmer.label))
      expect(lunr.stemmer, equals(Pipeline.registeredFunctions['stemmer']));
    });
  });
}
