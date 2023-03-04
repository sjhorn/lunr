import 'package:test/test.dart';
import 'assert.dart';

import 'package:lunr/query_parser.dart' as lunr;
import 'package:lunr/query.dart' as lunr;
import 'package:lunr/query_parse_error.dart' as lunr;
import 'package:lunr/query.dart';

void main() {
  group('lunr.QueryParser', () {
    parse(q) {
      var query = lunr.Query(['title', 'body']),
          parser = lunr.QueryParser(q, query);

      parser.parse();
      return query.clauses;
    }

    group('#parse', () {
      late List<Clause> clauses;
      late Clause clause;
      late Clause fooClause;
      late Clause barClause;

      group('single term', () {
        setUp(() {
          clauses = parse('foo');
        });

        test('has 1 clause', () {
          expect(clauses, hasLength(1));
        });

        group('clauses', () {
          setUp(() {
            clause = clauses[0];
          });

          test('term', () {
            Assert.equal('foo', clause.term);
          });

          test('fields', () {
            Assert.sameMembers(['title', 'body'], clause.fields);
          });

          test('presence', () {
            Assert.equal(lunr.QueryPresence.OPTIONAL, clause.presence);
          });

          test('usePipeline', () {
            Assert.ok(clause.usePipeline);
          });
        });
      });

      group('single term, uppercase', () {
        setUp(() {
          clauses = parse('FOO');
        });

        test('has 1 clause', () {
          Assert.lengthOf(clauses, 1);
        });

        group('clauses', () {
          setUp(() {
            clause = clauses[0];
          });

          test('term', () {
            Assert.equal('foo', clause.term);
          });

          test('fields', () {
            Assert.sameMembers(['title', 'body'], clause.fields);
          });

          test('usePipeline', () {
            Assert.ok(clause.usePipeline);
          });
        });
      });

      group('single term with wildcard', () {
        setUp(() {
          clauses = parse('fo*');
        });

        test('has 1 clause', () {
          Assert.lengthOf(clauses, 1);
        });

        group('clauses', () {
          setUp(() {
            clause = clauses[0];
          });

          test('#term', () {
            Assert.equal('fo*', clause.term);
          });

          test('#usePipeline', () {
            Assert.notOk(clause.usePipeline);
          });
        });
      });

      group('multiple terms', () {
        setUp(() {
          clauses = parse('foo bar');
        });

        test('has 2 clause', () {
          Assert.lengthOf(clauses, 2);
        });

        group('clauses', () {
          test('#term', () {
            Assert.equal('foo', clauses[0].term);
            Assert.equal('bar', clauses[1].term);
          });
        });
      });

      group('multiple terms with presence', () {
        setUp(() {
          clauses = parse('+foo +bar');
        });

        test('has 2 clause', () {
          Assert.lengthOf(clauses, 2);
        });
      });

      group('edit distance followed by presence', () {
        setUp(() {
          clauses = parse('foo~10 +bar');
        });

        test('has 2 clause', () {
          Assert.lengthOf(clauses, 2);
        });

        group('clauses', () {
          setUp(() {
            fooClause = clauses[0];
            barClause = clauses[1];
          });

          test('#term', () {
            Assert.equal('foo', fooClause.term);
            Assert.equal('bar', barClause.term);
          });

          test('#presence', () {
            Assert.equal(lunr.QueryPresence.OPTIONAL, fooClause.presence);
            Assert.equal(lunr.QueryPresence.REQUIRED, barClause.presence);
          });

          test('#editDistance', () {
            Assert.equal(10, fooClause.editDistance);
            // It feels dirty expecting that something is undefined
            // but there is no Optional so this is what we are reduced to
            Assert.isUndefined(barClause.editDistance);
          });
        });
      });

      group('boost followed by presence', () {
        setUp(() {
          clauses = parse('foo^10 +bar');
        });

        test('has 2 clause', () {
          Assert.lengthOf(clauses, 2);
        });

        group('clauses', () {
          setUp(() {
            fooClause = clauses[0];
            barClause = clauses[1];
          });

          test('#term', () {
            Assert.equal('foo', fooClause.term);
            Assert.equal('bar', barClause.term);
          });

          test('#presence', () {
            Assert.equal(lunr.QueryPresence.OPTIONAL, fooClause.presence);
            Assert.equal(lunr.QueryPresence.REQUIRED, barClause.presence);
          });

          test('#boost', () {
            Assert.equal(10, fooClause.boost);
            Assert.equal(1, barClause.boost);
          });
        });
      });

      group('field without a term', () {
        test('fails with lunr.QueryParseError', () {
          //Assert.throws( () { parse('title:') }, lunr.QueryParseError)
          expect(() => parse('title:'), throwsA(isA<lunr.QueryParseError>()));
        });
      });

      group('unknown field', () {
        test('fails with lunr.QueryParseError', () {
          //Assert.throws( () { parse('unknown:foo') }, lunr.QueryParseError)
          expect(
              () => parse('unknown:foo'), throwsA(isA<lunr.QueryParseError>()));
        });
      });

      group('term with field', () {
        setUp(() {
          clauses = parse('title:foo');
        });

        test('has 1 clause', () {
          Assert.lengthOf(clauses, 1);
        });

        test('clause contains only scoped field', () {
          Assert.sameMembers(clauses[0].fields, ['title']);
        });
      });

      group('uppercase field with uppercase term', () {
        setUp(() {
          // Using a different query to the rest of the tests
          // so that only this test has to worry about an upcase field name
          var query = lunr.Query(['TITLE']),
              parser = lunr.QueryParser("TITLE:FOO", query);

          parser.parse();

          clauses = query.clauses;
        });

        test('has 1 clause', () {
          Assert.lengthOf(clauses, 1);
        });

        test('clause contains downcased term', () {
          Assert.equal(clauses[0].term, 'foo');
        });

        test('clause contains only scoped field', () {
          Assert.sameMembers(clauses[0].fields, ['TITLE']);
        });
      });

      group('multiple terms scoped to different fields', () {
        setUp(() {
          clauses = parse('title:foo body:bar');
        });

        test('has 2 clauses', () {
          Assert.lengthOf(clauses, 2);
        });

        test('fields', () {
          Assert.sameMembers(['title'], clauses[0].fields);
          Assert.sameMembers(['body'], clauses[1].fields);
        });

        test('terms', () {
          Assert.equal('foo', clauses[0].term);
          Assert.equal('bar', clauses[1].term);
        });
      });

      group('single term with edit distance', () {
        setUp(() {
          clauses = parse('foo~2');
        });

        test('has 1 clause', () {
          Assert.lengthOf(clauses, 1);
        });

        test('term', () {
          Assert.equal('foo', clauses[0].term);
        });

        test('editDistance', () {
          Assert.equal(2, clauses[0].editDistance);
        });

        test('fields', () {
          Assert.sameMembers(['title', 'body'], clauses[0].fields);
        });
      });

      group('multiple terms with edit distance', () {
        setUp(() {
          clauses = parse('foo~2 bar~3');
        });

        test('has 2 clauses', () {
          Assert.lengthOf(clauses, 2);
        });

        test('term', () {
          Assert.equal('foo', clauses[0].term);
          Assert.equal('bar', clauses[1].term);
        });

        test('editDistance', () {
          Assert.equal(2, clauses[0].editDistance);
          Assert.equal(3, clauses[1].editDistance);
        });

        test('fields', () {
          Assert.sameMembers(['title', 'body'], clauses[0].fields);
          Assert.sameMembers(['title', 'body'], clauses[1].fields);
        });
      });

      group('single term scoped to field with edit distance', () {
        setUp(() {
          clauses = parse('title:foo~2');
        });

        test('has 1 clause', () {
          Assert.lengthOf(clauses, 1);
        });

        test('term', () {
          Assert.equal('foo', clauses[0].term);
        });

        test('editDistance', () {
          Assert.equal(2, clauses[0].editDistance);
        });

        test('fields', () {
          Assert.sameMembers(['title'], clauses[0].fields);
        });
      });

      group('non-numeric edit distance', () {
        test('throws lunr.QueryParseError', () {
          //Assert.throws( () { parse('foo~a') }, lunr.QueryParseError)
          expect(() => parse('foo~a'), throwsA(isA<lunr.QueryParseError>()));
        });
      });

      group('edit distance without a term', () {
        test('throws lunr.QueryParseError', () {
          //Assert.throws( () { parse('~2') }, lunr.QueryParseError)
          expect(() => parse('~2'), throwsA(isA<lunr.QueryParseError>()));
        });
      });

      group('single term with boost', () {
        setUp(() {
          clauses = parse('foo^2');
        });

        test('has 1 clause', () {
          Assert.lengthOf(clauses, 1);
        });

        test('term', () {
          Assert.equal('foo', clauses[0].term);
        });

        test('boost', () {
          Assert.equal(2, clauses[0].boost);
        });

        test('fields', () {
          Assert.sameMembers(['title', 'body'], clauses[0].fields);
        });
      });

      group('non-numeric boost', () {
        test('throws lunr.QueryParseError', () {
          //Assert.throws( () { parse('foo^a') }, lunr.QueryParseError)
          expect(() => parse('foo^a'), throwsA(isA<lunr.QueryParseError>()));
        });
      });

      group('boost without a term', () {
        test('throws lunr.QueryParseError', () {
          //Assert.throws( () { parse('^2') }, lunr.QueryParseError)
          expect(() => parse('^2'), throwsA(isA<lunr.QueryParseError>()));
        });
      });

      group('multiple terms with boost', () {
        setUp(() {
          clauses = parse('foo^2 bar^3');
        });

        test('has 2 clauses', () {
          Assert.lengthOf(clauses, 2);
        });

        test('term', () {
          Assert.equal('foo', clauses[0].term);
          Assert.equal('bar', clauses[1].term);
        });

        test('boost', () {
          Assert.equal(2, clauses[0].boost);
          Assert.equal(3, clauses[1].boost);
        });

        test('fields', () {
          Assert.sameMembers(['title', 'body'], clauses[0].fields);
          Assert.sameMembers(['title', 'body'], clauses[1].fields);
        });
      });

      group('term scoped by field with boost', () {
        setUp(() {
          clauses = parse('title:foo^2');
        });

        test('has 1 clause', () {
          Assert.lengthOf(clauses, 1);
        });

        test('term', () {
          Assert.equal('foo', clauses[0].term);
        });

        test('boost', () {
          Assert.equal(2, clauses[0].boost);
        });

        test('fields', () {
          Assert.sameMembers(['title'], clauses[0].fields);
        });
      });

      group('term with presence required', () {
        setUp(() {
          clauses = parse('+foo');
        });

        test('has 1 clauses', () {
          Assert.lengthOf(clauses, 1);
        });

        test('term', () {
          Assert.equal('foo', clauses[0].term);
        });

        test('boost', () {
          Assert.equal(1, clauses[0].boost);
        });

        test('fields', () {
          Assert.sameMembers(['title', 'body'], clauses[0].fields);
        });

        test('presence', () {
          Assert.equal(lunr.QueryPresence.REQUIRED, clauses[0].presence);
        });
      });

      group('term with presence prohibited', () {
        setUp(() {
          clauses = parse('-foo');
        });

        test('has 1 clauses', () {
          Assert.lengthOf(clauses, 1);
        });

        test('term', () {
          Assert.equal('foo', clauses[0].term);
        });

        test('boost', () {
          Assert.equal(1, clauses[0].boost);
        });

        test('fields', () {
          Assert.sameMembers(['title', 'body'], clauses[0].fields);
        });

        test('presence', () {
          Assert.equal(lunr.QueryPresence.PROHIBITED, clauses[0].presence);
        });
      });

      group('term scoped by field with presence required', () {
        setUp(() {
          clauses = parse('+title:foo');
        });

        test('has 1 clauses', () {
          Assert.lengthOf(clauses, 1);
        });

        test('term', () {
          Assert.equal('foo', clauses[0].term);
        });

        test('boost', () {
          Assert.equal(1, clauses[0].boost);
        });

        test('fields', () {
          Assert.sameMembers(['title'], clauses[0].fields);
        });

        test('presence', () {
          Assert.equal(lunr.QueryPresence.REQUIRED, clauses[0].presence);
        });
      });

      group('term scoped by field with presence prohibited', () {
        setUp(() {
          clauses = parse('-title:foo');
        });

        test('has 1 clauses', () {
          Assert.lengthOf(clauses, 1);
        });

        test('term', () {
          Assert.equal('foo', clauses[0].term);
        });

        test('boost', () {
          Assert.equal(1, clauses[0].boost);
        });

        test('fields', () {
          Assert.sameMembers(['title'], clauses[0].fields);
        });

        test('presence', () {
          Assert.equal(lunr.QueryPresence.PROHIBITED, clauses[0].presence);
        });
      });
    });

    group('term with boost and edit distance', () {
      late List<Clause> clauses;

      setUp(() {
        clauses = parse('foo^2~3');
      });

      test('has 1 clause', () {
        Assert.lengthOf(clauses, 1);
      });

      test('term', () {
        Assert.equal('foo', clauses[0].term);
      });

      test('editDistance', () {
        Assert.equal(3, clauses[0].editDistance);
      });

      test('boost', () {
        Assert.equal(2, clauses[0].boost);
      });

      test('fields', () {
        Assert.sameMembers(['title', 'body'], clauses[0].fields);
      });
    });
  });
}
