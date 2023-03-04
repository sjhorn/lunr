import 'field_ref.dart';
import 'index.dart';
import 'pipeline.dart';
import 'token.dart';
import 'token_set.dart';
import 'tokenizer.dart' as lunr;
import 'tokenizer.dart';
import 'vector.dart';
import 'idf.dart' as lunr;

typedef FieldMapping = Map<String, dynamic>;
typedef ExtractorCallback = String Function(Map<String, dynamic> lookup);

typedef TermFrequencies = Map<Token, int>;
typedef FieldTermFrequencies = Map<FieldRef, TermFrequencies>;

/// Builder performs indexing on a set of documents and
/// returns instances of Index ready for querying.
///
/// All configuration of the index is done via the builder, the
/// fields to index, the document reference, the text processing
/// pipeline and document scoring parameters are all set on the
/// builder before indexing.
///
class Builder {
  /// Internal reference to the document fields to index.
  final Map<String, FieldMapping> _fields = {};
  final Map<String, dynamic> _documents = {};

  /// Internal reference to the document reference field.
  String ref = 'id';

  /// The inverted index maps terms to document fields.
  InvertedIndex invertedIndex = InvertedIndex();

  /// Keeps track of document term frequencies.
  FieldTermFrequencies fieldTermFrequencies = {};

  /// Keeps track of the length of documents added to the index.
  Map<FieldRef, int> fieldLengths = {};

  /// Function for splitting strings into tokens for indexing.
  Tokenizer tokenizer = lunr.tokenizer;

  /// The pipeline performs text processing on tokens before indexing.
  Pipeline pipeline = Pipeline();

  /// A pipeline for processing search terms before querying the index.
  Pipeline searchPipeline = Pipeline();

  /// Keeps track of the total number of documents indexed.
  int documentCount = 0;

  /// A parameter to control field length normalization, setting this to 0 disabled normalization, 1 fully normalizes field lengths, the default value is 0.75.
  double _b = 0.75;

  /// A parameter to control how quickly an increase in term frequency results in term frequency saturation, the default value is 1.2.
  double _k1 = 1.2;

  /// A counter incremented for each unique term, used to identify a terms position in the vector space.
  int termIndex = 0;

  /// A list of metadata keys that have been whitelisted for entry in the index.
  List<String> metadataWhitelist = [];
  Map<String, double> averageFieldLength = {};
  Map<FieldRef, Vector> fieldVectors = {};
  TokenSet tokenSet = TokenSet();

  Builder();

  get fields => _fields;
  get documents => _documents;

  /// Adds a field to the list of document fields that will be indexed. Every document being
  /// indexed should have this field. Null values for this field in indexed documents will
  /// not cause errors but will limit the chance of that document being retrieved by searches.
  ///
  /// All fields should be added before adding documents to the index. Adding fields after
  /// a document has been indexed will have no effect on already indexed documents.
  ///
  /// Fields can be boosted at build time. This allows terms within that field to have more
  /// importance when ranking search results. Use a field boost to specify that matches within
  /// one field are more important than other fields.
  ///
  /// [fieldName] - The name of a field to index in all documents.
  /// [attributes] - Optional attributes associated with this field.
  /// Throws [Exception] if fieldName cannot contain unsupported characters '/'
  field(String fieldName, [FieldMapping? attributes]) {
    if (RegExp('/').hasMatch(fieldName)) {
      throw Exception("Field '$fieldName' contains illegal character '/'");
    }

    _fields[fieldName] = attributes ?? {};
  }

  /// A parameter to tune the amount of field length normalisation that is applied when
  /// calculating relevance scores. A value of 0 will completely disable any normalisation
  /// and a value of 1 will fully normalise field lengths. The default is 0.75. Values of b
  /// will be clamped to the range 0 - 1.
  ///
  /// [number] - The value to set for this tuning parameter.
  set b(double number) {
    if (number < 0) {
      _b = 0;
    } else if (number > 1) {
      _b = 1;
    } else {
      _b = number;
    }
  }

  double get b => _b;

  /// A parameter that controls the speed at which a rise in term frequency results in term
  /// frequency saturation. The default value is 1.2. Setting this to a higher value will give
  /// slower saturation levels, a lower value will result in quicker saturation.
  ///
  /// [number] - The value to set for this tuning parameter.
  set k1(double number) {
    _k1 = number;
  }

  // ignore: unnecessary_getters_setters
  double get k1 => _k1;

