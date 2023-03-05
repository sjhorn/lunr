---
layout: guides
permalink: /guides/started
---

### Getting Started

![Lunr image](../assets/images/undraw_in_real_life_v8fk.svg)

First we will walk you through setting up your first search index with Lunr. It assumes you have some familiarity with JavaScript. After finishing this guide you will have a script that will be able to perform a search on a collection of documents.


### Installation

Install Lunr with pub.dev

Dart:
```sh
dart pub add lunr
```

Flutter:
```sh
flutter pub add lunr
```

### Creating and index

We will create a simple index on a collection of documents and then perform searches on those documents.

First, we need a collection of documents. A document is a `Map<String, String>` object. It should have an identifier field that Lunr will use to tell us which documents in the collection matched a search, as well as any other fields that we want to search on.

```dart
List<Map<String,String>> documents = [{
  "name": "Lunr",
  "text": "Like Solr, but much smaller, and not as bright."
}, {
  "name": "React",
  "text": "A JavaScript library for building user interfaces."
}, {
  "name": "Lodash",
  "text": "A modern JavaScript utility library delivering "
}];
```
We will use the above list of documents to build our index. We want to search the text field, and the name field will be our identifier. Let’s define our index and add these documents to it.

After that we will do a simple search and print the results.

```dart
import 'package:lunr/lunr.dart';

void main() {
    List<Map<String,String>> documents = [{
    "name": "Lunr",
    "text": "Like Solr, but much smaller, and not as bright."
    }, {
    "name": "React",
    "text": "A JavaScript library for building user interfaces."
    }, {
    "name": "Lodash",
    "text": "A modern JavaScript utility library delivering "
    }];
    
    // Create the index
    Index idx = lunr((builder) {
        builder.ref = 'name';
        builder.field('text');
        for (var doc in documents) {
            builder.add(doc);
        }
    });

    // Search the index for text bright
    print(idx.search('bright'));
}
```

The results output will look similar to the following:

```
[DocMatch(ref: Lunr, score: 1.042, matchData: 
    MatchData(metadata: {bright: {text: {}}}))]
```

### Conclusion

The above example shows how to quickly get full text search with Lunr. From here you can learn more about the [core concepts](core) involved in a Lunr index, explore the [advanced search](advanced) capability provided by Lunr and see [how to customise Lunr](customise) to provide a great search experience.