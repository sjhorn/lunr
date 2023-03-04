//
// lunr.stemmer is an english language stemmer, this is a dart
// implementation of the PorterStemmer taken from http://tartarus.org/~martin
//

// ignore_for_file: non_constant_identifier_names

import 'token.dart';

Map<String, String> step2list = {
  "ational": "ate",
  "tional": "tion",
  "enci": "ence",
  "anci": "ance",
  "izer": "ize",
  "bli": "ble",
  "alli": "al",
  "entli": "ent",
  "eli": "e",
  "ousli": "ous",
  "ization": "ize",
  "ation": "ate",
  "ator": "ate",
  "alism": "al",
  "iveness": "ive",
  "fulness": "ful",
  "ousness": "ous",
  "aliti": "al",
  "iviti": "ive",
  "biliti": "ble",
  "logi": "log"
};

Map<String, String> step3list = {
  "icate": "ic",
  "ative": "",
  "alize": "al",
  "iciti": "ic",
  "ical": "ic",
  "ful": "",
  "ness": ""
};

String c = '[^aeiou]'; // consonant
String v = '[aeiouy]'; // vowel
String C = '$c[^aeiouy]*'; // consonant sequence
String V = '$v[aeiou]*'; // vowel sequence

String mgr0 = '^($C)?$V$C'; // [C]VC... is m>0
String meq1 = '^($C)?$V$C($V)?\$'; // [C]VC[V] is m=1
String mgr1 = '^($C)?$V$C$V$C'; // [C]VCVC... is m>1
String s_v = '^($C)?$v'; // vowel in stem

RegExp re_mgr0 = RegExp(mgr0);
RegExp re_mgr1 = RegExp(mgr1);
RegExp re_meq1 = RegExp(meq1);
RegExp re_s_v = RegExp(s_v);

var re_1a = RegExp(r'^(.+?)(ss|i)es$');
var re2_1a = RegExp(r'^(.+?)([^s])s$');
var re_1b = RegExp(r'^(.+?)eed$');
var re2_1b = RegExp(r'^(.+?)(ed|ing)$');
var re_1b_2 = RegExp(r'.$');
var re2_1b_2 = RegExp(r'(at|bl|iz)$');
var re3_1b_2 = RegExp(r'([^aeiouylsz])\1$');
var re4_1b_2 = RegExp('^$C$v[^aeiouwxy]\$');

var re_1c = RegExp(r'^(.+?[^aeiou])y$');
var re_2 = RegExp(
    r'^(.+?)(ational|tional|enci|anci|izer|bli|alli|entli|eli|ousli|ization|ation|ator|alism|iveness|fulness|ousness|aliti|iviti|biliti|logi)$');
var re_3 = RegExp(r'^(.+?)(icate|ative|alize|iciti|ical|ful|ness)$');
var re_4 = RegExp(
    r'^(.+?)(al|ance|ence|er|ic|able|ible|ant|ement|ment|ent|ou|ism|ate|iti|ous|ive|ize)$');
var re2_4 = RegExp(r'^(.+?)(s|t)(ion)$');
var re_5 = RegExp(r'^(.+?)e$');
var re_5_1 = RegExp(r'll$');
var re3_5 = RegExp('^$C$v[^aeiouwxy]\$');

TokenUpdateFn _porterStemmer = (w, metadata) {
  String stem;
  String suffix;
  String firstch;
  RegExp re;
  RegExp re2;
  RegExp re3;
  RegExp re4;

  if (w.length < 3) {
    return w;
  }

  firstch = w.substring(0, 1);
  if (firstch == "y") {
    w = firstch.toUpperCase() + w.substring(1);
  }

  // Step 1a
  re = re_1a;
  re2 = re2_1a;

  if (re.hasMatch(w)) {
    w = w.replaceAllMapped(re, (m) => '${m.group(1)}${m.group(2)}');
  } else if (re2.hasMatch(w)) {
    w = w.replaceAllMapped(re2, (m) => '${m.group(1)}${m.group(2)}');
  }

  // Step 1b
  re = re_1b;
  re2 = re2_1b;
  if (re.hasMatch(w)) {
    var fp = re.firstMatch(w);
    re = re_mgr0;
    if (re.hasMatch(fp!.group(1)!)) {
      re = re_1b_2;
      w = w.replaceAll(re, "");
    }
  } else if (re2.hasMatch(w)) {
    var fp = re2.firstMatch(w);
    stem = fp!.group(1)!;
    re2 = re_s_v;
    if (re2.hasMatch(stem)) {
      w = stem;
      re2 = re2_1b_2;
      re3 = re3_1b_2;
      re4 = re4_1b_2;
      if (re2.hasMatch(w)) {
        w = "${w}e";
      } else if (re3.hasMatch(w)) {
        re = re_1b_2;

        w = w.replaceAll(re, "");
      } else if (re4.hasMatch(w)) {
        w = "${w}e";
      }
    }
  }

  // Step 1c - replace suffix y or Y by i if preceded by a non-vowel which is not the first letter of the word (so cry -> cri, by -> by, say -> say)
  re = re_1c;
  if (re.hasMatch(w)) {
    var fp = re.firstMatch(w);
    stem = fp!.group(1)!;
    w = "${stem}i";
  }

  // Step 2
  re = re_2;
  if (re.hasMatch(w)) {
    var fp = re.firstMatch(w);
    stem = fp!.group(1)!;
    suffix = fp.group(2)!;
    re = re_mgr0;
    if (re.hasMatch(stem)) {
      w = stem + step2list[suffix]!;
    }
  }

  // Step 3
  re = re_3;
  if (re.hasMatch(w)) {
    var fp = re.firstMatch(w);
    stem = fp!.group(1)!;
    suffix = fp.group(2)!;
    re = re_mgr0;
    if (re.hasMatch(stem)) {
      w = stem + step3list[suffix]!;
    }
  }

  // Step 4
  re = re_4;
  re2 = re2_4;
  if (re.hasMatch(w)) {
    var fp = re.firstMatch(w);
    stem = fp!.group(1)!;
    re = re_mgr1;
    if (re.hasMatch(stem)) {
      w = stem;
    }
  } else if (re2.hasMatch(w)) {
    var fp = re2.firstMatch(w);
    stem = fp!.group(1)! + fp.group(2)!;
    re2 = re_mgr1;
    if (re2.hasMatch(stem)) {
      w = stem;
    }
  }

  // Step 5
  re = re_5;
  if (re.hasMatch(w)) {
    var fp = re.firstMatch(w);
    stem = fp!.group(1)!;
    re = re_mgr1;
    re2 = re_meq1;
    re3 = re3_5;
    if (re.hasMatch(stem) || (re2.hasMatch(stem) && !(re3.hasMatch(stem)))) {
      w = stem;
    }
  }

  re = re_5_1;
  re2 = re_mgr1;
  if (re.hasMatch(w) && re2.hasMatch(w)) {
    re = re_1b_2;
    w = w.replaceAll(re, "");
  }

  // and turn initial Y back to y

  if (firstch == "y") {
    w = firstch.toLowerCase() + w.substring(1);
  }

  return w;
};

Token? stemmer(Token? token, int i, List<Token?> tokens) {
  if (token == null) return token;
  return token.update(_porterStemmer);
}

//lunr.Pipeline.registerFunction(lunr.stemmer, 'stemmer')
