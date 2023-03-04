import 'dart:math';

typedef UpsertFn = num Function(num, num);

class Vector {
  double _magnitude = 0;
  late List<num> elements;

  Vector([List<num>? elements]) {
    this.elements = elements ?? [];
  }

  insert(insertIdx, val) {
    upsert(insertIdx, val, (_, __) {
      throw Exception("duplicate index");
    });
  }

  upsert(insertIdx, val, [UpsertFn? fn]) {
    _magnitude = 0;
    int position = positionForIndex(insertIdx);

    if (elements.length > position && elements[position] == insertIdx) {
      if (fn == null) {
        throw Exception('fn required for this scenario');
      }
      elements[position + 1] = fn(elements[position + 1], val);
    } else {
      //elements.splice(position, 0, insertIdx, val);
      elements.insertAll(position, [insertIdx, val]);
    }
  }

  int positionForIndex(index) {
    // For an empty vector the tuple can be inserted at the beginning
    if (elements.isEmpty) {
      return 0;
    }

    var start = 0,
        end = elements.length ~/ 2,
        sliceLength = end - start,
        pivotPoint = (sliceLength ~/ 2).floor(), //Math.floor(sliceLength / 2),
        pivotIndex = elements[pivotPoint * 2];

    while (sliceLength > 1) {
      if (pivotIndex < index) {
        start = pivotPoint;
      }

      if (pivotIndex > index) {
        end = pivotPoint;
      }

      if (pivotIndex == index) {
        break;
      }

      sliceLength = end - start;
      pivotPoint =
          start + (sliceLength ~/ 2).floor(); //Math.floor(sliceLength / 2);
      pivotIndex = elements[pivotPoint * 2];
    }

    if (pivotIndex == index) {
      return pivotPoint * 2;
    }

    if (pivotIndex > index) {
      return pivotPoint * 2;
    }

    if (pivotIndex < index) {
      return (pivotPoint + 1) * 2;
    }
    return 0;
  }

  double magnitude() {
    if (_magnitude > 0) return _magnitude;

    double sumOfSquares = 0;
    int elementsLength = elements.length;

    for (var i = 1; i < elementsLength; i += 2) {
      var val = elements[i];
      sumOfSquares += val * val;
    }

    return _magnitude = sqrt(sumOfSquares);
  }

  double dot(Vector otherVector) {
    var a = elements,
        b = otherVector.elements,
        aLen = a.length,
        bLen = b.length,
        i = 0,
        j = 0;
    num aVal = 0, dotProduct = 0, bVal = 0;

    while (i < aLen && j < bLen) {
      aVal = a[i];
      bVal = b[j];
      if (aVal < bVal) {
        i += 2;
      } else if (aVal > bVal) {
        j += 2;
      } else if (aVal == bVal) {
        dotProduct += a[i + 1] * b[j + 1];
        i += 2;
        j += 2;
      }
    }

    return dotProduct.toDouble();
  }

  double similarity(otherVector) =>
      magnitude() != 0 ? dot(otherVector) / magnitude() : 0;

  List<num> toArray() => elements.asMap().entries.fold([],
      (accum, entry) => (entry.key.isOdd) ? (accum..add(entry.value)) : accum);

  List<num> toJson() {
    // Match javascript style of making numbers ints if they are 1.0, 2.00 etc.
    return elements.map((e) => (e % 1) == 0 ? e.round() : e).toList();
  }

  factory Vector.fromJson(dynamic list) {
    return Vector(list.cast<num>());
  }

  @override
  bool operator ==(Object other) {
    if (other is! Vector) return false;
    if (elements.length != other.elements.length) return false;
    for (int i = 0; i < elements.length; i++) {
      if (elements[i] != other.elements[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => elements.fold(17, (accum, e) => accum += e.hashCode);
}
