import 'package:test/test.dart';
import 'package:lunr/utils.dart' as lunr;

void main() {
  group('lunr.utils', () {
    group('#clone', () {
      Map? obj;
      Map? clone;

      subject(o) {
        obj = o;
        clone = lunr.Utils.clone(o);
      }

      group('handles null', () {
        test('returns null', () {
          subject(null);
          expect(null, clone);
          expect(obj, clone);
        });
      });

      group('object with primatives', () {
        setUp(() {
          subject({'number': 1, 'string': 'foo', 'bool': true});
        });

        test('clones number correctly', () {
          expect(obj!['number'], clone!['number']);
        });

        test('clones string correctly', () {
          expect(obj!['string'], clone!['string']);
        });

        test('clones bool correctly', () {
          expect(obj!['bool'], clone!['bool']);
        });
      });

      group('object with array property', () {
        setUp(() {
          subject({
            'array': [1, 2, 3]
          });
        });

        test('clones array correctly', () {
          expect(obj!['array'], containsAllInOrder(clone!['array']));
        });

        test('mutations on clone do not affect orginial', () {
          clone!['array'].add(4);
          expect(obj!['array'], isNot(containsAllInOrder(clone!['array'])));
          expect(obj!['array'].length, 3);
          expect(clone!['array'].length, 4);
        });
      });

      group('nested object', () {
        test('throws type error', () {
          expect(() {
            lunr.Utils.clone({
              'foo': {'bar': 1}
            });
          }, throwsA(isA<Exception>()));
        });
      });
    });
  });

  group('Utils warn ', () {
    test('warn runs', () {
      expect(lunr.Utils.warn('test'), null);
    });
  });
  group('Utils asString ', () {
    test('asString converts object to string', () {
      expect(lunr.Utils.asString(123), equals('123'));
    });
  });
}
