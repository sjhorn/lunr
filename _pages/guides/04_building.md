---
layout: guides
permalink: /guides/building
---

### Building Lunr Indexes

![Lunr image](../assets/images/undraw_building_blocks_re_5ahy.svg)

For large numbers of documents, it can take time for Lunr to build an index. The time taken to build the index can lead a browser to block; making your site seem unresponsive.

A better way is to pre-build the index, and serve a serialised index that Lunr can load on the client side much quicker.

This technique is useful with large indexes, or with documents that are largely static, such as with a static website.

### Serialization

Lunr indexes support serialisation in JSON. Assuming that the index has already been created, it be serialised using the built-in JSON object:

```dart
import 'dart:convert';

//...

String serializedIdx = json.encode(idx);

```

This serialized index can then be written to a file, compressed, and served along side other static assets.

Assuming the following `sample.json`:

```javascript
[{ "id": "1", "title": "Foo", "body": "Bar" }]
```

This can converted to a saved index in json `index.json` as follows:

```dart
import 'dart:io';
import 'package:lunr/lunr.dart';

void main() {
  dynamic json = json.decode(File('sample.json').readAsStringSync());

  Index idx = lunr((builder) {
    builder.ref = 'id';
    builder.field('title');
    builder.field('body');

    for(dynamic doc in json) {
      builder.add(doc);
    }
  })

  File('index.json').writeAsStringSync(json.encode(idx));
}
```

### Loading

Loading a serialised index is significantly quicker than building the index from scratch. Assuming a variable named data contains the serialised index, loading the index is done like this:

```dart
import 'dart:io';
import 'package:lunr/lunr.dart';

void main() {
  dynamic json = json.decode(File('index.json').readAsStringSync());

  var idx = Index.load(json);
}
```

Now we have shown how to save and reload an index, lets move to [customizing our index](customizing)

