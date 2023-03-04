import 'package:lunr/pipeline.dart';

import 'builder.dart';
import 'index.dart';
import 'stemmer.dart';
import 'stop_word_filter.dart';
import 'trimmer.dart';

export 'builder.dart';
export 'field_ref.dart';
export 'idf.dart';
export 'index.dart';
export 'match_data.dart';
export 'pipeline.dart';
export 'query_lexer.dart';
export 'query_parse_error.dart';
export 'query.dart';
export 'set.dart';
export 'stemmer.dart';
export 'stop_word_filter.dart';
export 'token_set_builder.dart';
export 'token_set.dart';
export 'token.dart';
export 'tokenizer.dart';
export 'trimmer.dart';
export 'utils.dart';
export 'vector.dart';

typedef BuilderCallback = Function(Builder);

/// Wrapper for conveniance function, init and version
class Lunr {
  static const version = '2.3.9';
  static bool? initialised;

  static _init() {
    Pipeline.registerFunction(trimmer, 'trimmer');
    Pipeline.registerFunction(stopWordFilter, 'stopWordFilter');
    Pipeline.registerFunction(stemmer, 'stemmer');
    initialised = true;
  }

  /// A convenience function for configuring and constructing
  /// a new lunr Index.
  ///
  /// A Builder instance is created and the pipeline setup
  /// with a trimmer, stop word filter and stemmer.
  ///
  /// This builder object is yielded to the configuration function
  /// that is passed as a parameter, allowing the list of fields
  /// and other builder parameters to be customised.
  ///
  /// All documents _must_ be added within the passed config function.
  ///
  /// Example
  /// ```dart
  ///   var idx = lunr((builder) {
  ///   builder.field('title');
  ///   builder.field('body');
  ///   builder.ref('id');
  ///
  ///   for(var doc in documents) {
  ///     builder.add(doc);
  ///   }
  /// });
  /// ```
  /// see  [Builder]
  /// see  [Pipeline]
  /// see  [trimmer]
  /// see  [stopWordFilter]
  /// see  [stemmer]
  ///
  static Index lunr(BuilderCallback callback) {
    initialised ?? _init();
    Builder builder = Builder();
    builder.pipeline.add([trimmer, stopWordFilter, stemmer]);

    builder.searchPipeline.add([stemmer]);
    callback(builder);
    return builder.build();
  }
}

/// A convenience function for configuring and constructing
/// a new lunr Index.
///
/// A Builder instance is created and the pipeline setup
/// with a trimmer, stop word filter and stemmer.
///
/// This builder object is yielded to the configuration function
/// that is passed as a parameter, allowing the list of fields
/// and other builder parameters to be customised.
///
/// All documents _must_ be added within the passed config function.
///
/// Example
/// ```dart
///   var idx = lunr((builder) {
///   builder.field('title');
///   builder.field('body');
///   builder.ref('id');
///
///   for(var doc in documents) {
///     builder.add(doc);
///   }
/// });
/// ```
/// see  [Builder]
/// see  [Pipeline]
/// see  [trimmer]
/// see  [stopWordFilter]
/// see  [stemmer]
///
Index Function(BuilderCallback) lunr = Lunr.lunr;
