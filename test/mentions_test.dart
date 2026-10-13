// @mentions in the chat (SPEC CHAT-14): finding the @ being typed, who to
// suggest, whom a sent message names, and where to highlight them.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/features/chat/domain/mentions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sam = (uid: 'sam', name: 'Sam Rivera');
  const mary = (uid: 'mary', name: 'Mary Ann');
  const maryLee = (uid: 'maryl', name: 'Mary Ann Lee');
  const alex = (uid: 'alex', name: 'Alex Kim');
  const team = <MentionCandidate>[sam, mary, maryLee, alex];

  group('mentionQueryAt', () {
    test('finds the @ word being typed at the cursor', () {
      expect(mentionQueryAt('Hi @sa', 6), (start: 3, query: 'sa'));
      expect(mentionQueryAt('@', 1), (start: 0, query: ''));
      expect(mentionQueryAt('(@Mary An', 9), (start: 1, query: 'Mary An'));
      // The cursor can be in the middle of the text.
      expect(mentionQueryAt('@sam is here', 4), (start: 0, query: 'sam'));
    });

    test('not in an email address, past a line, or after a space', () {
      expect(mentionQueryAt('sam@example.com', 15), isNull);
      expect(mentionQueryAt('Hi @sam\nthere', 13), isNull);
      expect(mentionQueryAt('@ sam', 5), isNull);
      expect(mentionQueryAt('no at here', 5), isNull);
      expect(mentionQueryAt('@sa', 9), isNull);
    });
  });

  group('mentionSuggestions', () {
    test('names starting with it first, then a later word, by name', () {
      expect(mentionSuggestions('ma', team), [mary, maryLee]);
      expect(mentionSuggestions('ki', team), [alex]);
      expect(mentionSuggestions('', team), [alex, mary, maryLee, sam]);
      expect(mentionSuggestions('SAM', team), [sam]);
    });

    test('a query with a space matches whole names only', () {
      expect(mentionSuggestions('Mary Ann L', team), [maryLee]);
      expect(mentionSuggestions('Sam is', team), isEmpty);
    });

    test('@everyone only when allowed, and at most five', () {
      expect(mentionSuggestions('ev', team), isEmpty);
      expect(mentionSuggestions('ev', team, everyone: true), [
        everyoneCandidate,
      ]);
      final many = [
        for (var i = 0; i < 9; i++) (uid: 'u$i', name: 'Player $i'),
      ];
      expect(mentionSuggestions('pl', many), hasLength(mentionSuggestionsMax));
    });
  });

  test('completing a name leaves a space after it', () {
    expect(mentionText(mary), '@Mary Ann ');
    expect(mentionText(everyoneCandidate), '@everyone ');
  });

  group('mentionsIn', () {
    test('names people by their full names, ignoring case', () {
      final named = mentionsIn(
        '@sam rivera and @Alex Kim, bring the balls',
        team,
        canMentionEveryone: false,
      );
      expect(named.uids, ['sam', 'alex']);
      expect(named.everyone, isFalse);
    });

    test('the longest name wins', () {
      expect(
        mentionsIn(
          '@Mary Ann Lee is driving',
          team,
          canMentionEveryone: false,
        ).uids,
        ['maryl'],
      );
      expect(
        mentionsIn(
          '@Mary Ann is driving',
          team,
          canMentionEveryone: false,
        ).uids,
        ['mary'],
      );
    });

    test('punctuation ends a name; letters and email addresses do not', () {
      expect(
        mentionsIn(
          "Thanks @Sam Rivera. And @Sam Rivera's mom!",
          team,
          canMentionEveryone: false,
        ).uids,
        ['sam'],
      );
      expect(
        mentionsIn('@Sam Riveras', team, canMentionEveryone: false).uids,
        isEmpty,
      );
      expect(
        mentionsIn(
          'write to coach@Sam Rivera.com',
          team,
          canMentionEveryone: false,
        ).uids,
        isEmpty,
      );
    });

    test('@everyone only for admins', () {
      final admin = mentionsIn(
        '@everyone game moved',
        team,
        canMentionEveryone: true,
      );
      expect(admin.everyone, isTrue);
      expect(admin.uids, isEmpty);
      expect(
        mentionsIn(
          '@everyone game moved',
          team,
          canMentionEveryone: false,
        ).everyone,
        isFalse,
      );
    });

    test('each person once, and at most the limit', () {
      final many = [for (var i = 0; i < 30; i++) (uid: 'u$i', name: 'P$i')];
      final text = [for (var i = 0; i < 30; i++) '@P$i'].join(' ');
      expect(mentionsIn('$text @P0', many, canMentionEveryone: false).uids, [
        for (var i = 0; i < Limits.mentionsMax; i++) 'u$i',
      ]);
    });
  });

  test('mentionRanges marks where people are named, mine apart', () {
    const text = 'Hey @Sam Rivera and @everyone, ask @Alex Kim';
    expect(
      mentionRanges(
        text,
        names: {'sam': 'Sam Rivera', 'alex': 'Alex Kim'},
        everyone: true,
        me: 'alex',
      ),
      [
        (start: 4, end: 15, isMe: false),
        (start: 20, end: 29, isMe: true),
        (start: 35, end: 44, isMe: true),
      ],
    );
    // Without everyone, "@everyone" is plain text.
    expect(
      mentionRanges(text, names: {'sam': 'Sam Rivera'}).map((r) => r.start),
      [4],
    );
  });
}
