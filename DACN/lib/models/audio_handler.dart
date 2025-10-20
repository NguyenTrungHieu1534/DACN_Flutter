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

    // _player.positionStream.listen((position) {
    //   playbackState.add(playbackState.value.copyWith(position: position));
    // });
  }

  AudioPlayer get player => _player;

  @override
  Future<void> play() async {
    await _player.play();
    // Bổ sung: Gửi trạng thái hiện tại (đang phát) lên audio_service
    _broadcastState(_player.playerState);
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    // Bổ sung: Gửi trạng thái hiện tại (đã tạm dừng) lên audio_service
    _broadcastState(_player.playerState);
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
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
      androidCompactActionIndices: const [0, 1, 2],  // Show prev, play/pause, next in compact view
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
    await stop(); // Tắt nhạc
    return super.onTaskRemoved();
  }
}
