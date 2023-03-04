import 'package:test/test.dart';
import 'package:lunr/query_lexer.dart' as lunr;
import 'package:lunr/query_lexer.dart';

void main() {
  group('lunr.QueryLexer', () {
    group('#run', () {
      late lunr.QueryLexer lexer;
      late Lexeme lexeme;

      lex(str) {
        var lexer = lunr.QueryLexer(str);
        lexer.run();
        return lexer;
      }

      group('single term', () {
        setUp(() {
          lexer = lex('foo');
        });

        test('produces 1 lexeme', () {
          expect(lexer.lexemes.length, equals(1));
        });

        group('lexeme', () {
          setUp(() {
            lexeme = lexer.lexemes[0];
          });

          test('#type', () {
            expect(lunr.QueryLexer.TERM, equals(lexeme.type.toString()));
            expect(LexemeType.TERM, equals(lexeme.type));
          });

          test('#str', () {
            expect('foo', equals(lexeme.str));
          });

          test('#start', () {
            expect(0, equals(lexeme.start));
          });

          test('#end', () {
            expect(3, equals(lexeme.end));
          });
        });
      });

      // embedded hyphens should not be confused with
      // presence operators
      group('single term with hyphen', () {
        setUp(() {
          lexer = lex('foo-bar');
        });

        test('produces 2 lexeme', () {
          expect(lexer.lexemes.length, equals(2));
        });

        group('lexeme', () {
          late Lexeme fooLexeme;
          late Lexeme barLexeme;

          setUp(() {
            fooLexeme = lexer.lexemes[0];
            barLexeme = lexer.lexemes[1];
          });

          test('#type', () {
            expect(lunr.QueryLexer.TERM, equals(fooLexeme.type.toString()));
            expect(lunr.QueryLexer.TERM, equals(barLexeme.type.toString()));
          });

          test('#str', () {
            expect('foo', equals(fooLexeme.str));
            expect('bar', equals(barLexeme.str));
          });

          test('#start', () {
            expect(0, equals(fooLexeme.start));
            expect(4, equals(barLexeme.start));
          });

          test('#end', () {
            expect(3, equals(fooLexeme.end));
            expect(7, equals(barLexeme.end));
          });
        });
      });

      group('term escape char', () {
        setUp(() {
          lexer = lex("foo\\:bar");
        });

        test('produces 1 lexeme', () {
          expect(lexer.lexemes.length, equals(1));
        });

        group('lexeme', () {
          setUp(() {
            lexeme = lexer.lexemes[0];
          });

          test('#type', () {
            expect(lunr.QueryLexer.TERM, equals(lexeme.type.toString()));
          });

          test('#str', () {
            expect('foo:bar', equals(lexeme.str));
          });

          test('#start', () {
            expect(0, equals(lexeme.start));
          });

          test('#end', () {
            expect(8, equals(lexeme.end));
          });
        });
      });

      group('multiple terms', () {
        setUp(() {
          lexer = lex('foo bar');
        });

        test('produces 2 lexems', () {
          expect(lexer.lexemes.length, equals(2));
        });

        group('lexemes', () {
          late Lexeme fooLexeme;
          late Lexeme barLexeme;

          setUp(() {
            fooLexeme = lexer.lexemes[0];
            barLexeme = lexer.lexemes[1];
          });

          test('#type', () {
            expect(lunr.QueryLexer.TERM, equals(fooLexeme.type.toString()));
            expect(lunr.QueryLexer.TERM, equals(barLexeme.type.toString()));
          });

          test('#str', () {
            expect('foo', equals(fooLexeme.str));
            expect('bar', equals(barLexeme.str));
          });

          test('#start', () {
            expect(0, equals(fooLexeme.start));
            expect(4, equals(barLexeme.start));
          });

          test('#end', () {
            expect(3, equals(fooLexeme.end));
            expect(7, equals(barLexeme.end));
          });
        });
      });

      group('multiple terms with presence', () {
        setUp(() {
          lexer = lex('+foo +bar');
        });

        test('produces 2 lexems', () {
          expect(lexer.lexemes.length, equals(4));
        });

        group('lexemes', () {
          late Lexeme fooPresenceLexeme;
          late Lexeme fooTermLexeme;
          late Lexeme barPresenceLexeme;
          late Lexeme barTermLexeme;

          setUp(() {
            fooPresenceLexeme = lexer.lexemes[0];
            fooTermLexeme = lexer.lexemes[1];

            barPresenceLexeme = lexer.lexemes[2];
            barTermLexeme = lexer.lexemes[3];
          });

          test('#type', () {
            expect(lunr.QueryLexer.TERM, equals(fooTermLexeme.type.toString()));
            expect(LexemeType.TERM, equals(fooTermLexeme.type));
            expect(lunr.QueryLexer.TERM, equals(barTermLexeme.type.toString()));
            expect(LexemeType.TERM, equals(barTermLexeme.type));

            expect(lunr.QueryLexer.PRESENCE,
                equals(fooPresenceLexeme.type.toString()));
            expect(LexemeType.PRESENCE, equals(fooPresenceLexeme.type));
            expect(lunr.QueryLexer.PRESENCE,
                equals(barPresenceLexeme.type.toString()));
            expect(LexemeType.PRESENCE, equals(barPresenceLexeme.type));
          });

          test('#str', () {
            expect('foo', equals(fooTermLexeme.str));
            expect('bar', equals(barTermLexeme.str));

            expect('+', equals(fooPresenceLexeme.str));
            expect('+', equals(barPresenceLexeme.str));
          });
        });
      });

      group('multiple terms with presence and fuzz', () {
        setUp(() {
          lexer = lex('+foo~1 +bar');
        });

        test('produces n lexemes', () {
          expect(lexer.lexemes.length, equals(5));
        });

        group('lexemes', () {
          late Lexeme fooPresenceLexeme;
          late Lexeme fooTermLexeme;
          late Lexeme fooFuzzLexeme;
          late Lexeme barPresenceLexeme;
          late Lexeme barTermLexeme;

          setUp(() {
            fooPresenceLexeme = lexer.lexemes[0];
            fooTermLexeme = lexer.lexemes[1];
            fooFuzzLexeme = lexer.lexemes[2];
            barPresenceLexeme = lexer.lexemes[3];
            barTermLexeme = lexer.lexemes[4];
          });

          test('#type', () {
            expect(lunr.QueryLexer.PRESENCE,
                equals(fooPresenceLexeme.type.toString()));
            expect(lunr.QueryLexer.TERM, equals(fooTermLexeme.type.toString()));
            expect(lunr.QueryLexer.EDIT_DISTANCE,
                equals(fooFuzzLexeme.type.toString()));
            expect(lunr.QueryLexer.PRESENCE,
                equals(barPresenceLexeme.type.toString()));
            expect(lunr.QueryLexer.TERM, equals(barTermLexeme.type.toString()));
          });
        });
      });

      group('separator length > 1', () {
        setUp(() {
          lexer = lex('foo    bar');
        });

        test('produces 2 lexems', () {
          expect(lexer.lexemes.length, equals(2));
        });

        group('lexemes', () {
          late Lexeme fooLexeme;
          late Lexeme barLexeme;

          setUp(() {
            fooLexeme = lexer.lexemes[0];
            barLexeme = lexer.lexemes[1];
          });

          test('#type', () {
            expect(lunr.QueryLexer.TERM, equals(fooLexeme.type.toString()));
            expect(lunr.QueryLexer.TERM, equals(barLexeme.type.toString()));
          });

          test('#str', () {
            expect('foo', equals(fooLexeme.str));
            expect('bar', equals(barLexeme.str));
          });

          test('#start', () {
            expect(0, equals(fooLexeme.start));
            expect(7, equals(barLexeme.start));
          });

          test('#end', () {
            expect(3, equals(fooLexeme.end));
            expect(10, equals(barLexeme.end));
          });
        });
      });

      group('hyphen (-) considered a seperator', () {
        setUp(() {
          lexer = lex('foo-bar');
        });

        test('produces 1 lexeme', () {
          expect(lexer.lexemes.length, equals(2));
        });
      });

      group('term with field', () {
        setUp(() {
          lexer = lex('title:foo');
        });

        test('produces 2 lexems', () {
          expect(lexer.lexemes.length, equals(2));
        });

        group('lexemes', () {
          late Lexeme fieldLexeme;
          late Lexeme termLexeme;

          setUp(() {
            fieldLexeme = lexer.lexemes[0];
            termLexeme = lexer.lexemes[1];
          });

          test('#type', () {
            expect(lunr.QueryLexer.FIELD, equals(fieldLexeme.type.toString()));
            expect(lunr.QueryLexer.TERM, equals(termLexeme.type.toString()));
          });

          test('#str', () {
            expect('title', equals(fieldLexeme.str));
            expect('foo', equals(termLexeme.str));
          });

          test('#start', () {
            expect(0, equals(fieldLexeme.start));
            expect(6, equals(termLexeme.start));
          });

          test('#end', () {
            expect(5, equals(fieldLexeme.end));
            expect(9, equals(termLexeme.end));
          });
        });
      });

      group('term with field with escape char', () {
        setUp(() {
          lexer = lex("ti\\:tle:foo");
        });

        test('produces 1 lexeme', () {
          expect(lexer.lexemes.length, equals(2));
        });

        group('lexeme', () {
          late Lexeme fieldLexeme;
          late Lexeme termLexeme;
          setUp(() {
            fieldLexeme = lexer.lexemes[0];
            termLexeme = lexer.lexemes[1];
          });

          test('#type', () {
            expect(lunr.QueryLexer.FIELD, equals(fieldLexeme.type.toString()));
            expect(lunr.QueryLexer.TERM, equals(termLexeme.type.toString()));
          });

          test('#str', () {
            expect('ti:tle', equals(fieldLexeme.str));
            expect('foo', equals(termLexeme.str));
          });

          test('#start', () {
            expect(0, equals(fieldLexeme.start));
            expect(8, equals(termLexeme.start));
          });

          test('#end', () {
            expect(7, equals(fieldLexeme.end));
            expect(11, equals(termLexeme.end));
          });
        });
      });

      group('term with presence required', () {
        setUp(() {
          lexer = lex('+foo');
        });

        test('produces 2 lexemes', () {
          expect(lexer.lexemes.length, equals(2));
        });

        group('lexemes', () {
          late Lexeme presenceLexeme;
          late Lexeme termLexeme;

          setUp(() {
            presenceLexeme = lexer.lexemes[0];
            termLexeme = lexer.lexemes[1];
          });

          test('#type', () {
            expect(lunr.QueryLexer.PRESENCE,
                equals(presenceLexeme.type.toString()));
            expect(lunr.QueryLexer.TERM, equals(termLexeme.type.toString()));
          });

          test('#str', () {
            expect('+', equals(presenceLexeme.str));
            expect('foo', equals(termLexeme.str));
          });

          test('#start', () {
            expect(1, equals(termLexeme.start));
            expect(0, equals(presenceLexeme.start));
          });

          test('#end', () {
            expect(4, equals(termLexeme.end));
            expect(1, equals(presenceLexeme.end));
          });
        });
      });

      group('term with field with presence required', () {
        setUp(() {
          lexer = lex('+title:foo');
        });

        test('produces 3 lexemes', () {
          expect(lexer.lexemes.length, equals(3));
        });

        group('lexemes', () {
          late Lexeme presenceLexeme;
          late Lexeme fieldLexeme;
          late Lexeme termLexeme;

          setUp(() {
            presenceLexeme = lexer.lexemes[0];
            fieldLexeme = lexer.lexemes[1];
            termLexeme = lexer.lexemes[2];
          });

          test('#type', () {
            expect(lunr.QueryLexer.PRESENCE,
                equals(presenceLexeme.type.toString()));
            expect(lunr.QueryLexer.FIELD, equals(fieldLexeme.type.toString()));
            expect(lunr.QueryLexer.TERM, equals(termLexeme.type.toString()));
          });

          test('#str', () {
            expect('+', equals(presenceLexeme.str));
            expect('title', equals(fieldLexeme.str));
            expect('foo', equals(termLexeme.str));
          });

          test('#start', () {
            expect(0, equals(presenceLexeme.start));
            expect(1, equals(fieldLexeme.start));
            expect(7, equals(termLexeme.start));
          });

          test('#end', () {
            expect(1, equals(presenceLexeme.end));
            expect(6, equals(fieldLexeme.end));
            expect(10, equals(termLexeme.end));
          });
        });
      });

      group('term with presence prohibited', () {
        setUp(() {
          lexer = lex('-foo');
        });

        test('produces 2 lexemes', () {
          expect(lexer.lexemes.length, equals(2));
        });

        group('lexemes', () {
          late Lexeme presenceLexeme;
          late Lexeme termLexeme;

          setUp(() {
            presenceLexeme = lexer.lexemes[0];
            termLexeme = lexer.lexemes[1];
          });

          test('#type', () {
            expect(lunr.QueryLexer.PRESENCE,
                equals(presenceLexeme.type.toString()));
            expect(lunr.QueryLexer.TERM, equals(termLexeme.type.toString()));
          });

          test('#str', () {
            expect('-', equals(presenceLexeme.str));
            expect('foo', equals(termLexeme.str));
          });

          test('#start', () {
            expect(1, equals(termLexeme.start));
            expect(0, equals(presenceLexeme.start));
          });

          test('#end', () {
            expect(4, equals(termLexeme.end));
            expect(1, equals(presenceLexeme.end));
          });
        });
      });

      group('term with edit distance', () {
        setUp(() {
          lexer = lex('foo~2');
        });

        test('produces 2 lexems', () {
          expect(lexer.lexemes.length, equals(2));
        });

        group('lexemes', () {
          late Lexeme termLexeme;
          late Lexeme editDistanceLexeme;
          setUp(() {
            termLexeme = lexer.lexemes[0];
            editDistanceLexeme = lexer.lexemes[1];
          });

          test('#type', () {
            expect(lunr.QueryLexer.TERM, equals(termLexeme.type.toString()));
            expect(lunr.QueryLexer.EDIT_DISTANCE,
                equals(editDistanceLexeme.type.toString()));
          });

          test('#str', () {
            expect('foo', equals(termLexeme.str));
            expect('2', equals(editDistanceLexeme.str));
          });

          test('#start', () {
            expect(0, equals(termLexeme.start));
            expect(4, equals(editDistanceLexeme.start));
          });

          test('#end', () {
            expect(3, equals(termLexeme.end));
            expect(5, equals(editDistanceLexeme.end));
          });
        });
      });

      group('term with boost', () {
        setUp(() {
          lexer = lex('foo^10');
        });

        test('produces 2 lexems', () {
          expect(lexer.lexemes.length, equals(2));
        });

        group('lexemes', () {
          late Lexeme termLexeme;
          late Lexeme boostLexeme;

          setUp(() {
            termLexeme = lexer.lexemes[0];
            boostLexeme = lexer.lexemes[1];
          });

          test('#type', () {
            expect(lunr.QueryLexer.TERM, equals(termLexeme.type.toString()));
            expect(lunr.QueryLexer.BOOST, equals(boostLexeme.type.toString()));
          });

          test('#str', () {
            expect('foo', equals(termLexeme.str));
            expect('10', equals(boostLexeme.str));
          });

          test('#start', () {
            expect(0, equals(termLexeme.start));
            expect(4, equals(boostLexeme.start));
          });

          test('#end', () {
            expect(3, equals(termLexeme.end));
            expect(6, equals(boostLexeme.end));
          });
        });
      });

      group('term with field, boost and edit distance', () {
        setUp(() {
          lexer = lex('title:foo^10~5');
        });

        test('produces 4 lexems', () {
          expect(lexer.lexemes.length, equals(4));
        });

        group('lexemes', () {
          late Lexeme fieldLexeme;
          late Lexeme termLexeme;
          late Lexeme boostLexeme;
          late Lexeme editDistanceLexeme;

          setUp(() {
            fieldLexeme = lexer.lexemes[0];
            termLexeme = lexer.lexemes[1];
            boostLexeme = lexer.lexemes[2];
            editDistanceLexeme = lexer.lexemes[3];
          });

          test('#type', () {
            expect(lunr.QueryLexer.FIELD, equals(fieldLexeme.type.toString()));
            expect(lunr.QueryLexer.TERM, equals(termLexeme.type.toString()));
            expect(lunr.QueryLexer.BOOST, equals(boostLexeme.type.toString()));
            expect(lunr.QueryLexer.EDIT_DISTANCE,
                equals(editDistanceLexeme.type.toString()));
          });

          test('#str', () {
            expect('title', equals(fieldLexeme.str));
            expect('foo', equals(termLexeme.str));
            expect('10', equals(boostLexeme.str));
            expect('5', equals(editDistanceLexeme.str));
          });

          test('#start', () {
            expect(0, equals(fieldLexeme.start));
            expect(6, equals(termLexeme.start));
            expect(10, equals(boostLexeme.start));
            expect(13, equals(editDistanceLexeme.start));
          });

          test('#end', () {
            expect(5, equals(fieldLexeme.end));
            expect(9, equals(termLexeme.end));
            expect(12, equals(boostLexeme.end));
            expect(14, equals(editDistanceLexeme.end));
          });
        });
      });
    });
  });
}
