import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../core/api/api_client.dart';
import '../../core/errors/app_error.dart';
import '../../core/localization/strings.dart';
import '../../core/location/location_service.dart';
import '../../core/permissions/permission_service.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/async_panel.dart';
import '../../shared/widgets/incident_card.dart';
import '../../shared/widgets/persisted_text_field.dart';
import '../auth/auth_controller.dart';
import '../feed/incident_repository.dart';
import '../map/city_map.dart';
import 'draft_controller.dart';
import 'voice_input.dart';

class CreateScreen extends ConsumerStatefulWidget {
  const CreateScreen({super.key});
  @override
  ConsumerState<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends ConsumerState<CreateScreen> {
  bool busy = false;
  List<Map<String, dynamic>>? candidates;
  Uint8List? photo, preview;
  String? loadedPhoto;
  String? displayedOwner;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final lost = await picker.retrieveLostData();
        if (lost.files?.isNotEmpty ?? false) {
          await ref.read(draftProvider.notifier).setPhoto(lost.files!.first);
          if (mounted) setState(() => loadedPhoto = null);
        }
      } catch (_) {
        /* This recovery API is Android-only. */
      }
    });
  }

  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
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

  void update(IncidentDraft next) {
    ref.read(draftProvider.notifier).update(next).catchError((Object error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l.actionError)));
      }
    });
  }

  Future<void> pick(ImageSource source) => run(() async {
    final file = await picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 2000,
    );
    if (file != null) {
      await ref.read(draftProvider.notifier).setPhoto(file);
      loadedPhoto = null;
    }
  });
  Future<void> loadPhoto(IncidentDraft draft) async {
    if (draft.photoPath == null || loadedPhoto == draft.photoPath) return;
    loadedPhoto = draft.photoPath;
    try {
      final bytes = await ref.read(draftProvider.notifier).photoBytes();
      if (mounted) setState(() => photo = bytes);
    } catch (_) {
      if (mounted) setState(() => photo = null);
    }
  }

  Future<void> loadPreview() async {
    final id = await ref.read(draftProvider.notifier).uploadPhoto();
    final result = await ref
        .read(apiProvider)
        .dio
        .get<List<int>>(
          '/uploads/$id/preview',
          options: Options(responseType: ResponseType.bytes),
        );
    if (mounted) {
      setState(() => preview = Uint8List.fromList(result.data!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).asData?.value;
    if (displayedOwner != user?.id) {
      displayedOwner = user?.id;
      photo = preview = null;
      loadedPhoto = null;
      candidates = null;
    }
    if (user == null) {
      return Center(
        child: FilledButton(
          onPressed: () => context.push('/auth'),
          child: Text(context.l.loginRequired),
        ),
      );
    }
    final draft = ref.watch(draftProvider);
    final controller = ref.read(draftProvider.notifier);
    if (draft.photoPath != loadedPhoto) {
      WidgetsBinding.instance.addPostFrameCallback((_) => loadPhoto(draft));
    }
    final titles = [
      context.l.photo,
      context.l.location,
      context.l.description,
      context.l.aiAnalysis,
      context.l.aiReview,
      context.l.duplicates,
      context.l.publish,
    ];
    final step = draft.step.clamp(0, 6);
    return ListView(
      key: ValueKey('create-step-$step'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.l.reportProblem,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Text(
              '${step + 1} / 7',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: (step + 1) / 7,
          minHeight: 6,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 24),
        Text(titles[step], style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        if (busy) ...[
          const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(step == 3 ? context.l.analyzing : context.l.loading),
          ),
        ],
        if (draft.waitingToSend)
          Notice(
            '${context.l.waitingToSend}\n${context.l.pendingLocked}',
            icon: Icons.cloud_upload_outlined,
          ),
        if (draft.publicationError != null)
          Notice(publicationMessage(draft.publicationError!, context.l)),
        if (draft.pendingPayload != null)
          OutlinedButton(
            onPressed: busy
                ? null
                : () => run(() async {
                    final result = await controller.cancelPending();
                    if (context.mounted && result != null) {
                      context.go('/success/${result.id}');
                    }
                  }),
            child: Text(context.l.recoverPublication),
          ),
        if (step == 0) ...[
          if (photo != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.memory(photo!, height: 240, fit: BoxFit.cover),
            ),
          Notice(context.l.photoHint),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: busy ? null : () => pick(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(context.l.camera),
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : () => pick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(context.l.gallery),
              ),
            ],
          ),
          Notice(context.l.offlineDraftHint),
        ],
        if (step == 1) ...[
          Notice(context.l.locationHint),
          SizedBox(
            height: 270,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CityMap(
                center: LatLng(
                  draft.latitude ?? 43.2389,
                  draft.longitude ?? 76.8897,
                ),
                selected: draft.latitude == null || draft.longitude == null
                    ? null
                    : LatLng(draft.latitude!, draft.longitude!),
                onSelect: (point) => update(
                  draft.copyWith(
                    latitude: point.latitude,
                    longitude: point.longitude,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: busy
                ? null
                : () => run(() async {
                    try {
                      final point = await ref.read(locationProvider).current();
                      update(
                        ref
                            .read(draftProvider)
                            .copyWith(
                              latitude: point.latitude,
                              longitude: point.longitude,
                            ),
                      );
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.l.gpsDenied),
                            action: SnackBarAction(
                              label: context.l.settings,
                              onPressed: PermissionService.openSettings,
                            ),
                          ),
                        );
                      }
                    }
                  }),
            icon: const Icon(Icons.my_location),
            label: Text(context.l.currentLocation),
          ),
          Row(
            children: [
              Expanded(
                child: PersistedTextField(
                  value: draft.latitude?.toStringAsFixed(6) ?? '',
                  label: context.l.latitude,
                  numeric: true,
                  onChanged: (value) {
                    final n = double.tryParse(value.replaceAll(',', '.'));
                    update(
                      ref
                          .read(draftProvider)
                          .copyWith(
                            latitude:
                                n != null && n.isFinite && n >= -90 && n <= 90
                                ? n
                                : null,
                          ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PersistedTextField(
                  value: draft.longitude?.toStringAsFixed(6) ?? '',
                  label: context.l.longitude,
                  numeric: true,
                  onChanged: (value) {
                    final n = double.tryParse(value.replaceAll(',', '.'));
                    update(
                      ref
                          .read(draftProvider)
                          .copyWith(
                            longitude:
                                n != null && n.isFinite && n >= -180 && n <= 180
                                ? n
                                : null,
                          ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: draft.address,
            decoration: InputDecoration(labelText: context.l.address),
            maxLength: 300,
            onChanged: (value) =>
                update(ref.read(draftProvider).copyWith(address: value)),
          ),
        ],
        if (step == 2) ...[
          PersistedTextField(
            value: draft.description,
            minLines: 4,
            maxLines: 7,
            maxLength: 4000,
            label: context.l.description,
            hint: context.l.descriptionHint,
            onChanged: (value) =>
                update(ref.read(draftProvider).copyWith(description: value)),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: draft.cloudConsent,
            onChanged: (value) =>
                update(draft.copyWith(cloudConsent: value ?? false)),
            title: Text(context.l.cloudConsent),
          ),
          const VoiceInput(),
        ],
        if (step == 3) ...[
          const Icon(
            Icons.auto_awesome_outlined,
            size: 72,
            color: Color(0xFF087E70),
          ),
          Notice(context.l.aiWarning),
          FilledButton.icon(
            onPressed: busy
                ? null
                : () => run(
                    () => controller.analyze(
                      Localizations.localeOf(context).languageCode,
                    ),
                  ),
            icon: const Icon(Icons.auto_awesome),
            label: Text(context.l.analyze),
          ),
          TextButton(
            onPressed: busy ? null : () => update(draft.copyWith(step: 4)),
            child: Text(context.l.manualEntry),
          ),
        ],
        if (step == 4) ...[
          if (draft.analysis != null) AiResultNotice(analysis: draft.analysis!),
          TextFormField(
            initialValue: draft.title,
            decoration: InputDecoration(labelText: context.l.title),
            maxLength: 160,
            onChanged: (value) => update(
              ref.read(draftProvider).copyWith(title: value, reviewed: false),
            ),
          ),
          const SizedBox(height: 12),
          AsyncPanel(
            value: ref.watch(categoriesProvider),
            onRetry: () => ref.invalidate(categoriesProvider),
            builder: (categories) => DropdownButtonFormField<String>(
              initialValue: categories.any((c) => c.id == draft.categoryId)
                  ? draft.categoryId
                  : null,
              decoration: InputDecoration(labelText: context.l.category),
              items: categories
                  .map(
                    (c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(
                        Localizations.localeOf(context).languageCode == 'kk'
                            ? c.nameKk
                            : c.nameRu,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  update(
                    ref
                        .read(draftProvider)
                        .copyWith(categoryId: value, reviewed: false),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: draft.description,
            minLines: 3,
            maxLines: 6,
            maxLength: 4000,
            decoration: InputDecoration(labelText: context.l.description),
            onChanged: (value) => update(
              ref
                  .read(draftProvider)
                  .copyWith(description: value, reviewed: false),
            ),
          ),
          Text('${context.l.severity}: ${draft.severity}/10'),
          Slider(
            value: draft.severity.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: draft.severity.toString(),
            onChanged: (value) => update(
              ref
                  .read(draftProvider)
                  .copyWith(severity: value.round(), reviewed: false),
            ),
          ),
        ],
        if (step == 5) ...[
          Notice(context.l.duplicatesHint),
          FilledButton.tonal(
            onPressed: busy
                ? null
                : () => run(() async {
                    final result = await controller.duplicates();
                    if (context.mounted) setState(() => candidates = result);
                  }),
            child: Text(context.l.searchDuplicates),
          ),
          if (candidates != null && candidates!.isEmpty)
            Notice(context.l.noDuplicates),
          if (candidates != null)
            DuplicateCards(
              candidates: candidates!,
              busy: busy,
              onConfirm: (id) => run(() async {
                await ref.read(repositoryProvider).confirm(id, 'still_exists');
                await controller.clear();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l.confirmationSent)),
                  );
                  context.go('/incident/$id');
                }
              }),
            ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: busy
                ? null
                : () => run(() async {
                    await loadPreview();
                    update(ref.read(draftProvider).copyWith(step: 6));
                  }),
            child: Text(context.l.createAnyway),
          ),
        ],
        if (step == 6) ...[
          Text(draft.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(draft.description),
          const SizedBox(height: 12),
          Text(
            '${draft.latitude?.toStringAsFixed(5)}, ${draft.longitude?.toStringAsFixed(5)}',
          ),
          Notice(context.l.privacyNotice),
          Text(context.l.privacyPreview),
          if (preview != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Image.memory(preview!, height: 200, fit: BoxFit.cover),
            )
          else
            OutlinedButton(
              onPressed: busy ? null : () => run(loadPreview),
              child: Text(context.l.photo),
            ),
          Notice(context.l.honestNotice),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: draft.reviewed,
            onChanged: busy || draft.pendingPayload != null
                ? null
                : (value) => update(draft.copyWith(reviewed: value ?? false)),
            title: Text(context.l.publishConfirm),
          ),
          FilledButton.icon(
            onPressed: busy || !draft.reviewed
                ? null
                : () => run(() async {
                    final result = await controller.publish();
                    if (context.mounted) context.go('/success/${result.id}');
                  }),
            icon: const Icon(Icons.publish_outlined),
            label: Text(
              draft.waitingToSend ? context.l.retryPublish : context.l.publish,
            ),
          ),
        ],
        const SizedBox(height: 24),
        if (step != 3 && step != 5 && step != 6)
          FilledButton(
            onPressed: busy
                ? null
                : () {
                    if ((step == 0 && draft.photoPath == null) ||
                        (step == 1 &&
                            (draft.latitude == null ||
                                draft.longitude == null)) ||
                        (step == 4 && draft.title.trim().length < 3)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.l.checkFields)),
                      );
                      return;
                    }
                    update(draft.copyWith(step: step + 1));
                    if (step == 4) {
                      run(() async {
                        final result = await controller.duplicates();
                        if (context.mounted) {
                          setState(() => candidates = result);
                        }
                      });
                    }
                  },
            child: Text(context.l.next),
          ),
        if (step > 0 && draft.pendingPayload == null)
          TextButton(
            onPressed: busy
                ? null
                : () => update(draft.copyWith(step: step - 1)),
            child: Text(context.l.back),
          ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: busy
              ? null
              : () => run(() async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: Text(context.l.discardDraft),
                      content: Text(context.l.discardDraftPrompt),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: Text(context.l.back),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: Text(context.l.discardDraft),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                  final result = await controller.cancelPending(discard: true);
                  if (context.mounted && result != null) {
                    context.go('/success/${result.id}');
                  }
                }),
          icon: const Icon(Icons.delete_outline),
          label: Text(context.l.discardDraft),
        ),
        Center(
          child: Text(
            context.l.draftSaved,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ],
    );
  }
}

class AiResultNotice extends StatelessWidget {
  const AiResultNotice({super.key, required this.analysis});
  final Map<String, dynamic> analysis;
  @override
  Widget build(BuildContext context) {
    final result = analysis['result'] as Map<String, dynamic>;
    return Column(
      children: [
        Notice(context.l.aiWarning),
        if (analysis['mode'] == 'mock') Notice(context.l.mockAi),
        if (result['is_civic_issue'] == false)
          Notice(context.l.notCivic, icon: Icons.warning_amber_rounded),
        if (analysis['mode'] == 'cloud')
          Text(
            '${context.l.confidence}: ${((result['confidence'] as num) * 100).round()}%',
          ),
        Text(
          result['explanation_${Localizations.localeOf(context).languageCode}']
                  as String? ??
              '',
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class DuplicateCards extends StatelessWidget {
  const DuplicateCards({
    super.key,
    required this.candidates,
    required this.onConfirm,
    this.busy = false,
  });
  final List<Map<String, dynamic>> candidates;
  final ValueChanged<String> onConfirm;
  final bool busy;
  @override
  Widget build(BuildContext context) => Column(
    children: candidates.map((candidate) {
      final incident = Incident.fromJson(
        candidate['incident'] as Map<String, dynamic>,
      );
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IncidentCard(incident),
            FilledButton.tonal(
              onPressed: busy ? null : () => onConfirm(incident.id),
              child: Text(context.l.confirmExisting),
            ),
          ],
        ),
      );
    }).toList(),
  );
}
