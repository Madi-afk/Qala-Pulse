import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/api/api_client.dart';
import '../../core/localization/locale_controller.dart';
import '../../shared/models/models.dart';
import '../auth/auth_controller.dart';
import '../feed/incident_repository.dart';

class DraftStore {
  DraftStore(this.preferences, this.owner);
  final SharedPreferences preferences;
  final String owner;
  String get storageKey => 'draft.v1.$owner';
  IncidentDraft? load() {
    final raw = preferences.getString(storageKey);
    return raw == null
        ? null
        : IncidentDraft.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(IncidentDraft draft) async {
    if (!await preferences.setString(storageKey, jsonEncode(draft.toJson()))) {
      throw StateError('draft_storage_failed');
    }
  }

  Future<void> clear() async {
    await preferences.remove(storageKey);
  }
}

final draftStoreProvider = Provider<DraftStore>(
  (ref) => DraftStore(
    ref.watch(preferencesProvider),
    ref.watch(authProvider).asData?.value?.id ?? 'guest',
  ),
);
final draftProvider = NotifierProvider<DraftController, IncidentDraft>(
  DraftController.new,
);

class DraftController extends Notifier<IncidentDraft> {
  Future<void> _saving = Future.value();
  bool _publishing = false;
  @override
  IncidentDraft build() =>
      ref.watch(draftStoreProvider).load() ??
      IncidentDraft(key: const Uuid().v4());

  Future<void> update(IncidentDraft draft) {
    if (state.pendingPayload != null && draft != state) {
      throw StateError('publication_locked');
    }
    state = draft;
    final store = ref.read(draftStoreProvider);
    _saving = _saving.catchError((Object _) {}).then((_) => store.save(draft));
    return _saving;
  }

  Future<void> setPhoto(XFile photo) async {
    final owner = ref.read(draftStoreProvider).owner;
    final bytes = await photo.readAsBytes();
    _requireOwner(owner);
    if (bytes.length > 10 * 1024 * 1024) throw StateError('photo_too_large');
    if (kIsWeb) {
      await update(
        state.copyWith(
          photoBase64: base64Encode(bytes),
          photoPath: photo.name,
          uploadId: null,
          analysis: null,
          reviewed: false,
        ),
      );
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final target = File(
        '${directory.path}/qalapulse-${state.key}-${const Uuid().v4()}.jpg',
      );
      await target.writeAsBytes(bytes, flush: true);
      _requireOwner(owner);
      await update(
        state.copyWith(
          photoPath: target.path,
          photoBase64: null,
          uploadId: null,
          analysis: null,
          reviewed: false,
        ),
      );
    }
  }

  Future<Uint8List> photoBytes() async {
    if (state.photoBase64 != null) return base64Decode(state.photoBase64!);
    return File(state.photoPath!).readAsBytes();
  }

  Future<String> uploadPhoto({bool fullFrame = false}) async {
    if (fullFrame && state.pendingPayload != null) {
      throw StateError('publication_locked');
    }
    final owner = ref.read(draftStoreProvider).owner;
    if (state.uploadId != null && !fullFrame) return state.uploadId!;
    if (fullFrame) await update(state.copyWith(reviewed: false));
    final bytes = await photoBytes();
    _requireOwner(owner);
    final mime = bytes.length > 3 && bytes[0] == 0x89
        ? 'image/png'
        : bytes.length > 12 &&
              ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP'
        ? 'image/webp'
        : 'image/jpeg';
    final response = await ref
        .read(apiProvider)
        .post(
          '/uploads/images',
          FormData.fromMap({
            'full_frame': fullFrame,
            'file': MultipartFile.fromBytes(
              bytes,
              filename: 'incident',
              contentType: DioMediaType.parse(mime),
            ),
          }),
        );
    final id = response['id'] as String;
    _requireOwner(owner);
    await update(state.copyWith(uploadId: id, reviewed: false));
    return id;
  }

  Future<void> analyze(String language) async {
    final owner = ref.read(draftStoreProvider).owner;
    final upload = await uploadPhoto();
    _requireOwner(owner);
    final response = await ref.read(apiProvider).post('/incidents/analyze', {
      'upload_id': upload,
      'description': state.description,
      'language': language,
      'cloud_consent': state.cloudConsent,
    });
    final result = response['result'] as Map<String, dynamic>;
    _requireOwner(owner);
    await update(
      state.copyWith(
        analysis: response,
        title: result['title_$language'] as String,
        description: result['description_$language'] as String,
        categoryId: result['category_code'] as String,
        severity: result['severity'] as int,
        step: 4,
        reviewed: false,
      ),
    );
  }

