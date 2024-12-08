import 'package:lunr/lunr.dart';
import 'package:test/test.dart';
import 'assert.dart';

void main() {
  group('search', () {
    late List<Map<String, dynamic>> documents;
    setUp(() {
      documents = [
        {
          'id': 'a',
          'title': 'Mr. Green kills Colonel Mustard',
          'body':
              'Mr. Green killed Colonel Mustard in the study with the candlestick. Mr. Green is not a very nice fellow.',
          'wordCount': 19
        },
        {
          'id': 'b',
          'title': 'Plumb waters plant',
          'body': 'Professor Plumb has a green plant in his study',
          'wordCount': 9
        },
        {
          'id': 'c',
          'title': 'Scarlett helps Professor',
          'body':
              'Miss Scarlett watered Professor Plumbs green plant while he was away from his office last week.',
          'wordCount': 16
        }
      ];
    });

    group('with build-time field boosts', () {
      group('no query boosts', () {
        late Index idx;
        late List<DocMatch> results;
        setUp(() {
          idx = Lunr.lunr((builder) {
            builder.ref = 'id';
            builder.field('title');
            builder.field('body', {'boost': 10});

            for (var document in documents) {
              builder.add(document);
            }
          });
        });
        test('#search document b ranks highest', () {
          results = idx.search('professor');
          Assert.equal('b', results[0].ref);
        });

        test('#query document b ranks highest', () {
          results = idx.query((q) {
            q.term('professor');
          });
          Assert.equal('b', results[0].ref);
        });
      });

      group('with build-time document boost', () {
        late Index idx;
        late List<DocMatch> results;
        setUp(() {
          idx = Lunr.lunr((builder) {
            builder.ref = 'id';
            builder.field('title');
            builder.field('body');

            for (var document in documents) {
              var boost = document['id'] == 'c' ? 10 : 1;
              builder.add(document, {'boost': boost});
            }
          });
        });

        group('no query boost', () {
          test('#search document b ranks highest', () {
            results = idx.search('plumb');
            Assert.equal('c', results[0].ref);
          });

          test('#query document b ranks highest', () {
            results = idx.query((q) {
              q.term('plumb');
            });
          });
        });

        group('with query boost', () {
          group('#search', () {
            setUp(() {
              results = idx.search('green study^10');
            });

            test('document b ranks highest', () {
              Assert.equal('b', results[0].ref);
            });
          });

          group('#query', () {
            setUp(() {
              results = idx.query((q) {
                q.term('green');
                q.term('study', Clause(boost: 10));
              });
            });

            test('document b ranks highest', () {
              Assert.equal('b', results[0].ref);
            });
          });
        });
      });
    });

    group('without build-time boosts', () {
      late Index idx;
      late List<DocMatch> results;

      setUp(() {
        idx = Lunr.lunr((builder) {
          builder.ref = 'id';
          builder.field('title');
          builder.field('body');

          for (var document in documents) {
            builder.add(document);
          }
        });
      });

      group('single term search', () {
        group('one match', () {
          group('#search', () {
            setUp(() {
              results = idx.search('scarlett');
            });
            test('one result returned', () {
              Assert.lengthOf(results, 1);
            });

            test('document c matches', () {
              Assert.equal('c', results[0].ref);
            });

            test('matching term', () {
              Assert.sameMembers(
                  ['scarlett'], results[0].matchData.metadata.keys);
            });
          });

          group('#query', () {
            setUp(() {
              results = idx.query((q) {
                q.term('scarlett');
              });
            });

            test('one result returned', () {
              Assert.lengthOf(results, 1);
            });

            test('document c matches', () {
              Assert.equal('c', results[0].ref);
            });

            test('matching term', () {
              Assert.sameMembers(
                  ['scarlett'], results[0].matchData.metadata.keys);
            });
          });
        });

        group('no match', () {
          setUp(() {
            results = idx.search('foo');
          });

          test('no matches', () {
            Assert.lengthOf(results, 0);
          });
        });

        group('multiple matches', () {
          setUp(() {
            results = idx.search('plant');
          });

          test('has two matches', () {
            Assert.lengthOf(results, 2);
          });

          test('sorted by relevance', () {
            Assert.equal('b', results[0].ref);
            Assert.equal('c', results[1].ref);
          });
        });

        group('pipeline processing', () {
          // study would be stemmed to studi, tokens
          // are stemmed by default on index and must
          // also be stemmed on search to match
          group('enabled (default)', () {
            setUp(() {
              results = idx.query((q) {
                q.clause(Clause(term: 'study', usePipeline: true));
              });
            });

            test('has two matches', () {
              Assert.lengthOf(results, 2);
            });

            test('sorted by relevance', () {
              Assert.equal('b', results[0].ref);
              Assert.equal('a', results[1].ref);
            });
          });

          group('disabled', () {
            setUp(() {
              results = idx.query((q) {
                q.clause(Clause(term: 'study', usePipeline: false));
              });
            });

            test('no matches', () {
              Assert.lengthOf(results, 0);
            });
          });
        });
      });
      group('multiple terms', () {
        group('all terms match', () {
          setUp(() {
            results = idx.search('fellow candlestick');
          });

          test('has one match', () {
            Assert.lengthOf(results, 1);
          });

          test('correct document returned', () {
            Assert.equal('a', results[0].ref);
          });

          test('matched terms returned', () {
            Assert.sameMembers(
                ['fellow', 'candlestick'], results[0].matchData.metadata.keys);
            Assert.sameMembers(
                ['body'], results[0].matchData.metadata['fellow']!.keys);
            Assert.sameMembers(
                ['body'], results[0].matchData.metadata['candlestick']!.keys);
          });
        });
      });
      group('one term matches', () {
        setUp(() {
          results = idx.search('week foo');
        });

        test('has one match', () {
          Assert.lengthOf(results, 1);
        });

        test('correct document returned', () {
          Assert.equal('c', results[0].ref);
        });

        test('only matching terms returned', () {
          Assert.sameMembers(['week'], results[0].matchData.metadata.keys);
        });
      });

      group('duplicate query terms', () {
        // https://github.com/olivernn/lunr.js/issues/256
        // previously would throw a duplicate index error
        // because the query vector already contained an entry
        // for the term 'fellow'
        test('no errors', () {
          expect(
              () => idx.search('fellow candlestick foo bar green plant fellow'),
              returnsNormally);
        });
      });

      group('documents with all terms score higher', () {
        setUp(() {
          results = idx.search('candlestick green');
        });

        test('has three matches', () {
          Assert.lengthOf(results, 3);
        });

        test('correct documents returned', () {
          var matchingDocuments = results.map((r) {
            return r.ref;
          });
          Assert.sameMembers(['a', 'b', 'c'], matchingDocuments);
        });

        test('documents with all terms score highest', () {
          Assert.equal('a', results[0].ref);
        });

        test('matching terms are returned', () {
          Assert.sameMembers(
              ['candlestick', 'green'], results[0].matchData.metadata.keys);
          Assert.sameMembers(['green'], results[1].matchData.metadata.keys);
          Assert.sameMembers(['green'], results[2].matchData.metadata.keys);
        });
      });

      group('no terms match', () {
        setUp(() {
          results = idx.search('foo bar');
        });

        test('no matches', () {
          Assert.lengthOf(results, 0);
        });
      });

      group('corpus terms are stemmed', () {
        setUp(() {
          results = idx.search('water');
        });

        test('matches two documents', () {
          Assert.lengthOf(results, 2);
        });

        test('matches correct documents', () {
          var matchingDocuments = results.map((r) {
            return r.ref;
          });
          Assert.sameMembers(['b', 'c'], matchingDocuments);
        });
      });

      group('field scoped terms', () {
        group('only matches on scoped field', () {
          setUp(() {
            results = idx.search('title:plant');
          });

          test('one result returned', () {
            Assert.lengthOf(results, 1);
          });

          test('returns the correct document', () {
            Assert.equal('b', results[0].ref);
          });

          test('match data', () {
            Assert.sameMembers(['plant'], results[0].matchData.metadata.keys);
          });
        });

        group('no matching terms', () {
          setUp(() {
            results = idx.search('title:candlestick');
          });

          test('no results returned', () {
            Assert.lengthOf(results, 0);
          });
        });
      });

      group('wildcard matching', () {
        group('trailing wildcard', () {
          group('no matches', () {
            setUp(() {
              results = idx.search('fo*');
            });

            test('no results returned', () {
              Assert.lengthOf(results, 0);
            });
          });

          group('one match', () {
            setUp(() {
              results = idx.search('candle*');
            });

            test('one result returned', () {
              Assert.lengthOf(results, 1);
            });

            test('correct document matched', () {
              Assert.equal('a', results[0].ref);
            });

            test('matching terms returned', () {
              Assert.sameMembers(
                  ['candlestick'], results[0].matchData.metadata.keys);
            });
          });

          group('multiple terms match', () {
            setUp(() {
              results = idx.search('pl*');
            });

            test('two results returned', () {
              Assert.lengthOf(results, 2);
            });

            test('correct documents matched', () {
              var matchingDocuments = results.map((r) {
                return r.ref;
              });
              Assert.sameMembers(['b', 'c'], matchingDocuments);
            });

            test('matching terms returned', () {
              Assert.sameMembers(
                  ['plumb', 'plant'], results[0].matchData.metadata.keys);
              Assert.sameMembers(
                  ['plumb', 'plant'], results[1].matchData.metadata.keys);
            });
          });
        });
      });

      group('wildcard matching', () {
        group('trailing wildcard', () {
          group('no matches found', () {
            setUp(() {
              results = idx.search('fo*');
            });

            test('no results returned', () {
              Assert.lengthOf(results, 0);
            });
          });

          group('results found', () {
            setUp(() {
              results = idx.search('pl*');
            });

            test('two results returned', () {
              Assert.lengthOf(results, 2);
            });

            test('matching documents returned', () {
              Assert.equal('b', results[0].ref);
              Assert.equal('c', results[1].ref);
            });

            test('matching terms returned', () {
              Assert.sameMembers(
                  ['plant', 'plumb'], results[0].matchData.metadata.keys);
              Assert.sameMembers(
                  ['plant', 'plumb'], results[1].matchData.metadata.keys);
            });
          });
        });

        group('leading wildcard', () {
          group('no results found', () {
            setUp(() {
              results = idx.search('*oo');
            });

            test('no results found', () {
              Assert.lengthOf(results, 0);
            });
          });

          group('results found', () {
            setUp(() {
              results = idx.search('*ant');
            });

            test('two results found', () {
              Assert.lengthOf(results, 2);
            });

            test('matching documents returned', () {
              Assert.equal('b', results[0].ref);
              Assert.equal('c', results[1].ref);
            });

            test('matching terms returned', () {
              Assert.sameMembers(['plant'], results[0].matchData.metadata.keys);
              Assert.sameMembers(['plant'], results[1].matchData.metadata.keys);
            });
          });
        });

        group('contained wildcard', () {
          group('no results found', () {
            setUp(() {
              results = idx.search('f*o');
            });

            test('no results found', () {
              Assert.lengthOf(results, 0);
            });
          });

          group('results found', () {
            setUp(() {
              results = idx.search('pl*nt');
            });

            test('two results found', () {
              Assert.lengthOf(results, 2);
            });

            test('matching documents returned', () {
              Assert.equal('b', results[0].ref);
              Assert.equal('c', results[1].ref);
            });

            test('matching terms returned', () {
              Assert.sameMembers(['plant'], results[0].matchData.metadata.keys);
              Assert.sameMembers(['plant'], results[1].matchData.metadata.keys);
            });
          });
        });
      });

      group('edit distance', () {
        group('no results found', () {
          setUp(() {
            results = idx.search('foo~1');
          });

          test('no results returned', () {
            Assert.lengthOf(results, 0);
          });
        });

        group('results found', () {
          setUp(() {
            results = idx.search('plont~1');
          });

          test('two results found', () {
            Assert.lengthOf(results, 2);
          });

          test('matching documents returned', () {
            Assert.equal('b', results[0].ref);
            Assert.equal('c', results[1].ref);
          });

          test('matching terms returned', () {
            Assert.sameMembers(['plant'], results[0].matchData.metadata.keys);
            Assert.sameMembers(['plant'], results[1].matchData.metadata.keys);
          });
        });
      });

      group('searching by field', () {
        group('unknown field', () {
          test('throws lunr.QueryParseError', () {
            // Assert.throws(() {
            //   idx.search('unknown-field:plant')
            // }.bind(, lunr.QueryParseError)
            expect(() => idx.search('unknown-field:plant'),
                throwsA(isA<QueryParseError>()));
          });
        });

        group('no results found', () {
          setUp(() {
            results = idx.search('title:candlestick');
          });

          test('no results found', () {
            Assert.lengthOf(results, 0);
          });
        });

        group('results found', () {
          setUp(() {
            results = idx.search('title:plant');
          });

          test('one results found', () {
            Assert.lengthOf(results, 1);
          });

          test('matching documents returned', () {
            Assert.equal('b', results[0].ref);
          });

          test('matching terms returned', () {
            Assert.sameMembers(['plant'], results[0].matchData.metadata.keys);
          });
        });
      });

      group('term boosts', () {
        group('no results found', () {
          setUp(() {
            results = idx.search('foo^10');
          });

          test('no results found', () {
            Assert.lengthOf(results, 0);
          });
        });

        group('results found', () {
          setUp(() {
            results = idx.search('scarlett candlestick^5');
          });

          test('two results found', () {
            Assert.lengthOf(results, 2);
          });

          test('matching documents returned', () {
            Assert.equal('a', results[0].ref);
            Assert.equal('c', results[1].ref);
          });

          test('matching terms returned', () {
            Assert.sameMembers(
                ['candlestick'], results[0].matchData.metadata.keys);
            Assert.sameMembers(
                ['scarlett'], results[1].matchData.metadata.keys);
          });
        });
      });

      group('typeahead style search', () {
        group('no results found', () {
          setUp(() {
            results = idx.query((q) {
              q.term("xyz", Clause(boost: 100, usePipeline: true));
              q.term(
                  "xyz",
                  Clause(
                      boost: 10,
                      usePipeline: false,
                      wildcard: Query_wildcard_TRAILING));
              q.term("xyz", Clause(boost: 1, editDistance: 1));
            });
          });

          test('no results found', () {
            Assert.lengthOf(results, 0);
          });
        });

        group('results found', () {
          setUp(() {
            results = idx.query((q) {
              q.term("pl", Clause(boost: 100, usePipeline: true));
              q.term(
                  "pl",
                  Clause(
                      boost: 10,
                      usePipeline: false,
                      wildcard: Query_wildcard_TRAILING));
              q.term("pl", Clause(boost: 1, editDistance: 1));
            });
          });

          test('two results found', () {
            Assert.lengthOf(results, 2);
          });

          test('matching documents returned', () {
            Assert.equal('b', results[0].ref);
            Assert.equal('c', results[1].ref);
          });

          test('matching terms returned', () {
            Assert.sameMembers(
                ['plumb', 'plant'], results[0].matchData.metadata.keys);
            Assert.sameMembers(
                ['plumb', 'plant'], results[1].matchData.metadata.keys);
          });
        });
      });

      group('term presence', () {
        group('prohibited', () {
          group('match', () {
            assertions() {
              test('two results found', () {
                Assert.lengthOf(results, 2);
              });

              test('matching documents returned', () {
                Assert.equal('b', results[0].ref);
                Assert.equal('c', results[1].ref);
              });

              test('matching terms returned', () {
                Assert.sameMembers(
                    ['green'], results[0].matchData.metadata.keys);
                Assert.sameMembers(
                    ['green'], results[1].matchData.metadata.keys);
              });
            }

            group('#query', () {
              setUp(() {
                results = idx.query((q) {
                  q.term('candlestick',
                      Clause(presence: QueryPresence.PROHIBITED));
                  q.term('green', Clause(presence: QueryPresence.OPTIONAL));
                });
              });

              assertions();
            });

            group('#search', () {
              setUp(() {
                results = idx.search('-candlestick green');
              });

              assertions();
            });
          });

          group('no match', () {
            assertions() {
              test('no matches', () {
                Assert.lengthOf(results, 0);
              });
            }

            group('#query', () {
              setUp(() {
                results = idx.query((q) {
                  q.term('green', Clause(presence: QueryPresence.PROHIBITED));
                });
              });

              assertions();
            });

            group('#search', () {
              setUp(() {
                results = idx.search('-green');
              });

              assertions();
            });
          });

          group('negated query no match', () {
            assertions() {
              test('all documents returned', () {
                Assert.lengthOf(results, 3);
              });

              test('all results have same score', () {
                //Assert.isTrue(results.every((r) { return r.score == 0 }));
                expect(results.every((r) => r.score == 0), equals(true));
              });
            }

            group('#query', () {
              setUp(() {
                results = idx.query((q) {
                  q.term(
                      'qwertyuiop', Clause(presence: QueryPresence.PROHIBITED));
                });
              });

              assertions();
            });

            group('#search', () {
              setUp(() {
                results = idx.search("-qwertyuiop");
              });

              assertions();
            });
          });

          group('negated query some match', () {
            assertions() {
              test('all documents returned', () {
                Assert.lengthOf(results, 1);
              });

              test('all results have same score', () {
                //Assert.isTrue(results.every((r) { return r.score === 0 }))
                expect(results.every((r) => r.score == 0), equals(true));
              });

              test('matching documents returned', () {
                Assert.equal('a', results[0].ref);
              });
            }

            group('#query', () {
              setUp(() {
                results = idx.query((q) {
                  q.term('plant', Clause(presence: QueryPresence.PROHIBITED));
                });
              });

              assertions();
            });

            group('#search', () {
              setUp(() {
                results = idx.search("-plant");
              });

              assertions();
            });
          });

          group('field match', () {
            assertions() {
              test('one result found', () {
                Assert.lengthOf(results, 1);
              });

              test('matching documents returned', () {
                Assert.equal('c', results[0].ref);
              });

              test('matching terms returned', () {
                Assert.sameMembers(
                    ['plumb'], results[0].matchData.metadata.keys);
              });
            }

            group('#query', () {
              setUp(() {
                results = idx.query((q) {
                  q.term(
                      'plant',
                      Clause(
                          presence: QueryPresence.PROHIBITED,
                          fields: ['title']));
                  q.term('plumb', Clause(presence: QueryPresence.OPTIONAL));
                });
              });

              assertions();
            });

            group('#search', () {
              setUp(() {
                results = idx.search('-title:plant plumb');
              });

              assertions();
            });
          });
        });

        group('required', () {
          group('match', () {
            assertions() {
              test('one result found', () {
                Assert.lengthOf(results, 1);
              });

              test('matching documents returned', () {
                Assert.equal('a', results[0].ref);
              });

              test('matching terms returned', () {
                Assert.sameMembers(['candlestick', 'green'],
                    results[0].matchData.metadata.keys);
              });
            }

            group('#search', () {
              setUp(() {
                results = idx.search("+candlestick green");
              });

              assertions();
            });

            group('#query', () {
              setUp(() {
                results = idx.query((q) {
                  q.term(
                      'candlestick', Clause(presence: QueryPresence.REQUIRED));
                  q.term('green', Clause(presence: QueryPresence.OPTIONAL));
                });
              });

              assertions();
            });
          });

          group('no match', () {
            assertions() {
              test('no matches', () {
                Assert.lengthOf(results, 0);
              });
            }

            group('#query', () {
              setUp(() {
                results = idx.query((q) {
                  q.term('mustard', Clause(presence: QueryPresence.REQUIRED));
                  q.term('plant', Clause(presence: QueryPresence.REQUIRED));
                });
              });

              assertions();
            });

            group('#search', () {
              setUp(() {
                results = idx.search('+mustard +plant');
              });

              assertions();
            });
          });

          group('no matching term', () {
            assertions() {
              test('no matches', () {
                Assert.lengthOf(results, 0);
              });
            }

            group('#query', () {
              setUp(() {
                results = idx.query((q) {
                  q.term(
                      'qwertyuiop', Clause(presence: QueryPresence.REQUIRED));
                  q.term('green', Clause(presence: QueryPresence.OPTIONAL));
                });
              });

              assertions();
            });

            group('#search', () {
              setUp(() {
                results = idx.search('+qwertyuiop green');
              });

              assertions();
            });
          });

          group('field match', () {
            assertions() {
              test('one result found', () {
                Assert.lengthOf(results, 1);
              });

              test('matching documents returned', () {
                Assert.equal('b', results[0].ref);
              });

              test('matching terms returned', () {
                Assert.sameMembers(
                    ['plant', 'green'], results[0].matchData.metadata.keys);
              });
            }

            group('#query', () {
              setUp(() {
                results = idx.query((q) {
                  q.term(
                      'plant',
                      Clause(
                          presence: QueryPresence.REQUIRED, fields: ['title']));
                  q.term('green', Clause(presence: QueryPresence.OPTIONAL));
                });
              });

              assertions();
            });

            group('#search', () {
              setUp(() {
                results = idx.search('+title:plant green');
              });

              assertions();
            });
          });

          group('field and non field match', () {
            assertions() {
              test('one result found', () {
                Assert.lengthOf(results, 1);
              });

              test('matching documents returned', () {
                Assert.equal('b', results[0].ref);
              });

              test('matching terms returned', () {
                Assert.sameMembers(
                    ['plant', 'green'], results[0].matchData.metadata.keys);
              });
            }

            group('#search', () {
              setUp(() {
                results = idx.search('+title:plant +green');
              });

              assertions();
            });

            group('#query', () {
              setUp(() {
                results = idx.query((q) {
                  q.term(
                      'plant',
                      Clause(
                          fields: ['title'], presence: QueryPresence.REQUIRED));
                  q.term('green', Clause(presence: QueryPresence.REQUIRED));
                });
              });

              assertions();
            });
          });

          group('different fields', () {
            assertions() {
              test('one result found', () {
                Assert.lengthOf(results, 1);
              });

              test('matching documents returned', () {
                Assert.equal('b', results[0].ref);
              });

              test('matching terms returned', () {
                Assert.sameMembers(
                    ['studi', 'plant'], results[0].matchData.metadata.keys);
              });
            }

            group('#search', () {
              setUp(() {
                results = idx.search('+title:plant +body:study');
              });

              assertions();
            });

            group('#query', () {
              setUp(() {
                results = idx.query((q) {
                  q.term(
                      'plant',
                      Clause(
                          fields: ['title'], presence: QueryPresence.REQUIRED));
                  q.term(
                      'study',
                      Clause(
                          fields: ['body'], presence: QueryPresence.REQUIRED));
                });
              });

              assertions();
            });
          });

          group('different fields one without match', () {
            assertions() {
              test('no matches', () {
                Assert.lengthOf(results, 0);
              });
            }

            group('#search', () {
              setUp(() {
                results = idx.search('+title:plant +body:qwertyuiop');
              });

              assertions();
            });

            group('#query', () {
              setUp(() {
                results = idx.query((q) {
                  q.term(
                      'plant',
                      Clause(
                          fields: ['title'], presence: QueryPresence.REQUIRED));
                  q.term(
                      'qwertyuiop',
                      Clause(
                          fields: ['body'], presence: QueryPresence.REQUIRED));
                });
              });

              assertions();
            });
          });
        });

        group('combined', () {
          assertions() {
            test('one result found', () {
              Assert.lengthOf(results, 1);
            });

            test('matching documents returned', () {
              Assert.equal('b', results[0].ref);
            });

            test('matching terms returned', () {
              Assert.sameMembers(
                  ['plant', 'green'], results[0].matchData.metadata.keys);
            });
          }

          group('#query', () {
            setUp(() {
              results = idx.query((q) {
                q.term('plant', Clause(presence: QueryPresence.REQUIRED));
                q.term('green', Clause(presence: QueryPresence.OPTIONAL));
                q.term('office', Clause(presence: QueryPresence.PROHIBITED));
              });
            });

            assertions();
          });

          group('#search', () {
            setUp(() {
              results = idx.search('+plant green -office');
            });

            assertions();
          });
        });
      });
    });
  });
}
