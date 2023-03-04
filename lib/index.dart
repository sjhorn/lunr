import 'dart:collection';

import 'package:lunr/lunr.dart';

import 'query_parser.dart';
import 'set.dart' as lunr;

typedef QueryCallback = dynamic Function(Query query /*, Query query2*/);

class InvertedIndex extends MapBase<dynamic, Posting> {
  late Map<Token, Posting> store;

  InvertedIndex([Map<Token, Posting>? idf]) {
    store = idf ?? {};
  }

  @override
  operator [](Object? key) =>
      key is Token ? store[key] : store[Token(key.toString())];

  @override
  void operator []=(key, value) =>
      store[key is Token ? key : Token(key.toString())] = value;

  @override
  void clear() => store.clear();

  @override
  Iterable get keys => store.keys;

  @override
  remove(Object? key) =>
      store.remove(key is Token ? key : Token(key.toString()));
}

class Posting extends MapBase<String, dynamic> {
  int index = 0;
  Map<String, dynamic> items = {};

  Posting();

  @override
  operator [](Object? key) {
    if (key == '_index') return index;
    return items[key];
  }

  @override
  void operator []=(key, value) =>
      key == '_index' ? index = value : items[key] = value;

  @override
  void clear() => items.clear();

  @override
  Iterable<String> get keys => ['_index', ...items.keys];

  @override
  remove(Object? key) => items.remove(key);

  Map<String, dynamic> toJson() => {
        '_index': index,
        ...items,
      };

  factory Posting.fromJson(Map<String, dynamic> map) {
    var p = Posting();
    p.index = map['_index'];
    p.items = Map.from(map)..removeWhere((key, value) => key == '_index');
    return p;
  }
}

class DocMatch {
  String ref;
  double score;
  MatchData matchData;

  DocMatch({
    required this.ref,
    required this.score,
    required this.matchData,
  });
  @override
  String toString() =>
      'DocMatch(ref: $ref, score: $score, matchData: $matchData)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DocMatch &&
        other.ref == ref &&
        other.score == score &&
        other.matchData == matchData;
  }

  @override
  int get hashCode => ref.hashCode ^ score.hashCode ^ matchData.hashCode;

  Map<String, dynamic> toJson() {
    return {
      'ref': ref,
      'score': score,
      'matchData': matchData.toJson(),
    };
  }

  factory DocMatch.fromJson(Map<String, dynamic> map) {
    return DocMatch(
      ref: map['ref'],
      score: map['score'],
      matchData: MatchData.fromJson(map['matchData']),
    );
  }
}

/// An index contains the built index of all documents and provides a query interface
/// to the index.
///
/// Usually instances of lunr.Index will not be created using this constructor, instead
/// lunr.Builder should be used to construct new indexes, or lunr.Index.load should be
/// used to load previously built and serialized indexes.
///
/// [invertedIndex] - An index of term/field to document reference.
/// [fieldVectors] - Field vectors
/// [tokenSet] - An set of all corpus tokens.
/// [fields] - The names of indexed document fields.
/// [pipeline] - The pipeline to use for search terms.
class Index {
  InvertedIndex invertedIndex;
  Map<FieldRef, Vector> fieldVectors;
  TokenSet tokenSet;
  List<String> fields;
  Pipeline pipeline;
  Index({
    required this.invertedIndex,
    required this.fieldVectors,
    required this.tokenSet,
    required this.fields,
    required this.pipeline,
  });

  /// Performs a search against the index using lunr query syntax.
  ///
  /// Results will be returned sorted by their score, the most relevant results
  /// will be returned first.  For details on how the score is calculated, please see
  /// the [link](https://lunrjs.com/guides/searching.html#scoring|guide).
  ///
  /// For more programmatic querying use lunr.Index#query.
  ///
  /// [queryString] - A string containing a lunr query.
  /// Throws [QueryParseError] If the passed query string cannot be parsed.
  List<DocMatch> search(String queryString) {
    return query((query) {
      var parser = QueryParser(queryString, query);
      parser.parse();
    });
  }

