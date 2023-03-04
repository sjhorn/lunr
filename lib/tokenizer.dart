import 'package:lunr/token.dart';
import 'package:lunr/utils.dart';

final separator = RegExp(r'[\s\-]+');

typedef Tokenizer = List<Token> Function(
    [dynamic obj, Map<String, dynamic>? metadata]);

List<Token> tokenizer([dynamic obj, TokenMetaData? metadata]) {
  if (obj == null) {
    return [];
  }

  if (obj is List) {
    return obj.map((t) {
      return Token(Utils.asString(t).toLowerCase(), Utils.clone(metadata));
    }).toList();
  }
  // if (obj is Map) {
  //   return obj.entries.fold<List<Token>>(
  //       [],
  //       (accum, e) => accum
  //         ..addAll([
  //           Token(Utils.asString(e.key), Utils.clone(metadata)),
  //           Token(Utils.asString(e.value), Utils.clone(metadata))
  //         ]));
  // }

  String str = Utils.asString(obj).toLowerCase();
  int len = str.length;
  List<Token> tokens = [];

  for (var sliceEnd = 0, sliceStart = 0; sliceEnd <= len; sliceEnd++) {
    String char = sliceEnd < len ? str[sliceEnd] : '';
    int sliceLength = sliceEnd - sliceStart;

    if (separator.hasMatch(char) || sliceEnd == len) {
      if (sliceLength > 0) {
        TokenMetaData tokenMetadata = Utils.clone(metadata) ?? {};
        tokenMetadata["position"] = [sliceStart, sliceLength];
        tokenMetadata["index"] = tokens.length;

        tokens.add(Token(str.substring(sliceStart, sliceEnd), tokenMetadata));
      }

      sliceStart = sliceEnd + 1;
    }
  }

  return tokens;
}