  Future<List<Map<String, dynamic>>> duplicates() async {
    final result = await ref
        .read(apiProvider)
        .post('/incidents/duplicates/search', {
          'title': state.title,
          'description': state.description,
          'latitude': state.latitude,
          'longitude': state.longitude,
          'category_id': state.categoryId,
          'cloud_consent': state.cloudConsent,
        });
    return (result['items'] as List).cast<Map<String, dynamic>>();
  }

  Future<Incident> publish() async {
    if (_publishing) throw StateError('publication_in_progress');
    _publishing = true;
    final store = ref.read(draftStoreProvider);
    try {
      await _saving;
      _requireOwner(store.owner);
      if (state.pendingPayload == null) {
        if (!state.reviewed) throw StateError('review_required');
        final upload = await uploadPhoto();
        _requireOwner(store.owner);
        final payload = {
          'title': state.title,
          'description': state.description,
          'category_id': state.categoryId,
          'latitude': state.latitude,
          'longitude': state.longitude,
          'address': state.address,
          'severity': state.severity,
          'upload_ids': [upload],
          'reviewed_by_user': true,
          'publish': true,
          'cloud_consent': state.cloudConsent,
        };
        await update(
          state.copyWith(
            pendingPayload: payload,
            waitingToSend: true,
            step: 6,
            publicationError: null,
          ),
        );
      }
      _requireOwner(store.owner);
      final incident = await ref
          .read(repositoryProvider)
          .publish(state.pendingPayload!, state.key);
      await _clearOwned(store);
      ref.read(incidentChangesProvider.notifier).changed();
      return incident;
    } on DioException catch (error) {
      final body = error.response?.data;
      final detail = body is Map ? body['error'] : null;
      final code = detail is Map ? detail['code'] as String? : null;
      final saved = store.load();
      if (saved?.pendingPayload != null) {
        final definitive =
            error.response?.statusCode == 422 &&
            {
              'invalid_category',
              'review_required',
              'duplicate_upload',
              'redaction_required',
            }.contains(code);
        final next = definitive
            ? saved!.copyWith(
                key: const Uuid().v4(),
                pendingPayload: null,
                waitingToSend: false,
                reviewed: false,
                step: 4,
                publicationError: code,
              )
            : saved!.copyWith(publicationError: code ?? 'publication_unknown');
        await store.save(next);
        if (ref.read(draftStoreProvider).owner == store.owner) state = next;
        if (definitive) ref.invalidate(categoriesProvider);
      }
      rethrow;
    } finally {
      _publishing = false;
    }
  }

  Future<void> clear() async {
    if (state.pendingPayload != null) throw StateError('publication_locked');
    await _clearOwned(ref.read(draftStoreProvider));
  }

  void _requireOwner(String owner) {
    if (ref.read(draftStoreProvider).owner != owner) {
      throw StateError('session_changed');
    }
  }

  Future<void> _clearOwned(DraftStore store) async {
    await _saving;
    await store.clear();
    if (ref.read(draftStoreProvider).owner == store.owner) {
      state = IncidentDraft(key: const Uuid().v4());
    }
  }

  /// A server fence also blocks an earlier POST that has not acquired its lock yet.
  Future<Incident?> cancelPending({bool discard = false}) async {
    if (_publishing) throw StateError('publication_in_progress');
    _publishing = true;
    final store = ref.read(draftStoreProvider);
    final draft = state;
    try {
      await _saving;
      _requireOwner(store.owner);
      if (draft.pendingPayload != null) {
        final result = await ref
            .read(apiProvider)
            .post('/incidents/publications/${draft.key}/cancel', {});
        if (result['status'] == 'published') {
          final incident = Incident.fromJson(
            result['incident'] as Map<String, dynamic>,
          );
          await _clearOwned(store);
          ref.read(incidentChangesProvider.notifier).changed();
          return incident;
        }
        if (result['status'] != 'cancelled') {
          throw StateError('publication_unknown');
        }
      }
      if (discard) {
        await _clearOwned(store);
      } else {
        final editable = draft.copyWith(
          key: const Uuid().v4(),
          pendingPayload: null,
          waitingToSend: false,
          reviewed: false,
          publicationError: null,
          step: 4,
        );
        await store.save(editable);
        if (ref.read(draftStoreProvider).owner == store.owner) state = editable;
      }
      return null;
    } finally {
      _publishing = false;
    }
  }
}
