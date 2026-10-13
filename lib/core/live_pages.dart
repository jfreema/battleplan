import 'dart:async';

/// One page of a live list: its items, and the cursor to start the next
/// page after, or null when this is the last page.
typedef LivePage<T, C> = ({List<T> items, C? next});

/// A whole list read live a page at a time (queries are capped at 100,
/// ARCH §10.2), for lists that can be longer: a big team's roster, players,
/// and player links (TEAM-3, PLAYER-2, PLAYER-6).
///
/// [watchPage] watches the page after a cursor (null for the first). Every
/// page stays live. When a page's end moves (someone added or removed), the
/// pages after it start over from the new end. The list is emitted once
/// every open page has arrived, in page order.
Stream<List<T>> livePages<T, C extends Object>(
  Stream<LivePage<T, C>> Function(C? after) watchPage,
) {
  final out = StreamController<List<T>>();
  final subs = <StreamSubscription<LivePage<T, C>>>[];
  final pages = <List<T>>[];
  final nexts = <C?>[];

  void dropAfter(int i) {
    for (final s in subs.sublist(i + 1)) {
      unawaited(s.cancel());
    }
    subs.removeRange(i + 1, subs.length);
    if (pages.length > i + 1) pages.removeRange(i + 1, pages.length);
    if (nexts.length > i + 1) nexts.removeRange(i + 1, nexts.length);
  }

  void open(int i, C? after) {
    subs.add(
      watchPage(after).listen((page) {
        final first = pages.length <= i;
        final moved = first || nexts[i] != page.next;
        if (first) {
          pages.add(page.items);
          nexts.add(page.next);
        } else {
          pages[i] = page.items;
          nexts[i] = page.next;
        }
        if (moved) {
          dropAfter(i);
          final next = page.next;
          if (next != null) {
            open(i + 1, next);
            return;
          }
        }
        if (pages.length == subs.length) {
          out.add([for (final p in pages) ...p]);
        }
      }, onError: out.addError),
    );
  }

  out
    ..onListen = () {
      open(0, null);
    }
    ..onCancel = () async {
      for (final s in subs) {
        await s.cancel();
      }
    };
  return out.stream;
}
