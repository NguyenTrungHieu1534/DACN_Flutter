import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class MyAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();

  MyAudioHandler() {
    _player.playerStateStream.listen((playerState) {
      _broadcastState(playerState);
    });

    _player.durationStream.listen((duration) {
      if (mediaItem.value != null && duration != null) {
        mediaItem.add(mediaItem.value!.copyWith(duration: duration));
      }
    });

    // Bổ sung lại để cập nhật thời gian phát thực tế
    _player.positionStream.listen((position) {
  final oldState = playbackState.value;
  playbackState.add(PlaybackState(
    controls: oldState.controls,
    systemActions: oldState.systemActions,
    androidCompactActionIndices: oldState.androidCompactActionIndices,
    processingState: oldState.processingState,
    playing: oldState.playing,
    updatePosition: position,
  ));
});
  }

  AudioPlayer get player => _player;

  @override
  Future<void> play() async {
    await _player.play();
    _broadcastState(_player.playerState);
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    _broadcastState(_player.playerState);
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    // KHÔNG gọi super.stop(); vì nó reset playbackState về 0
    _broadcastState(_player.playerState);
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setMediaItem(MediaItem item) async {
    mediaItem.add(item);
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    final newQueue = queue.value..add(mediaItem);
    queue.add(newQueue);
  }

  Future<void> setAudioSource(MediaItem item, Uri uriToPlay) async {
    mediaItem.add(item);
    await _player.setAudioSource(AudioSource.uri(uriToPlay));
  }

  void _broadcastState(PlayerState playerState) {
    final processingState = _mapProcessingState(playerState.processingState);

    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        playerState.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
        MediaControl(
          androidIcon: 'drawable/ic_favorite',
          label: 'Yêu thích',
          action: MediaAction.custom,
        ),
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.custom,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: processingState,
      playing: playerState.playing,
    ));
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
    return super.onTaskRemoved();
  }
}
