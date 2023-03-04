import 'package:lunr/token.dart';
import 'package:test/test.dart';
import 'package:lunr/tokenizer.dart' as lunr;

class CustomObject {
  @override
  String toString() => "custom object";
}

void main() {
  group('lunr.tokenizer', () {
    toString(o) {
      return o.toString();
    }

    test('splitting into tokens', () {
      var tokens = lunr.tokenizer('foo bar baz').map(toString);

      expect(['foo', 'bar', 'baz'], containsAllInOrder(tokens));
    });

    test('downcases tokens', () {
      var tokens = lunr.tokenizer('Foo BAR BAZ').map(toString);

      expect(['foo', 'bar', 'baz'], containsAllInOrder(tokens));
    });

    test('array of strings', () {
      var tokens = lunr.tokenizer(['foo', 'bar', 'baz']).map(toString);

      expect(['foo', 'bar', 'baz'], containsAllInOrder(tokens));
    });

    test('null is converted to empty string', () {
      var tokens = lunr.tokenizer(['foo', null, 'baz']).map(toString);

      expect(['foo', '', 'baz'], containsAllInOrder(tokens));
    });

    test('multiple white space is stripped', () {
      var tokens = lunr.tokenizer('   foo    bar   baz  ').map(toString);

      expect(['foo', 'bar', 'baz'], containsAllInOrder(tokens));
    });

    test('handling null-like arguments', () {
      expect(lunr.tokenizer(), equals([]));
      expect(lunr.tokenizer(null), equals([]));
    });

    test('converting a date to tokens', () {
      var date = DateTime.utc(2013, 1, 1, 12);

      // NOTE: slicing here to prevent asserting on parts
      // of the date that might be affected by the timezone
      // the test is running in.
      expect(['tue', 'jan', '01', '2013'],
          equals(lunr.tokenizer(date).sublist(0, 4).map(toString)));
    });

    test('converting a number to tokens', () {
      expect('41', equals(lunr.tokenizer(41).map(toString).first));
    });

    test('converting a boolean to tokens', () {
      expect('false', equals(lunr.tokenizer(false).map(toString).first));
    });

    test('converting an object to tokens', () {
      expect(lunr.tokenizer(CustomObject()).map(toString),
          containsAllInOrder(['custom', 'object']));
    });

    test('splits strings with hyphens', () {
      expect(lunr.tokenizer('foo-bar').map(toString),
          containsAllInOrder(['foo', 'bar']));
    });

    test('splits strings with hyphens and spaces', () {
      expect(lunr.tokenizer('foo - bar').map(toString),
          containsAllInOrder(['foo', 'bar']));
    });

    test('tracking the token index', () {
      List<Token> tokens = lunr.tokenizer('foo bar');
      expect(tokens[0].metadata!['index'], 0);
      expect(tokens[1].metadata!['index'], 1);
    });

    test('tracking the token position', () {
      var tokens = lunr.tokenizer('foo bar');
      expect(tokens[0].metadata!['position'], containsAllInOrder([0, 3]));
      expect(tokens[1].metadata!['position'], containsAllInOrder([4, 3]));
    });

    test('tracking the token position with additional left-hand whitespace',
        () {
      var tokens = lunr.tokenizer(' foo bar');
      expect(tokens[0].metadata!['position'], containsAllInOrder([1, 3]));
      expect(tokens[1].metadata!['position'], containsAllInOrder([5, 3]));
    });

    test('tracking the token position with additional right-hand whitespace',
        () {
      var tokens = lunr.tokenizer('foo bar ');
      expect(tokens[0].metadata!['position'], containsAllInOrder([0, 3]));
      expect(tokens[1].metadata!['position'], containsAllInOrder([4, 3]));
    });

    test('providing additional metadata', () {
      var tokens = lunr.tokenizer('foo bar', {'hurp': 'durp'});
      expect(tokens[0].metadata!['hurp'], 'durp');
      expect(tokens[1].metadata!['hurp'], 'durp');
    });
  });
}
