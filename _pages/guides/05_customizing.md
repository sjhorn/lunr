---
layout: guides
permalink: /guides/customizing
---

### Customizing

![Lunr image](../assets/images/undraw_advanced_customization_re_wo6h.svg)

Lunr ships with sensible defaults that will produce good results for most use cases. Lunr also provides the ability to customise the index to provide extra features and allow more control over how documents are indexed and scored.

### Plugins

Any customisation, or extensions, can be packaged as a plugin. This makes it easier to share your customisations between indexes and other people, and provides a single, supported, way of customising Lunr.

### Pipeline Functions

The most commonly customised part of Lunr is the text processing pipeline. For example, if you wanted to support searching on either British or American spelling, you could add a pipeline function to normalise certain words. Let’s say we want to normalise the term “grey” so users can search by either British spelling “grey” or American spelling “gray”. To do this we can add a pipeline function to do the normalisation:

```dart
import 'package:lunr/lunr.dart';
//...

normaliseSpelling(builder) {

  // Define a pipeline function that converts 'gray' to 'grey'
  Token pipelineFunction(token) {
    if (token.toString() == 'gray') {
      return token.update(() => 'grey');
    } else {
      return token;
    }
  }

  // Register the pipeline function so the index can be serialised
  Pipeline.registerFunction(pipelineFunction, 'normaliseSpelling');

  // Add the pipeline function to both the indexing pipeline and the
  // searching pipeline
  builder.pipeline.before(stemmer, pipelineFunction);
  builder.searchPipeline.before(stemmer, pipelineFunction);
}
```

This can be applied before you create your index as follows:

```dart
var idx = lunr((builder) {
  normaliseSpelling(builder);
  //...
});
```
A pipeline is run on all fields in a document during indexing. Each token passed to the pipeline functions includes meta-data that indicates which field the token came from, this can be used to control which fields are processed by a particular pipeline function. The below example will skip stemming on tokens from the “name” field of a document.

```dart
Function skipField(fieldName, fn) {
  return (token, i, tokens) {
    if (token.metadata["fields"].contains(fieldName)) {
      return token;
    }
    return fn(token, i, tokens);
  }
}

// Create a stemmer that ignores tokens from the field "name"
Function selectiveStemmer = skipField('name', stemmer);
```

### Token Meta-data

Pipeline functions in Lunr are able to attach metadata to a token. An example of this is the token’s position data, i.e. the location of the token in the indexed document. By default, no metadata is stored in the index; this is to reduce the size of the index. It is possible to whitelist certain token metadata. Whitelisted meta-data will be returned with search results and it can also be used by other pipeline functions.

A Token has support for adding meta-data. For example, the following plugin will attach the length of a token as meta-data with key tokenLength. For it to be available in search results, this meta-data key is also added to the meta-data whitelist:

```dart
tokenLengthMetadata(builder) {
  // Define a pipeline function that stores the token length as metadata
  Token pipelineFunction(token, _, __) {
    token.metadata['tokenLength'] = token.toString().length;
    return token;
  }

  // Register the pipeline function so the index can be serialised
  Pipeline.registerFunction(pipelineFunction, 'tokenLenghtMetadata');

  // Add the pipeline function to the indexing pipeline
  builder.pipeline.before(stemmer, pipelineFunction);

  // Whitelist the tokenLength metadata key
  builder.metadataWhitelist.add('tokenLength');
}
```

As with all plugins, using it in an index is simple:

```dart
var idx = lunr((builder) {
  tokenLengthMetadata(builder);
  //...
});
```

### Similarity Tuning

The algorithm used by Lunr to calculate similarity between a query and a document can be tuned using two parameters. Lunr ships with sensible defaults, and these can be adjusted to provide the best results for a given collection of documents.

**b:** This parameter controls the importance given to the length of a document and its fields. This value must be between 0 and 1, and by default it has a value of 0.75. Reducing this value reduces the effect of different length documents on a term’s importance to that document.
**k1:** This controls how quickly the boost given by a common word reaches saturation. Increasing it will slow down the rate of saturation and lower values result in quicker saturation. The default value is 1.2. If the collection of documents being indexed have high occurrences of words that are not covered by a stop word filter, these words can quickly dominate any similarity calculation. In these cases, this value can be reduced to get more balanced results.
Both of these parameters can be adjusted when building the index:

```dart
Index idx = lunr((builder) {
  builder.k1 = 1.3;
  builder.b(0)
})
```

Next up is customizing to [add extra language support](languagesupport)