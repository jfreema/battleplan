/// Reads that leave out a record the app can't read (a field of the wrong
/// type) and say so, so one damaged event or document never hides the rest
/// of a list (#40, as the chat has always done for its messages).
///
/// Each one is told to [BadRecords]'s reporter, the crash log, once per app
/// run, by its kind and id, never its contents ("Unreadable event abc123:
/// …"): a live list reads the same bad record every time anything in it
/// changes. One instance serves every repository, from `app/providers.dart`.
library;

class BadRecords {
  /// [report] hears each unreadable record once; null in tests that don't
  /// listen.
  new([this.report]);

  final void Function(Object error, StackTrace stack)? report;

  final Set<String> _told = {};

  /// [read]'s record, or null when it throws, told once.
  T? read<T>(String kind, String id, T Function() read) {
    try {
      return read();
    } on Object catch (e, stack) {
      _tell(kind, id, e, stack);
      return null;
    }
  }

  /// [read]'s record for a page about that one record (an event's, a
  /// document's): told once, and then the error goes on, so the page says
  /// it couldn't load, with Try again.
  T readOne<T>(String kind, String id, T Function() read) {
    try {
      return read();
    } on Object catch (e, stack) {
      _tell(kind, id, e, stack);
      rethrow;
    }
  }

  void _tell(String kind, String id, Object error, StackTrace stack) {
    if (_told.add('$kind/$id')) {
      report?.call(StateError('Unreadable $kind $id: $error'), stack);
    }
  }
}
