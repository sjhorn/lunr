import 'package:test/test.dart';
import 'package:lunr/set.dart' as lunr;

void main() {
  group('lunr.Set', () {
    group('#contains', () {
      group('complete set', () {
        test('returns true', () {
          expect(lunr.Set.complete.contains('foo'), equals(true));
        });
      });

      group('empty set', () {
        test('returns false', () {
          expect(lunr.Set.empty.contains('foo'), equals(false));
        });
      });

      group('populated set', () {
        late lunr.Set set;
        setUp(() {
          set = lunr.Set(['foo']);
        });

        test('element contained in set', () {
          expect(set.contains('foo'), equals(true));
        });

        test('element not contained in set', () {
          expect(set.contains('bar'), equals(false));
        });
      });
    });

    group('#union', () {
      late lunr.Set set;
      setUp(() {
        set = lunr.Set(['foo']);
      });

      group('complete set', () {
        test('union is complete', () {
          var result = lunr.Set.complete.union(set);
          expect(result.contains('foo'), equals(true));
          expect(result.contains('bar'), equals(true));
        });
      });

      group('empty set', () {
        test('contains element', () {
          var result = lunr.Set.empty.union(set);
          expect(result.contains('foo'), equals(true));
          expect(result.contains('bar'), equals(false));
        });
      });

      group('populated set', () {
        group('with other populated set', () {
          test('contains both elements', () {
            var target = lunr.Set(['bar']);
            var result = target.union(set);

            expect(result.contains('foo'), equals(true));
            expect(result.contains('bar'), equals(true));
            expect(result.contains('baz'), equals(false));
          });
        });

        group('with empty set', () {
          test('contains all elements', () {
            var target = lunr.Set(['bar']);
            var result = target.union(lunr.Set.empty);

            expect(result.contains('bar'), equals(true));
            expect(result.contains('baz'), equals(false));
          });
        });

        group('with complete set', () {
          test('contains all elements', () {
            var target = lunr.Set(['bar']);
            var result = target.union(lunr.Set.complete);

            expect(result.contains('foo'), equals(true));
            expect(result.contains('bar'), equals(true));
            expect(result.contains('baz'), equals(true));
          });
        });
      });
    });

    group('#intersect', () {
      late lunr.Set set;
      setUp(() {
        set = lunr.Set(['foo']);
      });

      group('complete set', () {
        test('contains element', () {
          var result = lunr.Set.complete.intersect(set);
          expect(result.contains('foo'), equals(true));
          expect(result.contains('bar'), equals(false));
        });
      });

      group('empty set', () {
        test('does not contain element', () {
          var result = lunr.Set.empty.intersect(set);
          expect(result.contains('foo'), equals(false));
        });
      });

      group('populated set', () {
        group('no intersection', () {
          test('does not contain intersection elements', () {
            var target = lunr.Set(['bar']);
            var result = target.intersect(set);

            expect(result.contains('foo'), equals(false));
            expect(result.contains('bar'), equals(false));
          });
        });

        group('intersection', () {
          test('contains intersection elements', () {
            var target = lunr.Set(['foo', 'bar']);
            var result = target.intersect(set);
            expect(result.contains('foo'), equals(true));
            expect(result.contains('bar'), equals(false));
          });
        });

        group('with empty set', () {
          test('returns empty set', () {
            var target = lunr.Set(['foo']),
                result = target.intersect(lunr.Set.empty);

            expect(result.contains('foo'), equals(false));
          });
        });

        group('with complete set', () {
          test('returns populated set', () {
            var target = lunr.Set(['foo']),
                result = target.intersect(lunr.Set.complete);

            expect(result.contains('foo'), equals(true));
            expect(result.contains('bar'), equals(false));
          });
        });
      });
    });
  });
}
