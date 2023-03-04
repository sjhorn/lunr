import 'dart:convert';

import 'package:lunr/lunr.dart';
import 'package:test/test.dart';
import 'assert.dart';

void main() {
  group('serialization', () {
    late List<Map<String, dynamic>> documents;
    late Index idx;
    late String serializedIdx;
    late Index loadedIdx;

    setUp(() {
      documents = [
        {
          'id': 'a',
          'title': 'Mr. Green kills Colonel Mustard',
          'body':
              'Mr. Green killed Colonel Mustard in the study with the candlestick. Mr. Green is not a very nice fellow.',
          'wordCount': 19
        },
        {
          'id': 'b',
          'title': 'Plumb waters plant',
          'body': 'Professor Plumb has a green plant in his study',
          'wordCount': 9
        },
        {
          'id': 'c',
          'title': 'Scarlett helps Professor',
          'body':
              'Miss Scarlett watered Professor Plumbs green plant while he was away from his office last week.',
          'wordCount': 16
        },
        {
          'id': 'd',
          'title': 'All about JavaScript',
          'body': 'JavaScript objects have a special __proto__ property',
          'wordCount': 7
        }
      ];

      idx = Lunr.lunr((builder) {
        builder.ref = 'id';
        builder.field('title');
        builder.field('body');

        for (var document in documents) {
          builder.add(document);
        }
      });
      serializedIdx = json.encode(idx);
      loadedIdx = Index.load(json.decode(serializedIdx));
    });

    test('search', () {
      List<DocMatch> idxResults = idx.search('green');
      List<DocMatch> serializedResults = loadedIdx.search('green');

      Assert.deepEqual(idxResults, serializedResults);
    });

    test('__proto__ double serialization', () {
      var doubleLoadedIdx = Index.load(json.decode(json.encode(loadedIdx))),
          idxResults = idx.search('__proto__'),
          doubleSerializedResults = doubleLoadedIdx.search('__proto__');

      Assert.deepEqual(idxResults, doubleSerializedResults);
    });
  });
}
