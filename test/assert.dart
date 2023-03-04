import 'package:lunr/index.dart';
import 'package:lunr/token.dart';
import 'package:test/test.dart';

void suite(dynamic description, dynamic Function() body) =>
    group(description, body);

void setup(dynamic Function() callback) => setUp(callback);
void teardown(dynamic Function() callback) => tearDown(callback);

class Assert {
  static equal(dynamic a, dynamic b) => expect(a, equals(b));
  static sameMembers(dynamic a, dynamic b) => expect(a, containsAll(b));
  static ok(bool? a) => expect(a, equals(true));
  static notOk(bool? a) => expect(a, equals(false));
  static lengthOf(dynamic a, int b) => expect(a, hasLength(b));
  static isUndefined(dynamic a) => expect(a, equals(null));
  static throws(dynamic a) => expect(a, throwsA(isA<Exception>()));
  static void deepEqual(dynamic a, dynamic b) {
    if (b is Iterable) {
      expect(a, containsAll(b));
    } else if (a is Map && b is Map) {
      expect(a.keys, containsAll(b.keys));
      expect(a.values, containsAll(b.values));
    } else {
      expect(a, equals(b));
    }
  }

  static property(dynamic obj, dynamic property) =>
      expect(obj.containsKey(property), equals(true));
  static instanceOf<T>(dynamic obj) => expect(obj, isA<T>());

  static bool deepProperty(InvertedIndex index, String propertyPath) {
    List<String> properties = propertyPath.split('.');

    dynamic level = index[Token(properties[0])]!;

    for (String property in properties.sublist(1)) {
      if (!level.containsKey(property)) {
        return false;
      }
      level = level[property];
    }
    return true;
  }

  static notProperty(dynamic obj, dynamic property) =>
      expect(property, isNot(isIn(obj)));

  static include(List array, dynamic s) => expect(s, isIn(array));
}
