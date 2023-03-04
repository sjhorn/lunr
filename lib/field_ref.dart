class FieldRef {
  String docRef;
  String fieldName;
  late String? _stringValue;

  FieldRef(this.docRef, this.fieldName, [stringValue]) {
    _stringValue = stringValue;
  }

  static const joiner = '/';

  factory FieldRef.fromString(String s) {
    int n = s.indexOf(joiner);

    if (n == -1) {
      throw Exception("malformed field ref string");
    }

    String fieldRef = s.substring(0, n), docRef = s.substring(n + 1);

    return FieldRef(docRef, fieldRef, s);
  }

  @override
  String toString() {
    _stringValue ??= fieldName + joiner + docRef;
    return _stringValue!;
  }

  @override
  int get hashCode => toString().hashCode;

  @override
  bool operator ==(Object other) => toString() == other.toString();

  Map<String, dynamic> toJson() {
    return {'s': toString()};
  }

  factory FieldRef.fromJson(Map<String, dynamic> map) {
    return FieldRef.fromString(map['s']);
  }
}
