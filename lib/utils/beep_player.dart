import 'package:audioplayers/audioplayers.dart';

final AudioPlayer _beepPlayer = AudioPlayer();

Future<void> playAppBeep() async {
  try {
    await _beepPlayer.stop();
    await _beepPlayer.play(AssetSource('sounds/beep.wav'), volume: 1.0);
  } catch (_) {
    // Ignore playback errors.
  }
}
