import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

/// Service for playing synthesized TTS audio
class TTSAudioPlaybackService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  /// Play audio samples from TTS
  /// 
  /// [samples] - Float32 audio samples
  /// [sampleRate] - Sample rate in Hz (typically 22050 for Piper)
  Future<bool> playAudio(Float32List samples, int sampleRate) async {
    try {
      if (_isPlaying) {
        debugPrint('[TTS_PLAYBACK] Already playing, stopping current playback');
        await stop();
      }

      debugPrint('[TTS_PLAYBACK] Playing ${samples.length} samples at $sampleRate Hz');

      // Convert Float32 samples to Int16 PCM for audio playback
      final pcmData = _float32ToInt16PCM(samples);

      // Save to temporary WAV file
      final wavFile = await _createWavFile(pcmData, sampleRate);

      // Play the audio file
      _isPlaying = true;
      await _audioPlayer.play(DeviceFileSource(wavFile.path));

      // Listen for completion
      _audioPlayer.onPlayerComplete.listen((_) {
        _isPlaying = false;
        debugPrint('[TTS_PLAYBACK] ✅ Playback completed');
      });

      return true;
    } catch (e, stackTrace) {
      debugPrint('[TTS_PLAYBACK] Error playing audio: $e');
      debugPrint('[TTS_PLAYBACK] Stack trace: $stackTrace');
      _isPlaying = false;
      return false;
    }
  }

  /// Stop current playback
  Future<void> stop() async {
    if (_isPlaying) {
      await _audioPlayer.stop();
      _isPlaying = false;
      debugPrint('[TTS_PLAYBACK] Playback stopped');
    }
  }

  /// Convert Float32 samples to Int16 PCM
  Uint8List _float32ToInt16PCM(Float32List samples) {
    final pcm = ByteData(samples.length * 2); // 2 bytes per sample (Int16)

    for (int i = 0; i < samples.length; i++) {
      // Clamp to [-1.0, 1.0] and convert to Int16 range
      final sample = samples[i].clamp(-1.0, 1.0);
      final int16Value = (sample * 32767).round().clamp(-32768, 32767);
      pcm.setInt16(i * 2, int16Value, Endian.little);
    }

    return pcm.buffer.asUint8List();
  }

  /// Create a WAV file from PCM data
  Future<File> _createWavFile(Uint8List pcmData, int sampleRate) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final wavPath = path.join(tempDir.path, 'tts_$timestamp.wav');

    // WAV file header
    final wavHeader = _createWavHeader(
      pcmData.length,
      sampleRate: sampleRate,
      numChannels: 1, // Mono
      bitsPerSample: 16,
    );

    // Combine header and PCM data
    final wavFile = File(wavPath);
    final wavData = BytesBuilder();
    wavData.add(wavHeader);
    wavData.add(pcmData);

    await wavFile.writeAsBytes(wavData.toBytes());

    debugPrint('[TTS_PLAYBACK] Created WAV file: $wavPath');
    return wavFile;
  }

  /// Create WAV file header
  Uint8List _createWavHeader(
    int dataSize, {
    required int sampleRate,
    required int numChannels,
    required int bitsPerSample,
  }) {
    final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
    final blockAlign = numChannels * (bitsPerSample ~/ 8);

    final header = ByteData(44);

    // RIFF header
    header.setUint8(0, 0x52); // 'R'
    header.setUint8(1, 0x49); // 'I'
    header.setUint8(2, 0x46); // 'F'
    header.setUint8(3, 0x46); // 'F'
    header.setUint32(4, 36 + dataSize, Endian.little); // File size - 8

    // WAVE header
    header.setUint8(8, 0x57); // 'W'
    header.setUint8(9, 0x41); // 'A'
    header.setUint8(10, 0x56); // 'V'
    header.setUint8(11, 0x45); // 'E'

    // fmt subchunk
    header.setUint8(12, 0x66); // 'f'
    header.setUint8(13, 0x6D); // 'm'
    header.setUint8(14, 0x74); // 't'
    header.setUint8(15, 0x20); // ' '
    header.setUint32(16, 16, Endian.little); // Subchunk size
    header.setUint16(20, 1, Endian.little); // Audio format (PCM)
    header.setUint16(22, numChannels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);

    // data subchunk
    header.setUint8(36, 0x64); // 'd'
    header.setUint8(37, 0x61); // 'a'
    header.setUint8(38, 0x74); // 't'
    header.setUint8(39, 0x61); // 'a'
    header.setUint32(40, dataSize, Endian.little);

    return header.buffer.asUint8List();
  }

  /// Clean up resources
  Future<void> dispose() async {
    await stop();
    await _audioPlayer.dispose();
    debugPrint('[TTS_PLAYBACK] Disposed');
  }
}
