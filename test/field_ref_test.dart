import 'package:test/test.dart';
import 'package:lunr/field_ref.dart' as lunr;
import 'assert.dart';

void main() {
  suite('lunr.FieldRef', () {
    suite('#toString', () {
      test('combines document ref and field name', () {
        var fieldName = "title",
            documentRef = "123",
            fieldRef = lunr.FieldRef(documentRef, fieldName);

        Assert.equal(fieldRef.toString(), "title/123");
      });
    });

    suite('.fromString', () {
      test('splits string into parts', () {
        var fieldRef = lunr.FieldRef.fromString("title/123");

        Assert.equal(fieldRef.fieldName, "title");
        Assert.equal(fieldRef.docRef, "123");
      });

      test('docRef contains join character', () {
        var fieldRef = lunr.FieldRef.fromString("title/http://example.com/123");

        Assert.equal(fieldRef.fieldName, "title");
        Assert.equal(fieldRef.docRef, "http://example.com/123");
      });

      test('string does not contain join character', () {
        var s = "docRefOnly";

        Assert.throws(() {
          lunr.FieldRef.fromString(s);
        });
      });
    });
  });
}
