// ignore_for_file: constant_identifier_names, non_constant_identifier_names

const Query_wildcard = '*';
const Query_wildcard_NONE = 0;
const Query_wildcard_LEADING = 1;
const Query_wildcard_TRAILING = 2;

enum QueryPresence { OPTIONAL, REQUIRED, PROHIBITED }

class Clause {
  List<String>? fields;
  int? boost;
  bool? usePipeline;
  QueryPresence? presence;
  int? wildcard;
  String term;
  int? editDistance;

  Clause({
    this.fields,
    this.boost,
    this.usePipeline,
    this.presence,
    this.wildcard,
    this.term = '',
    this.editDistance,
  });

  Clause clone() {
    return Clause(
      fields: fields != null ? [...fields!] : [],
      boost: boost,
      usePipeline: usePipeline,
      presence: presence,
      wildcard: wildcard,
      term: term,
      editDistance: editDistance,
    );
  }
}

class Query {
  List<Clause> clauses = [];
  List<String> allFields;
  QueryPresence presence;

  Query(this.allFields, {this.presence = QueryPresence.OPTIONAL});

  Query clause(Clause clause) {
    clause.fields ??= allFields;
    clause.boost ??= 1;
    clause.usePipeline ??= true;
    clause.wildcard ??= Query_wildcard_NONE;
    clause.presence ??= QueryPresence.OPTIONAL;

    bool leadingBit =
        clause.wildcard! & Query_wildcard_LEADING == Query_wildcard_LEADING;
    if (leadingBit && (clause.term[0] != Query_wildcard)) {
      clause.term = "*${clause.term}";
    }

    bool trailingBit =
        clause.wildcard! & Query_wildcard_TRAILING == Query_wildcard_TRAILING;
    if (trailingBit &&
        (clause.term[clause.term.length - 1] != Query_wildcard)) {
      clause.term = "${clause.term}*";
    }
    clauses.add(clause);

    return this;
  }

  bool isNegated() {
    for (var i = 0; i < clauses.length; i++) {
      if (clauses[i].presence != QueryPresence.PROHIBITED) {
        return false;
      }
    }
    return true;
  }

  Query term(dynamic term, [Clause? options]) {
    if (term! is String && term! is List<dynamic>) {
      throw Exception(
          'The first paramter needs to be String or a list of Strings ');
    }
    if (term is List<dynamic>) {
      for (dynamic t in term) {
        this.term(t, options?.clone());
      }
      return this;
    }

    Clause clause = options ?? Clause();
    clause.term = term.toString();
    this.clause(clause);
    return this;
  }
}
