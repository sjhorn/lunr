---
layout: guides
permalink: /guides/core
---

### Core Concepts

![Lunr image](../assets/images/undraw_web_search_re_efla.svg)

Creating a basic search index with Lunr is simple. Understanding some of the concepts and terminology that Lunr uses will allow you to provide powerful search functionality.

### Documents

A document contains the text that you want to be able to search. A document is a `Map<String,String>` object with one or more fields and an identifier that is returned in the results from a search. A document representing a blog post might look like this in json:

```javascript
{
  "id": "http://my.blog/post",
  "title": "Title",
  "body": "Contents of the blog post"
}
```

In this document there are two fields that could be searched on, title and body, as well as an id field that can be used as an identifier. Typically, fields are strings, or they can be anything that responds to toString. Arrays can also be used, in which case the result of calling toString on each element will be available for search.

The documents that are passed to Lunr for indexing do not have to be in the same structure as the data in your application or site. For example, to provide a search on email addresses the email addresses could be split into domain and local parts:

```javascript
{
  "id": "Bob",
  "emailDomain": "example.com",
  "emailLocal": "bob.bobson"
}
```

### Text Processing 

Before Lunr can start building an index, it must first process the text in the document fields. The first step in this process is splitting a string into words; Lunr calls these tokens. A string such as “foo bar baz” will be split into three separate tokens: “foo”, “bar” and “baz”.

Once the text of a field has been split into tokens, each token is passed through a text processing pipeline. A pipeline is a combination of one or more functions that either modify the token, or extract and store meta-data about the token. The default pipeline in Lunr provides functions for trimming any punctuation, ignoring stop words and reducing a word to its stem.

The pipeline used by Lunr can be modified by either removing, rearranging or adding custom processors to the pipeline. A custom pipeline function can either prevent a token from entering the index (like the stop word filter), or modify a token (as with stemming). A token can also be expanded, which is useful for adding synonyms to an index. An example pipeline function that splits email addresses into a local and domain part is below:

```dart
Function emailFilter(token) {
  return token.toString().split("@").map((str) {
    return token.clone().update(() => str );
  });
}
```

### Stemming

Stemming is the process of reducing inflected or derived words to their base or stem form. For example, the stem of “searching”, “searched” and “searchable” should be “search”. This has two benefits: firstly the number of tokens in the search index, and therefore its size, is significantly reduced, and in addition, it increases the recall when performing a search. A document containing the word “searching” is likely to be relevant to a query for “search”.

There are two ways in which stemming can be achieved: dictionary-based or algorithm-based. In dictionary based stemming, a dictionary that maps all words to their stems is used. This approach can give good results but requires a complete dictionary, which must be maintained and large in size. A more pragmatic approach is an algorithmic stemming, such as a [Porter Stemmer](https://tartarus.org/martin/PorterStemmer/), which is used in Lunr.

The stemmer used by Lunr does not guarantee that the stem of a word it finds is an actual word, but all inflections and derivatives of that word should produce the same stem.

### Search Results

The result of a search contains an array of result objects representing each document that was matched by a search. Each result has three properties:

|**ref:**|the document reference.|
|**score:**|a relative measure of how similar this document is to the query. For information on how the score is calculated, see the page on searching.|
|**metadata:**|any metadata associated with query tokens found in this document.|

The metadata contains a key for each search term found in the document and the field in which it was found. This will contain all the metadata about this term and field; for example the position of the term matches:

```javascript
{
  "ref": "123",
  "score": 0.123456,
  "metadata": {
    "test": {
      "body": {
        "position": [[0, 4], [24, 4]]
      }
    }
  }
}
```

Storing metadata about the term and field is opt-in, this is to keep the size of the search index as small as possible. To enable positions of term matches the ‘positions’ metadata must be white-listed when building the index:

```dart
Index idx = lunr((builder) {
  builder.ref = 'id';
  builder.field('body');
  builder.metadataWhitelist = ['position'];
  for (var doc in documents) {
    builder.add(doc);
  }
});
```

Next we are going to look further into [searching](searching)