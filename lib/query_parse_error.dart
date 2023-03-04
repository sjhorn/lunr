class QueryParseError extends Error {
  String message;
  int start;
  int end;

  QueryParseError(
    this.message,
    this.start,
    this.end,
  );
}
