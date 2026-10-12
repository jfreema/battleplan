import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/features/groups/data/firestore_group_repository.dart';
import 'package:battleplan/features/groups/data/functions_media_repository.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/media.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  Group using(int used, int quota) => testGroup(
    'a',
    'Thunder',
  ).copyWith(storageBytes: used, storageQuotaBytes: quota);

  test('nearly full from 90%, full at the limit (STORE-3, STORE-4)', () {
    const quota = 500 * bytesPerMb;
    expect(using(449 * bytesPerMb, quota).storageLevel, StorageLevel.ok);
    expect(using(450 * bytesPerMb, quota).storageNearlyFull, isTrue);
    expect(using(450 * bytesPerMb, quota).storageFull, isFalse);
    expect(using(quota - 1, quota).storageLevel, StorageLevel.nearlyFull);
    expect(using(quota, quota).storageFull, isTrue);
    expect(using(quota + 1, quota).storageNearlyFull, isTrue);
    // A team read without a quota is never full.
    expect(using(quota, 0).storageLevel, StorageLevel.ok);
  });

  test('a team without a stored quota gets the 500 MB default (STORE-1)', () {
    Group read(Object? quota) => groupFromFirestore('a', {
      'name': 'Thunder',
      'storageBytes': 10,
      'storageQuotaBytes': ?quota,
    });
    expect(
      read(null).storageQuotaBytes,
      Limits.defaultStorageQuotaMb * bytesPerMb,
    );
    expect(
      read(0).storageQuotaBytes,
      Limits.defaultStorageQuotaMb * bytesPerMb,
    );
    // A super admin's limit is kept (STORE-6).
    expect(read(2048 * bytesPerMb).storageQuotaBytes, 2048 * bytesPerMb);
  });

  test("listTeamMedia's reply reads as the team's media (STORE-5)", () {
    final media = teamMediaFromCallable({
      'files': [
        {'path': 'groups/a/avatar/1.jpg', 'size': 10, 'kind': 'logo'},
        {'path': 'groups/a/messages/m1/0.jpg', 'size': 30, 'kind': 'chatPhoto'},
      ],
      'truncated': true,
      'storageBytes': 40,
      'storageQuotaBytes': 500 * bytesPerMb,
    });
    expect(media.items.map((i) => i.size), [30, 10]);
    expect(media.truncated, isTrue);
    expect(media.storageBytes, 40);
    expect(media.storageQuotaBytes, 500 * bytesPerMb);
    expect(teamMediaFromCallable({}).items, isEmpty);
  });

  test('Media items read from listTeamMedia (STORE-5)', () {
    final photo = mediaItemFromCallable({
      'path': 'groups/a/messages/m1/0.jpg',
      'size': 1234,
      'contentType': 'image/jpeg',
      'createdAt': '2026-10-12T15:00:00.000Z',
      'kind': 'chatPhoto',
      'messageId': 'm1',
      'authorName': 'Sam Rivera',
    });
    expect(photo.kind, MediaKind.chatPhoto);
    expect(photo.isImage, isTrue);
    expect(photo.createdAt, DateTime.utc(2026, 10, 12, 15));
    expect(photo.authorName, 'Sam Rivera');

    final old = mediaItemFromCallable({
      'path': 'groups/a/avatar/1.jpg',
      'size': 10,
      'kind': 'logo',
      'current': false,
    });
    expect(old.current, isFalse);
    // A kind this app doesn't know yet still lists.
    expect(
      mediaItemFromCallable({'path': 'p', 'size': 1, 'kind': 'video'}).kind,
      MediaKind.other,
    );
  });
}
