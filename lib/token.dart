import 'match_data.dart';

typedef TokenMetaData = Metadata; // Map<String, List>;
typedef TokenUpdateFn = String Function(String, TokenMetaData? metadata);

class Token {
  String str;
  TokenMetaData? metadata;

  Token(this.str, [TokenMetaData? metadata]) {
    this.metadata = metadata ?? {};
  }

  @override
  String toString() => str;

  Token update(TokenUpdateFn fn) {
    str = fn(str, metadata);
    return this;
  }

  Token clone([TokenUpdateFn? fn]) {
    fn = fn ?? (s, _) => s;
    return Token(fn(str, metadata), metadata);
  }

  @override
  int get hashCode => str.hashCode;

  @override
  bool operator ==(Object other) => other.toString() == str;
}
