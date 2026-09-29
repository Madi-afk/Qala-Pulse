import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../core/api/api_client.dart';
import '../../core/errors/app_error.dart';
import '../../core/localization/strings.dart';
import '../../shared/widgets/async_panel.dart';
import 'draft_controller.dart';

class VoiceInput extends ConsumerStatefulWidget {
  const VoiceInput({super.key});
  @override
  ConsumerState<VoiceInput> createState() => _VoiceInputState();
}

class _VoiceInputState extends ConsumerState<VoiceInput> {
  final recorder = AudioRecorder();
  final player = AudioPlayer();
  Timer? timer;
  bool recording = false, busy = false, playing = false, mock = false;
  @override
  void dispose() {
    timer?.cancel();
    unawaited(recorder.dispose());
    unawaited(player.dispose());
    super.dispose();
  }

  Future<void> run(Future<void> Function() action) async {
    setState(() => busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage(error, context.l))));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> start() => run(() async {
    if (!await recorder.hasPermission()) throw StateError('microphone_denied');
    final directory = kIsWeb
        ? ''
        : (await getApplicationDocumentsDirectory()).path;
    final path =
        '$directory/voice-${DateTime.now().millisecondsSinceEpoch}.wav';
    await recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );
    if (mounted) setState(() => recording = true);
    timer = Timer(const Duration(seconds: 90), () {
      if (mounted && recording) unawaited(stop());
    });
  });

  Future<void> stop() => run(() async {
    timer?.cancel();
    final path = await recorder.stop();
    if (path != null) {
      await ref
          .read(draftProvider.notifier)
          .update(
            ref
                .read(draftProvider)
                .copyWith(audioPath: path, audioUploadId: null),
          );
    }
    if (mounted) setState(() => recording = false);
  });

  Future<void> transcribe() => run(() async {
    final language = Localizations.localeOf(context).languageCode;
    var draft = ref.read(draftProvider);
    var uploadId = draft.audioUploadId;
    if (uploadId == null) {
      final bytes = await XFile(draft.audioPath).readAsBytes();
      final data = await ref
          .read(apiProvider)
          .post(
            '/uploads/audio',
            FormData.fromMap({
              'file': MultipartFile.fromBytes(
                bytes,
                filename: 'voice.wav',
                contentType: DioMediaType('audio', 'wav'),
              ),
              'language': language,
              'cloud_consent': draft.cloudConsent,
            }),
          );
      uploadId = data['id'] as String;
      await ref
          .read(draftProvider.notifier)
          .update(draft.copyWith(audioUploadId: uploadId));
    } else {
      await ref.read(apiProvider).post('/uploads/$uploadId/retry', {});
    }
    for (var i = 0; i < 30; i++) {
      final result = await ref.read(apiProvider).get('/uploads/$uploadId');
      if (result['status'] == 'ready' || result['status'] == 'ready_mock') {
        draft = ref.read(draftProvider);
        await ref
            .read(draftProvider.notifier)
            .update(
              draft.copyWith(description: result['transcript'] as String),
            );
        if (mounted) setState(() => mock = result['status'] == 'ready_mock');
        return;
      }
      if (!mounted) return;
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    throw StateError('transcription_pending');
  });

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(draftProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l.voice, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: busy
                  ? null
                  : recording
                  ? stop
                  : start,
              icon: Icon(recording ? Icons.stop_circle : Icons.mic_none),
              label: Text(
                recording ? context.l.stopRecording : context.l.record,
              ),
            ),
            if (draft.audioPath.isNotEmpty && !recording) ...[
              OutlinedButton.icon(
                onPressed: busy
                    ? null
                    : () => run(() async {
                        if (playing) {
                          await player.stop();
                          if (mounted) setState(() => playing = false);
                        } else {
                          if (kIsWeb) {
                            await player.setUrl(draft.audioPath);
                          } else {
                            await player.setFilePath(draft.audioPath);
                          }
                          if (mounted) setState(() => playing = true);
                          unawaited(
                            player.play().whenComplete(() {
                              if (mounted) setState(() => playing = false);
                            }),
                          );
                        }
                      }),
                icon: Icon(playing ? Icons.stop : Icons.play_arrow),
                label: Text(playing ? context.l.stopPlayback : context.l.play),
              ),
              OutlinedButton(
                onPressed: busy
                    ? null
                    : () => run(() async {
                        await player.stop();
                        await ref
                            .read(draftProvider.notifier)
                            .update(
                              draft.copyWith(
                                audioPath: '',
                                audioUploadId: null,
                              ),
                            );
                        if (mounted) setState(() => playing = false);
                      }),
                child: Text(context.l.cancel),
              ),
              FilledButton.tonal(
                onPressed: busy ? null : transcribe,
                child: Text(context.l.transcribe),
              ),
            ],
          ],
        ),
        if (busy) const LinearProgressIndicator(),
        if (mock) Notice(context.l.mockTranscript),
        Notice(context.l.transcriptHint),
      ],
    );
  }
}