  /// Performs a query against the index using the yielded lunr.Query object.
  ///
  /// If performing programmatic queries against the index, this method is preferred
  /// over lunr.Index#search so as to avoid the additional query parsing overhead.
  ///
  /// A query object is yielded to the supplied function which should be used to
  /// express the query to be run against the index.
  ///
  /// Note that although this function takes a callback parameter it is _not_ an
  /// asynchronous operation, the callback is just yielded a query object to be
  /// customized.
  ///
  /// [QueryCallback] fn - A function that is used to build the query.
  List<DocMatch> query(QueryCallback fn) {
    // for each query clause
    // * process terms
    // * expand terms from token set
    // * find matching documents and metadata
    // * get document vectors
    // * score documents

    Query query = Query(fields);
    Map<FieldRef, MatchData> matchingFields = {};
    Map<String, Vector> queryVectors = {};
    var termFieldCache = {}, requiredMatches = {}, prohibitedMatches = {};

    // To support field level boosts a query vector is created per
    // field. An empty vector is eagerly created to support negated
    // queries.
    for (String field in fields) {
      queryVectors[field] = Vector();
    }

    fn(query /*, query*/);

    for (Clause clause in query.clauses) {
      // Unless the pipeline has been disabled for this term, which is
      // the case for terms with wildcards, we need to pass the clause
      // term through the search pipeline. A pipeline returns an array
      // of processed terms. Pipeline functions may expand the passed
      // term, which means we may end up performing multiple index lookups
      // for a single query term.
      List<String>? terms;
      lunr.Set clauseMatches = lunr.Set.empty;

      if (clause.usePipeline ?? false) {
        terms =
            pipeline.runString(clause.term, {'fields': clause.fields ?? []});
      } else {
        terms = [clause.term];
      }

      for (String term in terms) {
        /*
       * Each term returned from the pipeline needs to use the same query
       * clause object, e.g. the same boost and or edit distance. The
       * simplest way to do this is to re-use the clause object but mutate
       * its term property.
       */
        clause.term = term;

        /*
       * From the term in the clause we create a token set which will then
       * be used to intersect the indexes token set to get a list of terms
       * to lookup in the inverted index
       */
        TokenSet termTokenSet = TokenSet.fromClause(clause);
        List<String> expandedTerms = tokenSet.intersect(termTokenSet).toArray();

        /*
       * If a term marked as required does not exist in the tokenSet it is
       * impossible for the search to return any matches. We set all the field
       * scoped required matches set to empty and stop examining any further
       * clauses.
       */
        if (expandedTerms.isEmpty &&
            clause.presence == QueryPresence.REQUIRED) {
          for (String? field in clause.fields!) {
            requiredMatches[field] = lunr.Set.empty;
          }
          break;
        }

        for (String expandedTerm in expandedTerms) {
          /*
         * For each term get the posting and termIndex, this is required for
         * building the query vector.
         */

          Posting posting = invertedIndex[expandedTerm]!;
          var termIndex = posting.index;

          for (String? field in clause.fields ?? []) {
            /*
           * For each field that this query term is scoped by (by default
           * all fields are in scope) we need to get all the document refs
           * that have this term in that field.
           *
           * The posting is the entry in the invertedIndex for the matching
           * term from above.
           */
            Map<String, dynamic> fieldPosting =
                posting[field].cast<String, dynamic>();
            List<String> matchingDocumentRefs =
                fieldPosting.keys.map((e) => e.toString()).toList();
            String termField = '$expandedTerm/${field!}';
            lunr.Set matchingDocumentsSet = lunr.Set(matchingDocumentRefs);

            /*
           * if the presence of this term is required ensure that the matching
           * documents are added to the set of required matches for this clause.
           *
           */
            if (clause.presence == QueryPresence.REQUIRED) {
              clauseMatches = clauseMatches.union(matchingDocumentsSet);

              if (requiredMatches[field] == null) {
                requiredMatches[field] = lunr.Set.complete;
              }
            }

            /*
           * if the presence of this term is prohibited ensure that the matching
           * documents are added to the set of prohibited matches for this field,
           * creating that set if it does not yet exist.
           */
            if (clause.presence == QueryPresence.PROHIBITED) {
              if (prohibitedMatches[field] == null) {
                prohibitedMatches[field] = lunr.Set.empty;
              }

              prohibitedMatches[field] =
                  prohibitedMatches[field].union(matchingDocumentsSet);

              /*
             * Prohibited matches should not be part of the query vector used for
             * similarity scoring and no metadata should be extracted so we continue
             * to the next field
             */
              continue;
            }

            /*
           * The query field vector is populated using the termIndex found for
           * the term and a unit value with the appropriate boost applied.
           * Using upsert because there could already be an entry in the vector
           * for the term we are working with. In that case we just add the scores
           * together.
           */
            queryVectors[field]!
                .upsert(termIndex, clause.boost, (num a, num b) => a + b);

            /**
           * If we've already seen this term, field combo then we've already collected
           * the matching documents and metadata, no need to go through all that again
           */
            if (termFieldCache[termField] ?? false) {
              continue;
            }

            for (String matchingDocumentRef in matchingDocumentRefs) {
              /*
             * All metadata for this term/field/document triple
             * are then extracted and collected into an instance
             * of lunr.MatchData ready to be returned in the query
             * results
             */
              FieldRef matchingFieldRef = FieldRef(matchingDocumentRef, field);
              Map<String, dynamic> metadata =
                  fieldPosting[matchingDocumentRef].cast<String, dynamic>();
              MatchData? fieldMatch = matchingFields[matchingFieldRef];

              if (fieldMatch == null) {
                matchingFields[matchingFieldRef] =
                    MatchData(expandedTerm, field, metadata);
              } else {
                fieldMatch.add(expandedTerm, field, metadata);
              }
            }

            termFieldCache[termField] = true;
          }
        }
      }

      /**
     * If the presence was required we need to update the requiredMatches field sets.
     * We do this after all fields for the term have collected their matches because
     * the clause terms presence is required in _any_ of the fields not _all_ of the
     * fields.
     */
      if (clause.presence == QueryPresence.REQUIRED) {
        for (String? field in clause.fields ?? []) {
          requiredMatches[field] =
              requiredMatches[field].intersect(clauseMatches);
        }
      }
    }

    /**
   * Need to combine the field scoped required and prohibited
   * matching documents into a global set of required and prohibited
   * matches
   */
    lunr.Set allRequiredMatches = lunr.Set.complete,
        allProhibitedMatches = lunr.Set.empty;

    for (String field in fields) {
      if (requiredMatches.containsKey(field)) {
        allRequiredMatches =
            allRequiredMatches.intersect(requiredMatches[field]);
      }

      if (prohibitedMatches.containsKey(field)) {
        allProhibitedMatches =
            allProhibitedMatches.union(prohibitedMatches[field]);
      }
    }

    Iterable<dynamic> matchingFieldRefs = matchingFields.keys;
    List<DocMatch> results = [];
    Map<String, DocMatch> matches = {};

    /*
   * If the query is negated (contains only prohibited terms)
   * we need to get _all_ fieldRefs currently existing in the
   * index. This is only done when we know that the query is
   * entirely prohibited terms to avoid any cost of getting all
   * fieldRefs unnecessarily.
   *
   * Additionally, blank MatchData must be created to correctly
   * populate the results.
   */
    if (query.isNegated()) {
      matchingFieldRefs = fieldVectors.keys;

      for (var matchingFieldRef in matchingFieldRefs) {
        FieldRef fieldRef = FieldRef.fromString(matchingFieldRef.toString());
        matchingFields[fieldRef] = MatchData();
      }
    }

    for (var matchingFieldRefs in matchingFieldRefs) {
      /*
     * Currently we have document fields that match the query, but we
     * need to return documents. The matchData and scores are combined
     * from multiple fields belonging to the same document.
     *
     * Scores are calculated by field, using the query vectors created
     * above, and combined into a final document score using addition.
     */
      var fieldRef = FieldRef.fromString(matchingFieldRefs.toString());
      String docRef = fieldRef.docRef;

      if (!allRequiredMatches.contains(docRef)) {
        continue;
      }

      if (allProhibitedMatches.contains(docRef)) {
        continue;
      }

      Vector? fieldVector = fieldVectors[fieldRef];
      double score = queryVectors[fieldRef.fieldName]!.similarity(fieldVector);
      DocMatch? docMatch;

      if ((docMatch = matches[docRef]) != null) {
        docMatch!.score += score;
        docMatch.matchData.combine(matchingFields[fieldRef]!);
      } else {
        DocMatch match = DocMatch(
            ref: docRef, score: score, matchData: matchingFields[fieldRef]!);
        matches[docRef] = match;
        results.add(match);
      }
    }

    /*
   * Sort the results objects by score, highest first.
   */
    return results
      ..sort((DocMatch a, DocMatch b) {
        return b.score.compareTo(a.score);
      });
  }

