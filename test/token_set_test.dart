import 'package:test/test.dart';
import 'package:lunr/token_set.dart' as lunr;

void main() {
  group('lunr.TokenSet', () {
    group('#toString', () {
      test('includes node isFinality', () {
        lunr.TokenSet nonisFinal = lunr.TokenSet();
        lunr.TokenSet isFinal = lunr.TokenSet();
        lunr.TokenSet otherisFinal = lunr.TokenSet();

        isFinal.isFinal = true;
        otherisFinal.isFinal = true;

        expect(nonisFinal.toString(), isNot(equals(isFinal.toString())));
        expect(otherisFinal.toString(), isFinal.toString());
      });

      test('includes all edges', () {
        lunr.TokenSet zeroEdges = lunr.TokenSet();
        lunr.TokenSet oneEdge = lunr.TokenSet();
        lunr.TokenSet twoEdges = lunr.TokenSet();

        lunr.TokenSet edge = lunr.TokenSet();

        oneEdge.edges['a'] = edge;
        twoEdges.edges['a'] = edge;
        twoEdges.edges['b'] = edge;

        expect(zeroEdges.toString(), isNot(equals(oneEdge.toString())));
        expect(twoEdges.toString(), isNot(equals(oneEdge.toString())));
        expect(twoEdges.toString(), isNot(equals(zeroEdges.toString())));
      });

      test('includes edge id', () {
        lunr.TokenSet childA = lunr.TokenSet(),
            childB = lunr.TokenSet(),
            parentA = lunr.TokenSet(),
            parentB = lunr.TokenSet(),
            parentC = lunr.TokenSet();

        parentA.edges['a'] = childA;
        parentB.edges['a'] = childB;
        parentC.edges['a'] = childB;

        expect(parentB.toString(), parentC.toString());
        expect(parentA.toString(), isNot(equals(parentC.toString())));
        expect(parentA.toString(), isNot(equals(parentB.toString())));
      });
    });

    group('.fromString', () {
      test('without wildcard', () {
        lunr.TokenSet.nextId = 1;
        var x = lunr.TokenSet.fromString('a');

        expect(x.toString(), '0a2');
        expect(x.edges['a']!.isFinal, equals(true));
      });

      test('with trailing wildcard', () {
        var x = lunr.TokenSet.fromString('a*'), wild = x.edges['a']!.edges['*'];

        // a state reached by a wildcard has
        // an edge with a wildcard to itself.
        // the resulting automota is
        // non-determenistic
        expect(wild, wild!.edges['*']);
        expect(wild.isFinal, equals(true));
      });
    });

    group('.fromArray', () {
      test('with unsorted array', () {
        expect(() => lunr.TokenSet.fromArray(['z', 'a']),
            throwsA(isA<Exception>()));
      });

      test('with sorted array', () {
        var tokenSet = lunr.TokenSet.fromArray(['a', 'z']);

        expect(
            ['a', 'z'],
            containsAllInOrder(
                tokenSet.toArray().toList()..sort((a, b) => a.compareTo(b))));
      });

      test('is minimal', () {
        lunr.TokenSet tokenSet = lunr.TokenSet.fromArray(['ac', 'dc']);
        var acNode = tokenSet.edges['a']!.edges['c']!;
        var dcNode = tokenSet.edges['d']!.edges['c']!;

        expect(acNode, equals(dcNode));
      });
    });

    group('#toArray', () {
      test('includes all words', () {
        var words = ['bat', 'cat'], tokenSet = lunr.TokenSet.fromArray(words);

        expect(words, containsAll(tokenSet.toArray()));
      });

      test('includes single words', () {
        var word = 'bat', tokenSet = lunr.TokenSet.fromString(word);

        expect([word], containsAllInOrder(tokenSet.toArray()));
      });
    });

    group('#intersect', () {
      test('no intersection', () {
        var x = lunr.TokenSet.fromString('cat'),
            y = lunr.TokenSet.fromString('bar'),
            z = x.intersect(y);

        expect(0, equals(z.toArray().length));
      });

      test('simple intersection', () {
        var x = lunr.TokenSet.fromString('cat'),
            y = lunr.TokenSet.fromString('cat'),
            z = x.intersect(y);
        expect(['cat'], containsAllInOrder(z.toArray()));
      });

      test('trailing wildcard intersection', () {
        var x = lunr.TokenSet.fromString('cat'),
            y = lunr.TokenSet.fromString('c*'),
            z = x.intersect(y);
        expect(['cat'], containsAllInOrder(z.toArray()));
      });

      test('trailing wildcard no intersection', () {
        var x = lunr.TokenSet.fromString('cat'),
            y = lunr.TokenSet.fromString('b*'),
            z = x.intersect(y);

        expect(0, equals(z.toArray().length));
      });

      test('leading wildcard intersection', () {
        var x = lunr.TokenSet.fromString('cat'),
            y = lunr.TokenSet.fromString('*t'),
            z = x.intersect(y);

        expect(['cat'], containsAllInOrder(z.toArray()));
      });

      test('leading wildcard backtracking intersection', () {
        var x = lunr.TokenSet.fromString('aaacbab'),
            y = lunr.TokenSet.fromString('*ab'),
            z = x.intersect(y);

        expect(['aaacbab'], containsAllInOrder(z.toArray()));
      });

      test('leading wildcard no intersection', () {
        var x = lunr.TokenSet.fromString('cat'),
            y = lunr.TokenSet.fromString('*r'),
            z = x.intersect(y);

        expect(0, equals(z.toArray().length));
      });

      test('leading wildcard backtracking no intersection', () {
        var x = lunr.TokenSet.fromString('aaabdcbc'),
            y = lunr.TokenSet.fromString('*abc'),
            z = x.intersect(y);

        expect(0, equals(z.toArray().length));
      });

      test('contained wildcard intersection', () {
        var x = lunr.TokenSet.fromString('foo'),
            y = lunr.TokenSet.fromString('f*o'),
            z = x.intersect(y);

        expect(['foo'], containsAllInOrder(z.toArray()));
      });

      test('contained wildcard backtracking intersection', () {
        var x = lunr.TokenSet.fromString('ababc'),
            y = lunr.TokenSet.fromString('a*bc'),
            z = x.intersect(y);

        expect(['ababc'], containsAllInOrder(z.toArray()));
      });

      test('contained wildcard no intersection', () {
        var x = lunr.TokenSet.fromString('foo'),
            y = lunr.TokenSet.fromString('b*r'),
            z = x.intersect(y);

        expect(0, equals(z.toArray().length));
      });

      test('contained wildcard backtracking no intersection', () {
        var x = lunr.TokenSet.fromString('ababc'),
            y = lunr.TokenSet.fromString('a*ac'),
            z = x.intersect(y);

        expect(0, equals(z.toArray().length));
      });

      test('wildcard matches zero or more characters', () {
        var x = lunr.TokenSet.fromString('foo'),
            y = lunr.TokenSet.fromString('foo*'),
            z = x.intersect(y);

        expect(['foo'], containsAllInOrder(z.toArray()));
      });

      // This test is intended to prevent 'bugs' that have lead to these
      // kind of intersections taking a _very_ long time. The assertion
      // is not of interest, just that the test does not timeout.
      test('catastrophic backtracking with leading characters', () {
        var x = lunr.TokenSet.fromString(
                'fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff'),
            y = lunr.TokenSet.fromString('*ff'),
            z = x.intersect(y);

        expect(1, equals(z.toArray().length));
      });

      test('leading and trailing backtracking intersection', () {
        var x = lunr.TokenSet.fromString('acbaabab'),
            y = lunr.TokenSet.fromString('*ab*'),
            z = x.intersect(y);

        expect(['acbaabab'], containsAllInOrder(z.toArray()));
      });

      test('multiple contained wildcard backtracking', () {
        var x = lunr.TokenSet.fromString('acbaabab'),
            y = lunr.TokenSet.fromString('a*ba*b'),
            z = x.intersect(y);

        expect(['acbaabab'], containsAllInOrder(z.toArray()));
      });

      test('intersect with fuzzy string substitution', () {
        var x1 = lunr.TokenSet.fromString('bar'),
            x2 = lunr.TokenSet.fromString('cur'),
            x3 = lunr.TokenSet.fromString('cat'),
            x4 = lunr.TokenSet.fromString('car'),
            x5 = lunr.TokenSet.fromString('foo'),
            y = lunr.TokenSet.fromFuzzyString('car', 1);

        expect(x1.intersect(y).toArray(), containsAllInOrder(["bar"]));
        expect(x2.intersect(y).toArray(), containsAllInOrder(["cur"]));
        expect(x3.intersect(y).toArray(), containsAllInOrder(["cat"]));
        expect(x4.intersect(y).toArray(), containsAllInOrder(["car"]));
        expect(x5.intersect(y).toArray().length, equals(0));
      });

      test('intersect with fuzzy string deletion', () {
        var x1 = lunr.TokenSet.fromString('ar'),
            x2 = lunr.TokenSet.fromString('br'),
            x3 = lunr.TokenSet.fromString('ba'),
            x4 = lunr.TokenSet.fromString('bar'),
            x5 = lunr.TokenSet.fromString('foo'),
            y = lunr.TokenSet.fromFuzzyString('bar', 1);

        expect(x1.intersect(y).toArray(), containsAllInOrder(["ar"]));
        expect(x2.intersect(y).toArray(), containsAllInOrder(["br"]));
        expect(x3.intersect(y).toArray(), containsAllInOrder(["ba"]));
        expect(x4.intersect(y).toArray(), containsAllInOrder(["bar"]));
        expect(x5.intersect(y).toArray().length, equals(0));
      });

      test('intersect with fuzzy string insertion', () {
        var x1 = lunr.TokenSet.fromString('bbar'),
            x2 = lunr.TokenSet.fromString('baar'),
            x3 = lunr.TokenSet.fromString('barr'),
            x4 = lunr.TokenSet.fromString('bar'),
            x5 = lunr.TokenSet.fromString('ba'),
            x6 = lunr.TokenSet.fromString('foo'),
            x7 = lunr.TokenSet.fromString('bara'),
            y = lunr.TokenSet.fromFuzzyString('bar', 1);

        expect(x1.intersect(y).toArray(), containsAllInOrder(["bbar"]));
        expect(x2.intersect(y).toArray(), containsAllInOrder(["baar"]));
        expect(x3.intersect(y).toArray(), containsAllInOrder(["barr"]));
        expect(x4.intersect(y).toArray(), containsAllInOrder(["bar"]));
        expect(x5.intersect(y).toArray(), containsAllInOrder(["ba"]));
        expect(x6.intersect(y).toArray().length, equals(0));
        expect(x7.intersect(y).toArray(), containsAllInOrder(["bara"]));
      });

      test('intersect with fuzzy string transpose', () {
        var x1 = lunr.TokenSet.fromString('abr'),
            x2 = lunr.TokenSet.fromString('bra'),
            x3 = lunr.TokenSet.fromString('foo'),
            y = lunr.TokenSet.fromFuzzyString('bar', 1);

        expect(x1.intersect(y).toArray(), containsAllInOrder(["abr"]));
        expect(x2.intersect(y).toArray(), containsAllInOrder(["bra"]));
        expect(x3.intersect(y).toArray().length, equals(0));
      });

      test('fuzzy string insertion', () {
        var x = lunr.TokenSet.fromString('abcxx'),
            y = lunr.TokenSet.fromFuzzyString('abc', 2);

        expect(x.intersect(y).toArray(), containsAllInOrder(['abcxx']));
      });

      test('fuzzy string substitution', () {
        var x = lunr.TokenSet.fromString('axx'),
            y = lunr.TokenSet.fromFuzzyString('abc', 2);

        expect(x.intersect(y).toArray(), containsAllInOrder(['axx']));
      });

      test('fuzzy string deletion', () {
        var x = lunr.TokenSet.fromString('a'),
            y = lunr.TokenSet.fromFuzzyString('abc', 2);

        expect(x.intersect(y).toArray(), containsAllInOrder(['a']));
      });

      test('fuzzy string transpose', () {
        var x = lunr.TokenSet.fromString('bca'),
            y = lunr.TokenSet.fromFuzzyString('abc', 2);

        expect(x.intersect(y).toArray(), containsAllInOrder(['bca']));
      });
    });
  });
}
