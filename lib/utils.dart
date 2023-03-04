import 'package:intl/intl.dart';

class Utils {
  static warn(message) => print(message);

  static asString(dynamic obj) {
    if (obj is DateTime) {
      // JS date format toString
      return DateFormat('EEE MMM dd yyyy HH:mm:ss').format(obj);
    }
    return obj?.toString() ?? '';
  }

  static Map<String, dynamic>? clone(Map<String, dynamic>? obj) {
    if (obj == null) {
      return obj;
    }

    Map<String, dynamic> clone = {};

    for (final entry in obj.entries) {
      String key = entry.key;
      var val = entry.value;

      if (val is List) {
        clone[key] = [...val];
        continue;
      }

      if (val is String || val is num || val is bool) {
        clone[key] = val;
        continue;
      }

      throw Exception("clone is not deep and does not support nested objects");
    }
    return clone;
  }
}
