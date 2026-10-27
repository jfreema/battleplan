/// How long each step takes in a play's GIF (BOARD-5), in hundredths of a
/// second: the first shows for this long, and each later one glides into
/// place over it.
const gifStepTime = 150;

/// How long a play's GIF holds its last step before it starts over.
const gifEndTime = 300;

/// How long each frame of a glide shows: 20 frames a second.
const gifFrameTime = 5;

/// One frame of a play's GIF: the board `t` of the way (0 to 1, before
/// easing) from step `step` to the next one, shown for `delay` hundredths
/// of a second. At 0 it's that step as it stands.
typedef PlayGifFrame = ({int step, double t, int delay});

/// A play of [steps] steps as a GIF, frame by frame (BOARD-5): the first
/// step for 1.5 seconds, each later step gliding into place over 1.5
/// seconds, and the last step held for 3 seconds before it starts over.
List<PlayGifFrame> playGifFrames(int steps) {
  const glide = gifStepTime ~/ gifFrameTime;
  final frames = <PlayGifFrame>[(step: 0, t: 0, delay: gifStepTime)];
  for (var i = 0; i < steps - 1; i++) {
    for (var k = 1; k < glide; k++) {
      frames.add((step: i, t: k / glide, delay: gifFrameTime));
    }
    frames.add((step: i + 1, t: 0, delay: gifFrameTime));
  }
  final last = frames.removeLast();
  return frames..add((step: last.step, t: 0, delay: gifEndTime));
}

/// What a play's GIF is called when saved, without ".gif": the play's
/// name, less the characters file names can't have.
String playGifName(String title) {
  final name = title
      .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return name.isEmpty ? 'Play' : name;
}
