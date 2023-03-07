# Lunr 


A bit like Solr, but much smaller and not as bright (based on [lunrjs](https://github.com/olivernn/lunr.js))

## Example

A very simple search index can be created using the following:

```dart
var idx = lunr((builder) {
  builder.field('title');
  builder.field('body');

  builder.add({
    "title": "Twelfth-Night",
    "body": "If music be the food of love, play on: Give me excess of it…",
    "author": "William Shakespeare",
    "id": "1"
  });
});
```

Then searching is as simple as:

```dart
idx.search("love");
```

This returns a list of matching documents with a score of how closely they match the search query as well as any associated metadata about the match:

```javascript
[
  {
    "ref": "1",
    "score": 0.3535533905932737,
    "matchData": {
      "metadata": {
        "love": {
          "body": {}
        }
      }
    }
  }
]
```


## Description

Lunr is a small, full-text search library for use in the browser.  It indexes JSON documents and provides a simple search interface for retrieving documents that best match text queries.

## Why

For web applications with all their data already sitting in the client, it makes sense to be able to search that data on the client too.  It saves adding extra, compacted services on the server.  A local search index will be quicker, there is no network overhead, and will remain available and usable even without a network connection.

## Installation

Simply add the lunr package to your code.

With Dart:

```sh
dart pub add lunr
```

With Flutter:

```sh
flutter pub add lunr
```


## Features

* Full text search support (14 languages support from lunrjs coming soon).
* Boost terms at query time or boost entire documents at index time
* Scope searches to specific fields
* Fuzzy term matching with wildcards or edit distance

## Demo

[Try out the demo](https://lunr_demo.hornmicro.com)

and see the [Associated Source code](https://github.com/sjhorn/lunr_demo)

## Contributing

See the [`CONTRIBUTING.md` file](CONTRIBUTING.md).