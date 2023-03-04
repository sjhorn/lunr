import 'dart:convert';
import 'dart:math';

import 'package:test/test.dart';
import 'package:lunr/vector.dart' as lunr;

void main() {
  vectorFromArgs(List arguments) {
    var vector = lunr.Vector();
    arguments.asMap().forEach((i, el) {
      vector.insert(i, el);
    });
    return vector;
  }

  group('lunr.Vector', () {
    test('#magnitude calculates magnitude of vector', () async {
      var vector = vectorFromArgs([4, 5, 6]);
      expect(sqrt(77), vector.magnitude());
    });

    test('#dot calculates dot product of two vector', () async {
      var v1 = vectorFromArgs([1, 3, -5]), v2 = vectorFromArgs([4, -2, -1]);
      expect(3, v1.dot(v2));
    });

    test('#similarity calculates the similarity between two vectors', () async {
      var v1 = vectorFromArgs([1, 3, -5]), v2 = vectorFromArgs([4, -2, -1]);
      expect(v1.similarity(v2), closeTo(0.5, 0.01));
    });

    test('#similarity empty vector', () {
      var vEmpty = lunr.Vector(), v1 = vectorFromArgs([1]);

      expect(0, vEmpty.similarity(v1));
      expect(0, v1.similarity(vEmpty));
    });

    test('#similarity non-overlapping vector', () {
      var v1 = lunr.Vector([1, 1]);
      var v2 = lunr.Vector([2, 1]);

      expect(0, v1.similarity(v2));
      expect(0, v2.similarity(v1));
    });

    test('#insert invalidates magnitude cache', () {
      var vector = vectorFromArgs([4, 5, 6]);

      expect(sqrt(77), vector.magnitude());

      vector.insert(3, 7);

      expect(sqrt(126), vector.magnitude());
    });

    test('#insert keeps items in index specified order', () {
      var vector = lunr.Vector();

      vector.insert(2, 4);
      vector.insert(1, 5);
      vector.insert(0, 6);

      expect([6, 5, 4], containsAllInOrder(vector.toArray()));
    });

    test('#insert fails when duplicate entry', () {
      var vector = vectorFromArgs([4, 5, 6]);
      expect(() => vector.insert(0, 44), throwsA(isA<Exception>()));
    });

    test('#upsert invalidates magnitude cache', () {
      var vector = vectorFromArgs([4, 5, 6]);

      expect(sqrt(77), vector.magnitude());

      vector.upsert(3, 7);

      expect(sqrt(126), vector.magnitude());
    });

    test('#upsert keeps items in index specified order', () {
      var vector = lunr.Vector();

      vector.upsert(2, 4);
      vector.upsert(1, 5);
      vector.upsert(0, 6);
      expect([6, 5, 4], containsAllInOrder(vector.toArray()));
    });

    test('#upsert calls fn for value on duplicate', () {
      var vector = vectorFromArgs([4, 5, 6]);
      vector.upsert(0, 4, (current, passed) => current + passed);
      expect([8, 5, 6], containsAllInOrder(vector.toArray()));
    });

    test('#upsert throws if missing fn for value on duplicate', () {
      var vector = vectorFromArgs([4, 5, 6]);
      expect(() => vector.upsert(0, 4), throwsA(isA<Exception>()));
    });
  });
  group('lunr.Vector #positionForIndex', () {
    var vector = lunr.Vector([
      1,
      'a'.codeUnitAt(0),
      2,
      'b'.codeUnitAt(0),
      4,
      'c'.codeUnitAt(0),
      7,
      'd'.codeUnitAt(0),
      11,
      'e'.codeUnitAt(0)
    ]);
    test('at the beginning', () {
      expect(0, vector.positionForIndex(0));
    });

    test('at the end', () {
      expect(10, vector.positionForIndex(20));
    });

    test('consecutive', () {
      expect(4, vector.positionForIndex(3));
    });

    test('non-consecutive gap after', () {
      expect(6, vector.positionForIndex(5));
    });

    test('non-consecutive gap before', () {
      expect(6, vector.positionForIndex(6));
    });

    test('non-consecutive gave before and after', () {
      expect(8, vector.positionForIndex(9));
    });

    test('duplicate at the beginning', () {
      expect(0, vector.positionForIndex(1));
    });

    test('duplicate at the end', () {
      expect(8, vector.positionForIndex(11));
    });

    test('duplicate consecutive', () {
      expect(4, vector.positionForIndex(4));
    });
  });

  group('Json methods', () {
    var testJsonString = r'[1,2,3,4]';
    var testVector = lunr.Vector([1, 2, 3, 4]);

    test('toJson', () async {
      expect(json.encode(testVector.toJson()), equals(testJsonString));
    });

    test('fromJson', () async {
      var vector = lunr.Vector.fromJson(json.decode(testJsonString));
      expect(vector, equals(testVector));
      expect(vector.hashCode, equals(testVector.hashCode));
    });
  });
}
