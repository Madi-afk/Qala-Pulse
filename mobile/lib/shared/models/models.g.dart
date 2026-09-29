// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppUser _$AppUserFromJson(Map<String, dynamic> json) => _AppUser(
  id: json['id'] as String,
  email: json['email'] as String,
  displayName: json['display_name'] as String,
  preferredLanguage: json['preferred_language'] as String? ?? 'ru',
  role: json['role'] as String? ?? 'citizen',
);

Map<String, dynamic> _$AppUserToJson(_AppUser instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'display_name': instance.displayName,
  'preferred_language': instance.preferredLanguage,
  'role': instance.role,
};

_IncidentCategory _$IncidentCategoryFromJson(Map<String, dynamic> json) =>
    _IncidentCategory(
      id: json['id'] as String,
      code: json['code'] as String,
      nameRu: json['name_ru'] as String,
      nameKk: json['name_kk'] as String,
      description: json['description'] as String,
      baseSeverity: (json['base_severity'] as num).toInt(),
      icon: json['icon'] as String,
      color: json['color'] as String,
      isActive: json['is_active'] as bool? ?? true,
    );

Map<String, dynamic> _$IncidentCategoryToJson(_IncidentCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name_ru': instance.nameRu,
      'name_kk': instance.nameKk,
      'description': instance.description,
      'base_severity': instance.baseSeverity,
      'icon': instance.icon,
      'color': instance.color,
      'is_active': instance.isActive,
    };

_Incident _$IncidentFromJson(Map<String, dynamic> json) => _Incident(
  id: json['id'] as String,
  authorId: json['author_id'] as String,
  categoryId: json['category_id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  severity: (json['severity'] as num).toInt(),
  priorityScore: (json['priority_score'] as num).toDouble(),
  status: json['status'] as String,
  confirmationCount: (json['confirmation_count'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  address: json['address'] as String? ?? '',
  source: json['source'] as String? ?? 'citizen',
  media:
      (json['media'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      const [],
  priorityExplanation:
      json['priority_explanation'] as Map<String, dynamic>? ?? const {},
  aiConfidence: (json['ai_confidence'] as num?)?.toDouble(),
  aiExplanation: json['ai_explanation'] as String?,
);

Map<String, dynamic> _$IncidentToJson(_Incident instance) => <String, dynamic>{
  'id': instance.id,
  'author_id': instance.authorId,
  'category_id': instance.categoryId,
  'title': instance.title,
  'description': instance.description,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'severity': instance.severity,
  'priority_score': instance.priorityScore,
  'status': instance.status,
  'confirmation_count': instance.confirmationCount,
  'created_at': instance.createdAt.toIso8601String(),
  'address': instance.address,
  'source': instance.source,
  'media': instance.media,
  'priority_explanation': instance.priorityExplanation,
  'ai_confidence': instance.aiConfidence,
  'ai_explanation': instance.aiExplanation,
};

_IncidentDraft _$IncidentDraftFromJson(Map<String, dynamic> json) =>
    _IncidentDraft(
      key: json['key'] as String,
      photoPath: json['photoPath'] as String?,
      photoBase64: json['photoBase64'] as String?,
      uploadId: json['uploadId'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      description: json['description'] as String? ?? '',
      title: json['title'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? 'other',
      severity: (json['severity'] as num?)?.toInt() ?? 3,
      address: json['address'] as String? ?? '',
      step: (json['step'] as num?)?.toInt() ?? 0,
      reviewed: json['reviewed'] as bool? ?? false,
      cloudConsent: json['cloudConsent'] as bool? ?? false,
      waitingToSend: json['waitingToSend'] as bool? ?? false,
      audioPath: json['audioPath'] as String? ?? '',
      audioUploadId: json['audioUploadId'] as String?,
      analysis: json['analysis'] as Map<String, dynamic>?,
      pendingPayload: json['pendingPayload'] as Map<String, dynamic>?,
      publicationError: json['publicationError'] as String?,
    );

Map<String, dynamic> _$IncidentDraftToJson(_IncidentDraft instance) =>
    <String, dynamic>{
      'key': instance.key,
      'photoPath': instance.photoPath,
      'photoBase64': instance.photoBase64,
      'uploadId': instance.uploadId,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'description': instance.description,
      'title': instance.title,
      'categoryId': instance.categoryId,
      'severity': instance.severity,
      'address': instance.address,
      'step': instance.step,
      'reviewed': instance.reviewed,
      'cloudConsent': instance.cloudConsent,
      'waitingToSend': instance.waitingToSend,
      'audioPath': instance.audioPath,
      'audioUploadId': instance.audioUploadId,
      'analysis': instance.analysis,
      'pendingPayload': instance.pendingPayload,
      'publicationError': instance.publicationError,
    };