  /// Adds a document to the index.
  ///
  /// Before adding fields to the index the index should have been fully setup, with the document
  /// ref and all fields to index already having been specified.
  ///
  /// The document must have a field name as specified by the ref (by default this is 'id') and
  /// it should have all fields defined for indexing, though null or undefined values will not
  /// cause errors.
  ///
  /// Entire documents can be boosted at build time. Applying a boost to a document indicates that
  /// this document should rank higher in search results than other documents.
  ///
  /// [doc] - The document to add to the index.
  /// [attributes] - Optional attributes associated with this document.
  /// attributes.boost=1 - Boost applied to all terms within this document.
  add(Map<String, dynamic> doc, [Map<String, dynamic>? attributes]) {
    String docRef = doc[ref]!;
    Iterable<String> fields = _fields.keys;

    _documents[docRef] = attributes ?? {};
    documentCount += 1;

    for (String fieldName in fields) {
      var extractor = _fields[fieldName]!['extractor'];
      String field =
          extractor is Function ? extractor(doc) : '${doc[fieldName]}';
      List<Token> tokens = tokenizer(field, {
        'fields': [fieldName]
      });
      List<Token?> terms = pipeline.run(tokens);

      FieldRef fieldRef = FieldRef(docRef, fieldName);
      TermFrequencies fieldTerms = {};
      fieldTermFrequencies[fieldRef] = fieldTerms;

      fieldLengths[fieldRef] = 0;

      // store the length of this field for this document
      fieldLengths[fieldRef] = fieldLengths[fieldRef]! + terms.length;

      // calculate term frequencies for this field
      for (Token? term in terms) {
        if (term == null) continue;
        if (fieldTerms[term] == null) {
          fieldTerms[term] = 0;
        }

        fieldTerms[term] = fieldTerms[term]! + 1;

        // add to inverted index
        // create an initial posting if one doesn't exist
        if (invertedIndex[term] == null) {
          Posting posting = Posting();
          posting.index = termIndex;
          termIndex += 1;

          for (String field in fields) {
            posting[field] = {};
          }

          invertedIndex[term] = posting;
        }

        // add an entry for this term/fieldName/docRef to the invertedIndex
        if (invertedIndex[term]![fieldName][docRef] == null) {
          invertedIndex[term]![fieldName][docRef] = {};
        }

        // store all whitelisted metadata about this token in the
        // inverted index
        for (String metadataKey in metadataWhitelist) {
          dynamic metadata = term.metadata![metadataKey];

          if (invertedIndex[term]![fieldName]?[docRef]?[metadataKey] == null) {
            invertedIndex[term]![fieldName][docRef][metadataKey] = [];
          }

          invertedIndex[term]![fieldName][docRef][metadataKey].add(metadata);
        }
      }
    }
  }

  /// Calculates the average document length for this index
  _calculateAverageFieldLengths() {
    Iterable<FieldRef> fieldRefs = fieldLengths.keys;
    Map<String, double> accumulator = {};
    Map<String, int> documentsWithField = {};

    for (FieldRef f in fieldRefs) {
      FieldRef fieldRef = FieldRef.fromString(f.toString());
      String field = fieldRef.fieldName;

      documentsWithField[field] ??= 0;
      documentsWithField[field] = documentsWithField[field]! + 1;

      accumulator[field] ??= 0;
      accumulator[field] = accumulator[field]! + fieldLengths[fieldRef]!;
    }
    var fields = _fields.keys;
    for (String fieldName in fields) {
      accumulator[fieldName] = accumulator.containsKey(fieldName)
          ? accumulator[fieldName]! / documentsWithField[fieldName]!
          : 0;
    }

    averageFieldLength = accumulator;
  }

  /// Builds a vector space model of every document using lunr.Vector
  _createFieldVectors() {
    Map<FieldRef, Vector> fieldVectors = {};
    Iterable<FieldRef> fieldRefs =
        fieldTermFrequencies.keys.map((e) => FieldRef.fromString(e.toString()));
    Map<Token, double> termIdfCache = {};
    for (FieldRef f in fieldRefs) {
      var fieldRef = FieldRef.fromString(f.toString()),
          fieldName = fieldRef.fieldName,
          fieldLength = fieldLengths[fieldRef],
          fieldVector = Vector(),
          termFrequencies = fieldTermFrequencies[fieldRef]!,
          terms = termFrequencies.keys;
      var fieldBoost = _fields[fieldName]!['boost'] ?? 1,
          docBoost = _documents[fieldRef.docRef]['boost'] ?? 1;

      for (Token term in terms) {
        int tf = termFrequencies[term]!;
        int termIndex = invertedIndex[term]!.index;
        double idf;
        double score, scoreWithPrecision;

        if (termIdfCache[term] == null) {
          idf = lunr.idf(invertedIndex[term]!, documentCount);
          termIdfCache[term] = idf;
        } else {
          idf = termIdfCache[term]!;
        }

        score = idf *
            ((_k1 + 1) * tf) /
            (_k1 *
                    (1 -
                        _b +
                        _b * (fieldLength! / averageFieldLength[fieldName]!)) +
                tf);
        score *= fieldBoost;

        score *= docBoost;
        scoreWithPrecision = (score * 1000).round() / 1000;
        // Converts 1.23456789 to 1.234.
        // Reducing the precision so that the vectors take up less
        // space when serialised. Doing it now so that they behave
        // the same before and after serialisation. Also, this is
        // the fastest approach to reducing a number's precision in
        // JavaScript.

        fieldVector.insert(termIndex, scoreWithPrecision);
      }

      fieldVectors[fieldRef] = fieldVector;
    }

    this.fieldVectors = fieldVectors;
  }

  /// Creates a token set of all tokens in the index using [TokenSet]
  _createTokenSet() {
    tokenSet = TokenSet.fromArray((invertedIndex.keys.toList())
      ..sort((a, b) => a.toString().compareTo(b.toString())));
  }

  /// Builds the index, creating an instance of [Index].
  ///
  /// This completes the indexing process and should only be called
  /// once all documents have been added to the index.
  Index build() {
    _calculateAverageFieldLengths();
    _createFieldVectors();
    _createTokenSet();

    return Index(
        invertedIndex: invertedIndex,
        fieldVectors: fieldVectors,
        tokenSet: tokenSet,
        fields: _fields.keys.toList(),
        pipeline: searchPipeline);
  }

  ///
  /// Applies a plugin to the index builder.
  ///
  /// A plugin is a function that is called with the index builder as its context.
  /// Plugins can be used to customise or extend the behaviour of the index
  /// in some way. A plugin is just a function, that encapsulated the custom
  /// behaviour that should be applied when building the index.
  ///
  /// The plugin function will be called with the index builder as its argument, additional
  /// arguments can also be passed when calling use. The function will be called
  /// with the index builder as its context.
  ///
  /// @param {Function} plugin The plugin to apply.
  ///
  // use(fn) {
  //   var args = Array.prototype.slice.call(arguments, 1)
  //   args.unshift(this)
  //   fn.apply(this, args)
  // }
}
