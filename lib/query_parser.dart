import 'query.dart';
import 'query_lexer.dart';
import 'query_parse_error.dart';

typedef QueryParserState = dynamic Function(QueryParser parser);

class QueryParser {
  late QueryLexer lexer;
  Query query;
  Clause currentClause = Clause();
  int lexemeIdx = 0;
  List<Lexeme> lexemes = [];

  QueryParser(String str, this.query) {
    lexer = QueryLexer(str);
  }

  parse() {
    lexer.run();
    lexemes = lexer.lexemes;

    QueryParserState? state = parseClause;

    while (state != null) {
      state = state(this);
    }

    return query;
  }

  Lexeme? peekLexeme() =>
      lexemeIdx < lexemes.length ? lexemes[lexemeIdx] : null;

  Lexeme? consumeLexeme() {
    var lexeme = peekLexeme();
    lexemeIdx += 1;
    return lexeme;
  }

  nextClause() {
    var completedClause = currentClause;
    query.clause(completedClause);
    currentClause = Clause();
  }

  static QueryParserState? parseClause(QueryParser parser) {
    var lexeme = parser.peekLexeme();

    if (lexeme == null) {
      return null;
    }

    switch (lexeme.type) {
      case LexemeType.PRESENCE:
        return QueryParser.parsePresence;
      case LexemeType.FIELD:
        return QueryParser.parseField;
      case LexemeType.TERM:
        return QueryParser.parseTerm;
      default:
        var errorMessage =
            'expected either a field or a term, found ${lexeme.type}';

        if (lexeme.str.isNotEmpty) {
          errorMessage += "${" with value '${lexeme.str}"}'";
        }

        throw QueryParseError(errorMessage, lexeme.start, lexeme.end);
    }
  }

  static QueryParserState? parsePresence(QueryParser parser) {
    var lexeme = parser.consumeLexeme();

    if (lexeme == null) {
      return null;
    }

    switch (lexeme.str) {
      case "-":
        parser.currentClause.presence = QueryPresence.PROHIBITED;
        break;
      case "+":
        parser.currentClause.presence = QueryPresence.REQUIRED;
        break;
      default:
        var errorMessage = 'unrecognised presence operator ${lexeme.str}';
        throw QueryParseError(errorMessage, lexeme.start, lexeme.end);
    }

    var nextLexeme = parser.peekLexeme();

    if (nextLexeme == null) {
      var errorMessage = "expecting term or field, found nothing";
      throw QueryParseError(errorMessage, lexeme.start, lexeme.end);
    }

    switch (nextLexeme.type) {
      case LexemeType.FIELD:
        return QueryParser.parseField;
      case LexemeType.TERM:
        return QueryParser.parseTerm;
      default:
        var errorMessage = 'expecting term or field, found ${nextLexeme.type}';
        throw QueryParseError(errorMessage, nextLexeme.start, nextLexeme.end);
    }
  }

  static QueryParserState? parseField(QueryParser parser) {
    var lexeme = parser.consumeLexeme();

    if (lexeme == null) {
      return null;
    }

    if (!parser.query.allFields.contains(lexeme.str)) {
      var possibleFields = parser.query.allFields.map((f) => "'$f'").join(', '),
          errorMessage =
              "unrecognised field '${lexeme.str}', possible fields: $possibleFields";

      throw QueryParseError(errorMessage, lexeme.start, lexeme.end);
    }

    parser.currentClause.fields = [lexeme.str];

    var nextLexeme = parser.peekLexeme();

    if (nextLexeme == null) {
      var errorMessage = 'expecting term, found nothing';
      throw QueryParseError(errorMessage, lexeme.start, lexeme.end);
    }

    switch (nextLexeme.type) {
      case LexemeType.TERM:
        return QueryParser.parseTerm;
      default:
        var errorMessage = "expecting term, found '${nextLexeme.type}'";
        throw QueryParseError(errorMessage, nextLexeme.start, nextLexeme.end);
    }
  }

  static QueryParserState? parseTerm(QueryParser parser) {
    var lexeme = parser.consumeLexeme();

    if (lexeme == null) {
      return null;
    }

    parser.currentClause.term = lexeme.str.toLowerCase();

    if (lexeme.str.contains("*")) {
      parser.currentClause.usePipeline = false;
    }

    var nextLexeme = parser.peekLexeme();

    if (nextLexeme == null) {
      parser.nextClause();
      return null;
    }

    switch (nextLexeme.type) {
      case LexemeType.TERM:
        parser.nextClause();
        return QueryParser.parseTerm;
      case LexemeType.FIELD:
        parser.nextClause();
        return QueryParser.parseField;
      case LexemeType.EDIT_DISTANCE:
        return QueryParser.parseEditDistance;
      case LexemeType.BOOST:
        return QueryParser.parseBoost;
      case LexemeType.PRESENCE:
        parser.nextClause();
        return QueryParser.parsePresence;
      default:
        var errorMessage = "Unexpected lexeme type '${nextLexeme.type}'";
        throw QueryParseError(errorMessage, nextLexeme.start, nextLexeme.end);
    }
  }

  static QueryParserState? parseEditDistance(QueryParser parser) {
    var lexeme = parser.consumeLexeme();

    if (lexeme == null) {
      return null;
    }

    var editDistance = int.tryParse(lexeme.str, radix: 10);

    if (editDistance == null) {
      var errorMessage = "edit distance must be numeric";
      throw QueryParseError(errorMessage, lexeme.start, lexeme.end);
    }

    parser.currentClause.editDistance = editDistance;

    var nextLexeme = parser.peekLexeme();

    if (nextLexeme == null) {
      parser.nextClause();
      return null;
    }

    switch (nextLexeme.type) {
      case LexemeType.TERM:
        parser.nextClause();
        return QueryParser.parseTerm;
      case LexemeType.FIELD:
        parser.nextClause();
        return QueryParser.parseField;
      case LexemeType.EDIT_DISTANCE:
        return QueryParser.parseEditDistance;
      case LexemeType.BOOST:
        return QueryParser.parseBoost;
      case LexemeType.PRESENCE:
        parser.nextClause();
        return QueryParser.parsePresence;
      default:
        var errorMessage = "Unexpected lexeme type '${nextLexeme.type}'";
        throw QueryParseError(errorMessage, nextLexeme.start, nextLexeme.end);
    }
  }

  static QueryParserState? parseBoost(QueryParser parser) {
    var lexeme = parser.consumeLexeme();

    if (lexeme == null) {
      return null;
    }

    var boost = int.tryParse(lexeme.str, radix: 10);

    if (boost == null) {
      var errorMessage = "boost must be numeric";
      throw QueryParseError(errorMessage, lexeme.start, lexeme.end);
    }

    parser.currentClause.boost = boost;

    var nextLexeme = parser.peekLexeme();

    if (nextLexeme == null) {
      parser.nextClause();
      return null;
    }

    switch (nextLexeme.type) {
      case LexemeType.TERM:
        parser.nextClause();
        return QueryParser.parseTerm;
      case LexemeType.FIELD:
        parser.nextClause();
        return QueryParser.parseField;
      case LexemeType.EDIT_DISTANCE:
        return QueryParser.parseEditDistance;
      case LexemeType.BOOST:
        return QueryParser.parseBoost;
      case LexemeType.PRESENCE:
        parser.nextClause();
        return QueryParser.parsePresence;
      default:
        var errorMessage = "Unexpected lexeme type '${nextLexeme.type}'";
        throw QueryParseError(errorMessage, nextLexeme.start, nextLexeme.end);
    }
  }
}
