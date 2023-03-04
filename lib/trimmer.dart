import 'package:lunr/token.dart';

export 'package:lunr/token.dart';

Token? trimmer(Token? token, int i, List<Token?> tokens) {
  if (token == null) {
    return token;
  }
  return token.update((String s, TokenMetaData? _) {
    return s.replaceAll(RegExp(r'^\W+'), '').replaceAll(RegExp(r'\W+$'), '');
  });
}
