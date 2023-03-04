import 'dart:math';

import 'index.dart';

/// A function to calculate the inverse document frequency for
/// a posting. This is shared between the builder and the index
///
///
/// [posting] - The posting for a given term
/// [documentCount] - The total number of documents.
double idf(Posting posting, int documentCount) {
  int documentsWithTerm = 0;

  for (String fieldName in posting.keys) {
    if (fieldName == '_index') {
      continue; // Ignore the term index, its not a field
    }
    documentsWithTerm += (posting[fieldName]! as Map).keys.length;
  }

  double x =
      (documentCount - documentsWithTerm + 0.5) / (documentsWithTerm + 0.5);

  return log(1 + x.abs());
}
