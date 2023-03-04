class _CompleteSet extends Set {
  _CompleteSet();

  @override
  bool contains(object) => true;

  @override
  Set intersect(Set other) => other;

  @override
  Set union(Set other) => this;
}

class _EmptySet extends Set {
  _EmptySet();

  @override
  bool contains(object) => false;

  @override
  Set intersect(Set other) => this;

  @override
  Set union(Set other) => other;
}

class Set {
  Map<dynamic, bool> elements = {};
  int length = 0;

  Set([List<dynamic>? elements]) {
    if (elements != null) {
      length = elements.length;
      for (final el in elements) {
        this.elements[el] = true;
      }
    }
  }

  @override
  String toString() => elements.toString();

  static Set get complete => _CompleteSet();

  static Set get empty => _EmptySet();

  bool contains(dynamic object) => elements.containsKey(object);

  Set intersect(Set other) {
    Set a, b;
    List<dynamic> intersection = [];

    if (other is _CompleteSet) {
      return this;
    }

    if (other is _EmptySet) {
      return other;
    }

    if (length < other.length) {
      a = this;
      b = other;
    } else {
      a = other;
      b = this;
    }

    for (final el in a.elements.keys) {
      if (b.elements.containsKey(el)) {
        intersection.add(el);
      }
    }

    return Set(intersection);
  }

  Set union(Set other) {
    if (other is _CompleteSet) {
      return _CompleteSet();
    }

    if (other is _EmptySet) {
      return this;
    }

    return Set([...elements.keys, ...other.elements.keys]);
  }
}
