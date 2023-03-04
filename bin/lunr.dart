import 'package:lunr/lunr.dart';

void main(List<String> arguments) {
  var idx = lunr((builder) {
    builder.field('title');
    builder.field('body');

    builder.add({
      "title": "Twelfth-Night",
      "body": "If music be the food of love, play on: Give me excess of it…",
      "author": "William Shakespeare",
      "id": "1"
    });
  });

  print(idx.search("love"));
}