  /// Prepares the index for JSON serialization.
  ///
  /// The schema for this JSON blob will be described in a
  /// separate JSON schema file.
  Map<String, dynamic> toJSON() => toJson();

  Map<String, dynamic> toJson() {
    var fieldVectors = this.fieldVectors.keys.toList().map((ref) {
      return [ref.toString(), this.fieldVectors[ref]!.toJson()];
    }).toList();

    var invertedIndex = (this.invertedIndex.keys.toList()
          ..sort((a, b) => '$a'.compareTo('$b')))
        .map<List>((e) => [e.toString(), this.invertedIndex[e]!.toJson()])
        .toList();

    var pipeline = this.pipeline.toJSON();

    return {
      'version': Lunr.version,
      'fields': fields,
      'fieldVectors': fieldVectors,
      'invertedIndex': invertedIndex,
      'pipeline': pipeline
    };
  }

  /// Loads a previously serialized lunr.Index
  ///
  /// [serializedIndex] - A previously serialized Index
  ///
  factory Index.load(Map<String, dynamic> map) => Index.fromJson(map);

  factory Index.fromJson(Map<String, dynamic> map) {
    Map<FieldRef, Vector> fieldVectors = {};
    List serializedVectors = map['fieldVectors'];
    InvertedIndex invertedIndex = InvertedIndex();
    List serializedInvertedIndex = map['invertedIndex'];
    TokenSetBuilder tokenSetBuilder = TokenSetBuilder();
    Pipeline pipeline = Pipeline.load(map['pipeline'].cast<String>());

    if (map['version'] != Lunr.version) {
      Utils.warn("Version mismatch when loading serialised index. Current"
          "version of lunr '${Lunr.version}' does not match serialized "
          "index '${map['version']}'");
    }

    for (List tuple in serializedVectors) {
      String ref = tuple[0] as String;
      List<num> elements = tuple[1].cast<num>();
      fieldVectors[FieldRef.fromString(ref)] = Vector(elements);
    }

    for (List tuple in serializedInvertedIndex) {
      String term = tuple[0];
      Posting posting = Posting.fromJson(tuple[1]);

      tokenSetBuilder.insert(term);
      invertedIndex[Token(term)] = posting;
    }
    tokenSetBuilder.finish();

    return Index(
      fields: map['fields'].cast<String>(),
      fieldVectors: fieldVectors,
      invertedIndex: invertedIndex,
      tokenSet: tokenSetBuilder.root,
      pipeline: pipeline,
    );
  }
}
