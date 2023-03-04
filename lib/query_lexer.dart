// ignore_for_file: constant_identifier_names

import 'tokenizer.dart';

enum LexemeType {
  EOS,
  FIELD,
  TERM,
  EDIT_DISTANCE,
  BOOST,
  PRESENCE;

  @override
  String toString() => name;

  static LexemeType fromString(String str) {
    switch (str) {
      case QueryLexer.EOS:
        return LexemeType.EOS;
      case QueryLexer.FIELD:
        return LexemeType.FIELD;
      case QueryLexer.TERM:
        return LexemeType.TERM;
      case QueryLexer.EDIT_DISTANCE:
        return LexemeType.EDIT_DISTANCE;
      case QueryLexer.BOOST:
        return LexemeType.BOOST;
      case QueryLexer.PRESENCE:
        return LexemeType.PRESENCE;
      default:
        throw Exception('Invalid LexemType $str');
    }
  }
}

class Lexeme {
  LexemeType type;
  String str;
  int start;
  int end;

  Lexeme({
    required this.type,
    required this.str,
    required this.start,
    required this.end,
  });
}

class QueryLexer {
  static const EOS = 'EOS';
  static const FIELD = 'FIELD';
  static const TERM = 'TERM';
  static const EDIT_DISTANCE = 'EDIT_DISTANCE';
  static const BOOST = 'BOOST';
  static const PRESENCE = 'PRESENCE';

  List<Lexeme> lexemes = [];
  String str;
  late int length;
  int pos = 0;
  int start = 0;
  List escapeCharPositions = [];

  QueryLexer(this.str) {
    length = str.length;
  }

  run() {
    Function? state = QueryLexer.lexText;

    while (state != null) {
      state = state(this);
    }
  }

  String sliceString() {
    var subSlices = [], sliceStart = start, sliceEnd = pos;

    for (var i = 0; i < escapeCharPositions.length; i++) {
      sliceEnd = escapeCharPositions[i];
      subSlices.add(str.substring(sliceStart, sliceEnd));
      sliceStart = sliceEnd + 1;
    }

    subSlices.add(str.substring(sliceStart, pos));
    escapeCharPositions.length = 0;

    return subSlices.join('');
  }

  emit(String type) {
    lexemes.add(Lexeme(
      type: LexemeType.fromString(type),
      str: sliceString(),
      start: start,
      end: pos,
    ));

    start = pos;
  }

  escapeCharacter() {
    escapeCharPositions.add(pos - 1);
    pos += 1;
  }

  String next() {
    if (pos >= length) {
      return QueryLexer.EOS;
    }

    var char = str[pos];
    pos += 1;
    return char;
  }

  width() {
    return pos - start;
  }

  ignore() {
    if (start == pos) {
      pos += 1;
    }

    start = pos;
  }

  backup() {
    pos -= 1;
  }

  acceptDigitRun() {
    String char;
    int charCode;

    do {
      char = next();
      charCode = char.codeUnitAt(0);
    } while (charCode > 47 && charCode < 58);

    if (char != QueryLexer.EOS) {
      backup();
    }
  }

  more() => pos < length;

  static Function? lexField(QueryLexer lexer) {
    lexer.backup();
    lexer.emit(FIELD);
    lexer.ignore();
    return lexText;
  }

  static Function? lexTerm(QueryLexer lexer) {
    if (lexer.width() > 1) {
      lexer.backup();
      lexer.emit(TERM);
    }

    lexer.ignore();

    if (lexer.more()) {
      return lexText;
    }
    return null;
  }

  static Function? lexEditDistance(QueryLexer lexer) {
    lexer.ignore();
    lexer.acceptDigitRun();
    lexer.emit(EDIT_DISTANCE);
    return lexText;
  }

  static Function? lexBoost(QueryLexer lexer) {
    lexer.ignore();
    lexer.acceptDigitRun();
    lexer.emit(BOOST);
    return lexText;
  }

  static Function? lexEOS(QueryLexer lexer) {
    if (lexer.width() > 0) {
      lexer.emit(TERM);
    }
    return null;
  }

// This matches the separator used when tokenising fields
// within a document. These should match otherwise it is
// not possible to search for some tokens within a document.
//
// It is possible for the user to change the separator on the
// tokenizer so it _might_ clash with any other of the special
// characters already used within the search string, e.g. :.
//
// This means that it is possible to change the separator in
// such a way that makes some words unsearchable using a search
// string.
  static RegExp termSeparator = separator;

  static Function? lexText(QueryLexer lexer) {
    while (true) {
      String char = lexer.next();

      if (char == EOS) {
        return lexEOS;
      }

      // Escape character is '\'
      if (char.codeUnitAt(0) == 92) {
        lexer.escapeCharacter();
        continue;
      }

      if (char == ":") {
        return lexField;
      }

      if (char == "~") {
        lexer.backup();
        if (lexer.width() > 0) {
          lexer.emit(TERM);
        }
        return lexEditDistance;
      }

      if (char == "^") {
        lexer.backup();
        if (lexer.width() > 0) {
          lexer.emit(TERM);
        }
        return lexBoost;
      }

      // "+" indicates term presence is required
      // checking for length to ensure that only
      // leading "+" are considered
      if (char == "+" && lexer.width() == 1) {
        lexer.emit(PRESENCE);
        return lexText;
      }

      // "-" indicates term presence is prohibited
      // checking for length to ensure that only
      // leading "-" are considered
      if (char == "-" && lexer.width() == 1) {
        lexer.emit(PRESENCE);
        return lexText;
      }

      if (termSeparator.hasMatch(char)) {
        return lexTerm;
      }
    }
  }
}
