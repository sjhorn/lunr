import 'package:lunr/token.dart';
import 'package:lunr/tokenizer.dart';
import 'package:test/test.dart';
import 'package:lunr/query.dart' as lunr;

void main() {
  group('lunr.Query', () {
    var allFields = ['title', 'body'];
    late lunr.Query query;
    late lunr.Clause clause;
    group('#term', () {
      setUp(() {
        query = lunr.Query(allFields);
      });

      group('single string term', () {
        setUp(() {
          query.term('foo');
        });

        test('adds a single clause', () {
          expect(query.clauses.length, equals(1));
        });

        test('clause has the correct term', () {
          expect(query.clauses[0].term, equals('foo'));
        });
      });

      group('single token term', () {
        setUp(() {
          query.term(Token('foo'));
        });

        test('adds a single clause', () {
          expect(query.clauses.length, equals(1));
        });

        test('clause has the correct term', () {
          expect(query.clauses[0].term, equals('foo'));
        });
      });

      group('multiple string terms', () {
        setUp(() {
          query.term(['foo', 'bar']);
        });

        test('adds a single clause', () {
          expect(query.clauses.length, equals(2));
        });

        test('clause has the correct term', () {
          var terms = query.clauses.map((c) => c.term);
          expect(terms, containsAll(['foo', 'bar']));
        });
      });

      group('multiple string terms with options', () {
        setUp(() {
          query.term(['foo', 'bar'], lunr.Clause(usePipeline: false));
        });

        test('clause has the correct term', () {
          var terms = query.clauses.map((c) => c.term).toList();
          expect(terms, containsAll(['foo', 'bar']));
        });
      });

      group('multiple token terms', () {
        setUp(() {
          query.term(tokenizer('foo bar'));
        });

        test('adds a single clause', () {
          expect(query.clauses.length, equals(2));
        });

        test('clause has the correct term', () {
          var terms = query.clauses.map((c) => c.term).toList();
          expect(terms, containsAll(['foo', 'bar']));
        });
      });
    });

    group('#clause', () {
      setUp(() {
        query = lunr.Query(allFields);
      });

      group('defaults', () {
        setUp(() {
          query.clause(lunr.Clause(term: 'foo'));
          clause = query.clauses[0];
        });

        test('fields', () {
          expect(clause.fields, containsAll(allFields));
        });

        test('boost', () {
          expect(clause.boost, equals(1));
        });

        test('usePipeline', () {
          expect(clause.usePipeline, equals(true));
        });
      });

      group('specified', () {
        setUp(() {
          query.clause(lunr.Clause(
              term: 'foo', boost: 10, fields: ['title'], usePipeline: false));

          clause = query.clauses[0];
        });

        test('fields', () {
          expect(clause.fields, containsAll(['title']));
        });

        test('boost', () {
          expect(clause.boost, equals(10));
        });

        test('usePipeline', () {
          expect(clause.usePipeline, equals(false));
        });
      });

      group('wildcards', () {
        group('none', () {
          setUp(() {
            query.clause(
                lunr.Clause(term: 'foo', wildcard: lunr.Query_wildcard_NONE));

            clause = query.clauses[0];
          });

          test('no wildcard', () {
            expect(clause.term, equals('foo'));
          });
        });

        group('leading', () {
          setUp(() {
            query.clause(lunr.Clause(
                term: 'foo', wildcard: lunr.Query_wildcard_LEADING));

            clause = query.clauses[0];
          });

          test('adds wildcard', () {
            expect(clause.term, equals('*foo'));
          });
        });

        group('trailing', () {
          setUp(() {
            query.clause(lunr.Clause(
                term: 'foo', wildcard: lunr.Query_wildcard_TRAILING));

            clause = query.clauses[0];
          });

          test('adds wildcard', () {
            expect(clause.term, equals('foo*'));
          });
        });

        group('leading and trailing', () {
          setUp(() {
            query.clause(lunr.Clause(
                term: 'foo',
                wildcard: lunr.Query_wildcard_TRAILING |
                    lunr.Query_wildcard_LEADING));

            clause = query.clauses[0];
          });

          test('adds wildcards', () {
            expect(clause.term, equals('*foo*'));
          });
        });

        group('existing', () {
          setUp(() {
            query.clause(lunr.Clause(
                term: '*foo*',
                wildcard: lunr.Query_wildcard_TRAILING |
                    lunr.Query_wildcard_LEADING));

            clause = query.clauses[0];
          });

          test('no additional wildcards', () {
            expect(clause.term, equals('*foo*'));
          });
        });
      });
    });

    group('#isNegated', () {
      setUp(() {
        query = lunr.Query(allFields);
      });

      group('all prohibited', () {
        setUp(() {
          query.term(
              'foo', lunr.Clause(presence: lunr.QueryPresence.PROHIBITED));
          query.term(
              'bar', lunr.Clause(presence: lunr.QueryPresence.PROHIBITED));
        });

        test('is negated', () {
          expect(query.isNegated(), equals(true));
        });
      });

      group('some prohibited', () {
        setUp(() {
          query.term(
              'foo', lunr.Clause(presence: lunr.QueryPresence.PROHIBITED));
          query.term('bar', lunr.Clause(presence: lunr.QueryPresence.REQUIRED));
        });

        test('is negated', () {
          expect(query.isNegated(), equals(false));
        });
      });

      group('none prohibited', () {
        setUp(() {
          query.term('foo', lunr.Clause(presence: lunr.QueryPresence.OPTIONAL));
          query.term('bar', lunr.Clause(presence: lunr.QueryPresence.REQUIRED));
        });

        test('is negated', () {
          expect(query.isNegated(), equals(false));
        });
      });
    });
  });
}
