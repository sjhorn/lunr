import 'package:collection/collection.dart';

typedef Metadata = Map<String, dynamic>;
typedef FieldMap = Map<String, Metadata>;
typedef TermMap = Map<String, FieldMap>;

/// Contains and collects metadata about a matching document.
/// A list of MatchData is returned as part of every
/// search.
class MatchData {
  /// A cloned collection of metadata associated with this document.
  TermMap metadata = {};

  ///  [term] - The term this match data is associated with
  ///  [field] - The field in which the term was found
  ///  [metadata] - The metadata recorded about this term in this field
  MatchData([String? term, String? field, Metadata? metadata]) {
    if (term == null || field == null) {
      return;
    }
    Metadata clonedMetadata = {};
    Iterable<String> metadataKeys = metadata?.keys ?? [];

    // Cloning the metadata to prevent the original
    // being mutated during match data combination.
    // Metadata is kept in an array within the inverted
    // index so cloning the data can be done with
    // List#sublist
    for (String key in metadataKeys) {
      clonedMetadata[key] = metadata![key]!.sublist(0);
    }

    this.metadata[term] = {};
    this.metadata[term]![field] = clonedMetadata;
  }

  @override
  String toString() {
    return 'MatchData(metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MatchData && other.hashCode == hashCode;
  }

  @override
  int get hashCode => DeepCollectionEquality().hash(metadata);

  /// An instance of MatchData will be created for every term that matches a
  /// document. However only one instance is required in a result. This
  /// method combines metadata from another instance of MatchData with this
  /// objects metadata.
  ///
  ///  [otherMatchData] - Another instance of match data to merge with this one.
  ///
  combine(MatchData otherMatchData) {
    Iterable<String> terms = otherMatchData.metadata.keys;

    for (String term in terms) {
      Iterable<String> fields = otherMatchData.metadata[term]!.keys;

      if (!metadata.containsKey(term)) {
        metadata[term] = {};
      }

      for (String field in fields) {
        Iterable<String> keys = otherMatchData.metadata[term]![field]!.keys;

        if (!metadata[term]!.containsKey(field)) {
          metadata[term]![field] = {};
        }

        for (String key in keys) {
          if (!metadata[term]![field]!.containsKey(key)) {
            metadata[term]![field]![key] =
                otherMatchData.metadata[term]![field]![key]!;
          } else {
            metadata[term]![field]![key] = [
              ...metadata[term]![field]![key]!,
              ...otherMatchData.metadata[term]![field]![key]!
            ];
          }
        }
      }
    }
  }

  /// Add metadata for a term/field pair to this instance of match data.
  ///
  ///  [term] - The term this match data is associated with
  ///  [field] - The field in which the term was found
  ///  [metadata] - The metadata recorded about this term in this field
  add(String term, String field, Metadata? metadata) {
    metadata ??= {};
    if (!(this.metadata.containsKey(term))) {
      this.metadata[term] = {};
      this.metadata[term]![field] = metadata;
      return;
    }

    if (!this.metadata[term]!.containsKey(field)) {
      this.metadata[term]![field] = metadata;
      return;
    }

    Iterable<String> metadataKeys = metadata.keys;

    for (String key in metadataKeys) {
      if (this.metadata[term]![field]!.containsKey(key)) {
        this.metadata[term]![field]![key] = [
          ...this.metadata[term]![field]![key]!,
          ...metadata[key]!
        ];
      } else {
        this.metadata[term]![field]![key] = metadata[key]!;
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'metadata': metadata,
    };
  }

  factory MatchData.fromJson(Map<String, dynamic> map) {
    var md = MatchData();
    md.metadata = map['metadata'].cast<FieldMap>();
    return md;
  }
}
