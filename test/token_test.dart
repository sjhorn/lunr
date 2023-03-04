import 'package:test/test.dart';
import 'package:lunr/token.dart' as lunr;

void main() {
  group('lunr.Token', () {
    group('#toString', () {
      test('converts the token to a string', () {
        var token = lunr.Token('foo');
        expect('foo', token.toString());
      });
    });

    group('#metadata', () {
      test('can attach arbitrary metadata', () {
        var token = lunr.Token('foo', {'length': 3});
        expect(3, token.metadata!['length']);
      });
    });

    group('#update', () {
      test('can update the token value', () {
        var token = lunr.Token('foo');

        token.update((s, _) {
          return s.toUpperCase();
        });

        expect('FOO', token.toString());
      });

      test('metadata is yielded when updating', () {
        Map<String, dynamic> metadata = {'bar': true};
        lunr.Token token = lunr.Token('foo', metadata);
        late Map<String, dynamic> yieldedMetadata;

        token.update((_, md) {
          yieldedMetadata = md!;
          return _;
        });

        expect(metadata, yieldedMetadata);
      });
    });

    group('#clone', () {
      var token = lunr.Token('foo', {'bar': true});

      test('clones value', () {
        expect(token.toString(), token.clone().toString());
      });

      test('clones metadata', () {
        expect(token.metadata, token.clone().metadata);
      });

      test('clone and modify', () {
        var clone = token.clone((s, _) {
          return s.toUpperCase();
        });

        expect('FOO', clone.toString());
        expect(token.metadata, clone.metadata);
      });
    });
  });
}
