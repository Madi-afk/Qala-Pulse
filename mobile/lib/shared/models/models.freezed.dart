// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppUser {

 String get id; String get email; String get displayName; String get preferredLanguage; String get role;
/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppUserCopyWith<AppUser> get copyWith => _$AppUserCopyWithImpl<AppUser>(this as AppUser, _$identity);

  /// Serializes this AppUser to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppUser&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.preferredLanguage, preferredLanguage) || other.preferredLanguage == preferredLanguage)&&(identical(other.role, role) || other.role == role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,email,displayName,preferredLanguage,role);

@override
String toString() {
  return 'AppUser(id: $id, email: $email, displayName: $displayName, preferredLanguage: $preferredLanguage, role: $role)';
}


}

/// @nodoc
abstract mixin class $AppUserCopyWith<$Res>  {
  factory $AppUserCopyWith(AppUser value, $Res Function(AppUser) _then) = _$AppUserCopyWithImpl;
@useResult
$Res call({
 String id, String email, String displayName, String preferredLanguage, String role
});




}
/// @nodoc
class _$AppUserCopyWithImpl<$Res>
    implements $AppUserCopyWith<$Res> {
  _$AppUserCopyWithImpl(this._self, this._then);

  final AppUser _self;
  final $Res Function(AppUser) _then;

/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? email = null,Object? displayName = null,Object? preferredLanguage = null,Object? role = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,preferredLanguage: null == preferredLanguage ? _self.preferredLanguage : preferredLanguage // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AppUser].
extension AppUserPatterns on AppUser {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppUser() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppUser value)  $default,){
final _that = this;
switch (_that) {
case _AppUser():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppUser value)?  $default,){
final _that = this;
switch (_that) {
case _AppUser() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String email,  String displayName,  String preferredLanguage,  String role)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppUser() when $default != null:
return $default(_that.id,_that.email,_that.displayName,_that.preferredLanguage,_that.role);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String email,  String displayName,  String preferredLanguage,  String role)  $default,) {final _that = this;
switch (_that) {
case _AppUser():
return $default(_that.id,_that.email,_that.displayName,_that.preferredLanguage,_that.role);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String email,  String displayName,  String preferredLanguage,  String role)?  $default,) {final _that = this;
switch (_that) {
case _AppUser() when $default != null:
return $default(_that.id,_that.email,_that.displayName,_that.preferredLanguage,_that.role);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _AppUser implements AppUser {
  const _AppUser({required this.id, required this.email, required this.displayName, this.preferredLanguage = 'ru', this.role = 'citizen'});
  factory _AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);

@override final  String id;
@override final  String email;
@override final  String displayName;
@override@JsonKey() final  String preferredLanguage;
@override@JsonKey() final  String role;

/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppUserCopyWith<_AppUser> get copyWith => __$AppUserCopyWithImpl<_AppUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppUserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppUser&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.preferredLanguage, preferredLanguage) || other.preferredLanguage == preferredLanguage)&&(identical(other.role, role) || other.role == role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,email,displayName,preferredLanguage,role);

@override
String toString() {
  return 'AppUser(id: $id, email: $email, displayName: $displayName, preferredLanguage: $preferredLanguage, role: $role)';
}


}

/// @nodoc
abstract mixin class _$AppUserCopyWith<$Res> implements $AppUserCopyWith<$Res> {
  factory _$AppUserCopyWith(_AppUser value, $Res Function(_AppUser) _then) = __$AppUserCopyWithImpl;
@override @useResult
$Res call({
 String id, String email, String displayName, String preferredLanguage, String role
});




}
/// @nodoc
class __$AppUserCopyWithImpl<$Res>
    implements _$AppUserCopyWith<$Res> {
  __$AppUserCopyWithImpl(this._self, this._then);

  final _AppUser _self;
  final $Res Function(_AppUser) _then;

/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? email = null,Object? displayName = null,Object? preferredLanguage = null,Object? role = null,}) {
  return _then(_AppUser(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,preferredLanguage: null == preferredLanguage ? _self.preferredLanguage : preferredLanguage // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$IncidentCategory {

 String get id; String get code; String get nameRu; String get nameKk; String get description; int get baseSeverity; String get icon; String get color; bool get isActive;
/// Create a copy of IncidentCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IncidentCategoryCopyWith<IncidentCategory> get copyWith => _$IncidentCategoryCopyWithImpl<IncidentCategory>(this as IncidentCategory, _$identity);

  /// Serializes this IncidentCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IncidentCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.nameRu, nameRu) || other.nameRu == nameRu)&&(identical(other.nameKk, nameKk) || other.nameKk == nameKk)&&(identical(other.description, description) || other.description == description)&&(identical(other.baseSeverity, baseSeverity) || other.baseSeverity == baseSeverity)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,nameRu,nameKk,description,baseSeverity,icon,color,isActive);

@override
String toString() {
  return 'IncidentCategory(id: $id, code: $code, nameRu: $nameRu, nameKk: $nameKk, description: $description, baseSeverity: $baseSeverity, icon: $icon, color: $color, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class $IncidentCategoryCopyWith<$Res>  {
  factory $IncidentCategoryCopyWith(IncidentCategory value, $Res Function(IncidentCategory) _then) = _$IncidentCategoryCopyWithImpl;
@useResult
$Res call({
 String id, String code, String nameRu, String nameKk, String description, int baseSeverity, String icon, String color, bool isActive
});




}
/// @nodoc
class _$IncidentCategoryCopyWithImpl<$Res>
    implements $IncidentCategoryCopyWith<$Res> {
  _$IncidentCategoryCopyWithImpl(this._self, this._then);

  final IncidentCategory _self;
  final $Res Function(IncidentCategory) _then;

/// Create a copy of IncidentCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? nameRu = null,Object? nameKk = null,Object? description = null,Object? baseSeverity = null,Object? icon = null,Object? color = null,Object? isActive = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,nameRu: null == nameRu ? _self.nameRu : nameRu // ignore: cast_nullable_to_non_nullable
as String,nameKk: null == nameKk ? _self.nameKk : nameKk // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,baseSeverity: null == baseSeverity ? _self.baseSeverity : baseSeverity // ignore: cast_nullable_to_non_nullable
as int,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [IncidentCategory].
extension IncidentCategoryPatterns on IncidentCategory {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IncidentCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IncidentCategory() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IncidentCategory value)  $default,){
final _that = this;
switch (_that) {
case _IncidentCategory():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IncidentCategory value)?  $default,){
final _that = this;
switch (_that) {
case _IncidentCategory() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String code,  String nameRu,  String nameKk,  String description,  int baseSeverity,  String icon,  String color,  bool isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IncidentCategory() when $default != null:
return $default(_that.id,_that.code,_that.nameRu,_that.nameKk,_that.description,_that.baseSeverity,_that.icon,_that.color,_that.isActive);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String code,  String nameRu,  String nameKk,  String description,  int baseSeverity,  String icon,  String color,  bool isActive)  $default,) {final _that = this;
switch (_that) {
case _IncidentCategory():
return $default(_that.id,_that.code,_that.nameRu,_that.nameKk,_that.description,_that.baseSeverity,_that.icon,_that.color,_that.isActive);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String code,  String nameRu,  String nameKk,  String description,  int baseSeverity,  String icon,  String color,  bool isActive)?  $default,) {final _that = this;
switch (_that) {
case _IncidentCategory() when $default != null:
return $default(_that.id,_that.code,_that.nameRu,_that.nameKk,_that.description,_that.baseSeverity,_that.icon,_that.color,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _IncidentCategory implements IncidentCategory {
  const _IncidentCategory({required this.id, required this.code, required this.nameRu, required this.nameKk, required this.description, required this.baseSeverity, required this.icon, required this.color, this.isActive = true});
  factory _IncidentCategory.fromJson(Map<String, dynamic> json) => _$IncidentCategoryFromJson(json);

@override final  String id;
@override final  String code;
@override final  String nameRu;
@override final  String nameKk;
@override final  String description;
@override final  int baseSeverity;
@override final  String icon;
@override final  String color;
@override@JsonKey() final  bool isActive;

/// Create a copy of IncidentCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IncidentCategoryCopyWith<_IncidentCategory> get copyWith => __$IncidentCategoryCopyWithImpl<_IncidentCategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IncidentCategoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IncidentCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.nameRu, nameRu) || other.nameRu == nameRu)&&(identical(other.nameKk, nameKk) || other.nameKk == nameKk)&&(identical(other.description, description) || other.description == description)&&(identical(other.baseSeverity, baseSeverity) || other.baseSeverity == baseSeverity)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,nameRu,nameKk,description,baseSeverity,icon,color,isActive);

@override
String toString() {
  return 'IncidentCategory(id: $id, code: $code, nameRu: $nameRu, nameKk: $nameKk, description: $description, baseSeverity: $baseSeverity, icon: $icon, color: $color, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$IncidentCategoryCopyWith<$Res> implements $IncidentCategoryCopyWith<$Res> {
  factory _$IncidentCategoryCopyWith(_IncidentCategory value, $Res Function(_IncidentCategory) _then) = __$IncidentCategoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String code, String nameRu, String nameKk, String description, int baseSeverity, String icon, String color, bool isActive
});




}
/// @nodoc
class __$IncidentCategoryCopyWithImpl<$Res>
    implements _$IncidentCategoryCopyWith<$Res> {
  __$IncidentCategoryCopyWithImpl(this._self, this._then);

  final _IncidentCategory _self;
  final $Res Function(_IncidentCategory) _then;

/// Create a copy of IncidentCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? nameRu = null,Object? nameKk = null,Object? description = null,Object? baseSeverity = null,Object? icon = null,Object? color = null,Object? isActive = null,}) {
  return _then(_IncidentCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,nameRu: null == nameRu ? _self.nameRu : nameRu // ignore: cast_nullable_to_non_nullable
as String,nameKk: null == nameKk ? _self.nameKk : nameKk // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,baseSeverity: null == baseSeverity ? _self.baseSeverity : baseSeverity // ignore: cast_nullable_to_non_nullable
as int,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$Incident {

 String get id; String get authorId; String get categoryId; String get title; String get description; double get latitude; double get longitude; int get severity; double get priorityScore; String get status; int get confirmationCount; DateTime get createdAt; String get address; String get source; List<Map<String, dynamic>> get media; Map<String, dynamic> get priorityExplanation; double? get aiConfidence; String? get aiExplanation;
/// Create a copy of Incident
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IncidentCopyWith<Incident> get copyWith => _$IncidentCopyWithImpl<Incident>(this as Incident, _$identity);

  /// Serializes this Incident to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Incident&&(identical(other.id, id) || other.id == id)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.priorityScore, priorityScore) || other.priorityScore == priorityScore)&&(identical(other.status, status) || other.status == status)&&(identical(other.confirmationCount, confirmationCount) || other.confirmationCount == confirmationCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.address, address) || other.address == address)&&(identical(other.source, source) || other.source == source)&&const DeepCollectionEquality().equals(other.media, media)&&const DeepCollectionEquality().equals(other.priorityExplanation, priorityExplanation)&&(identical(other.aiConfidence, aiConfidence) || other.aiConfidence == aiConfidence)&&(identical(other.aiExplanation, aiExplanation) || other.aiExplanation == aiExplanation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,authorId,categoryId,title,description,latitude,longitude,severity,priorityScore,status,confirmationCount,createdAt,address,source,const DeepCollectionEquality().hash(media),const DeepCollectionEquality().hash(priorityExplanation),aiConfidence,aiExplanation);

@override
String toString() {
  return 'Incident(id: $id, authorId: $authorId, categoryId: $categoryId, title: $title, description: $description, latitude: $latitude, longitude: $longitude, severity: $severity, priorityScore: $priorityScore, status: $status, confirmationCount: $confirmationCount, createdAt: $createdAt, address: $address, source: $source, media: $media, priorityExplanation: $priorityExplanation, aiConfidence: $aiConfidence, aiExplanation: $aiExplanation)';
}


}

/// @nodoc
abstract mixin class $IncidentCopyWith<$Res>  {
  factory $IncidentCopyWith(Incident value, $Res Function(Incident) _then) = _$IncidentCopyWithImpl;
@useResult
$Res call({
 String id, String authorId, String categoryId, String title, String description, double latitude, double longitude, int severity, double priorityScore, String status, int confirmationCount, DateTime createdAt, String address, String source, List<Map<String, dynamic>> media, Map<String, dynamic> priorityExplanation, double? aiConfidence, String? aiExplanation
});




}
/// @nodoc
class _$IncidentCopyWithImpl<$Res>
    implements $IncidentCopyWith<$Res> {
  _$IncidentCopyWithImpl(this._self, this._then);

  final Incident _self;
  final $Res Function(Incident) _then;

/// Create a copy of Incident
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? authorId = null,Object? categoryId = null,Object? title = null,Object? description = null,Object? latitude = null,Object? longitude = null,Object? severity = null,Object? priorityScore = null,Object? status = null,Object? confirmationCount = null,Object? createdAt = null,Object? address = null,Object? source = null,Object? media = null,Object? priorityExplanation = null,Object? aiConfidence = freezed,Object? aiExplanation = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,authorId: null == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as int,priorityScore: null == priorityScore ? _self.priorityScore : priorityScore // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,confirmationCount: null == confirmationCount ? _self.confirmationCount : confirmationCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,media: null == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,priorityExplanation: null == priorityExplanation ? _self.priorityExplanation : priorityExplanation // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,aiConfidence: freezed == aiConfidence ? _self.aiConfidence : aiConfidence // ignore: cast_nullable_to_non_nullable
as double?,aiExplanation: freezed == aiExplanation ? _self.aiExplanation : aiExplanation // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Incident].
extension IncidentPatterns on Incident {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Incident value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Incident() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Incident value)  $default,){
final _that = this;
switch (_that) {
case _Incident():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Incident value)?  $default,){
final _that = this;
switch (_that) {
case _Incident() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String authorId,  String categoryId,  String title,  String description,  double latitude,  double longitude,  int severity,  double priorityScore,  String status,  int confirmationCount,  DateTime createdAt,  String address,  String source,  List<Map<String, dynamic>> media,  Map<String, dynamic> priorityExplanation,  double? aiConfidence,  String? aiExplanation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Incident() when $default != null:
return $default(_that.id,_that.authorId,_that.categoryId,_that.title,_that.description,_that.latitude,_that.longitude,_that.severity,_that.priorityScore,_that.status,_that.confirmationCount,_that.createdAt,_that.address,_that.source,_that.media,_that.priorityExplanation,_that.aiConfidence,_that.aiExplanation);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String authorId,  String categoryId,  String title,  String description,  double latitude,  double longitude,  int severity,  double priorityScore,  String status,  int confirmationCount,  DateTime createdAt,  String address,  String source,  List<Map<String, dynamic>> media,  Map<String, dynamic> priorityExplanation,  double? aiConfidence,  String? aiExplanation)  $default,) {final _that = this;
switch (_that) {
case _Incident():
return $default(_that.id,_that.authorId,_that.categoryId,_that.title,_that.description,_that.latitude,_that.longitude,_that.severity,_that.priorityScore,_that.status,_that.confirmationCount,_that.createdAt,_that.address,_that.source,_that.media,_that.priorityExplanation,_that.aiConfidence,_that.aiExplanation);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String authorId,  String categoryId,  String title,  String description,  double latitude,  double longitude,  int severity,  double priorityScore,  String status,  int confirmationCount,  DateTime createdAt,  String address,  String source,  List<Map<String, dynamic>> media,  Map<String, dynamic> priorityExplanation,  double? aiConfidence,  String? aiExplanation)?  $default,) {final _that = this;
switch (_that) {
case _Incident() when $default != null:
return $default(_that.id,_that.authorId,_that.categoryId,_that.title,_that.description,_that.latitude,_that.longitude,_that.severity,_that.priorityScore,_that.status,_that.confirmationCount,_that.createdAt,_that.address,_that.source,_that.media,_that.priorityExplanation,_that.aiConfidence,_that.aiExplanation);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _Incident implements Incident {
  const _Incident({required this.id, required this.authorId, required this.categoryId, required this.title, required this.description, required this.latitude, required this.longitude, required this.severity, required this.priorityScore, required this.status, required this.confirmationCount, required this.createdAt, this.address = '', this.source = 'citizen', final  List<Map<String, dynamic>> media = const [], final  Map<String, dynamic> priorityExplanation = const {}, this.aiConfidence, this.aiExplanation}): _media = media,_priorityExplanation = priorityExplanation;
  factory _Incident.fromJson(Map<String, dynamic> json) => _$IncidentFromJson(json);

@override final  String id;
@override final  String authorId;
@override final  String categoryId;
@override final  String title;
@override final  String description;
@override final  double latitude;
@override final  double longitude;
@override final  int severity;
@override final  double priorityScore;
@override final  String status;
@override final  int confirmationCount;
@override final  DateTime createdAt;
@override@JsonKey() final  String address;
@override@JsonKey() final  String source;
 final  List<Map<String, dynamic>> _media;
@override@JsonKey() List<Map<String, dynamic>> get media {
  if (_media is EqualUnmodifiableListView) return _media;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_media);
}

 final  Map<String, dynamic> _priorityExplanation;
@override@JsonKey() Map<String, dynamic> get priorityExplanation {
  if (_priorityExplanation is EqualUnmodifiableMapView) return _priorityExplanation;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_priorityExplanation);
}

@override final  double? aiConfidence;
@override final  String? aiExplanation;

/// Create a copy of Incident
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IncidentCopyWith<_Incident> get copyWith => __$IncidentCopyWithImpl<_Incident>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IncidentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Incident&&(identical(other.id, id) || other.id == id)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.priorityScore, priorityScore) || other.priorityScore == priorityScore)&&(identical(other.status, status) || other.status == status)&&(identical(other.confirmationCount, confirmationCount) || other.confirmationCount == confirmationCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.address, address) || other.address == address)&&(identical(other.source, source) || other.source == source)&&const DeepCollectionEquality().equals(other._media, _media)&&const DeepCollectionEquality().equals(other._priorityExplanation, _priorityExplanation)&&(identical(other.aiConfidence, aiConfidence) || other.aiConfidence == aiConfidence)&&(identical(other.aiExplanation, aiExplanation) || other.aiExplanation == aiExplanation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,authorId,categoryId,title,description,latitude,longitude,severity,priorityScore,status,confirmationCount,createdAt,address,source,const DeepCollectionEquality().hash(_media),const DeepCollectionEquality().hash(_priorityExplanation),aiConfidence,aiExplanation);

@override
String toString() {
  return 'Incident(id: $id, authorId: $authorId, categoryId: $categoryId, title: $title, description: $description, latitude: $latitude, longitude: $longitude, severity: $severity, priorityScore: $priorityScore, status: $status, confirmationCount: $confirmationCount, createdAt: $createdAt, address: $address, source: $source, media: $media, priorityExplanation: $priorityExplanation, aiConfidence: $aiConfidence, aiExplanation: $aiExplanation)';
}


}

/// @nodoc
abstract mixin class _$IncidentCopyWith<$Res> implements $IncidentCopyWith<$Res> {
  factory _$IncidentCopyWith(_Incident value, $Res Function(_Incident) _then) = __$IncidentCopyWithImpl;
@override @useResult
$Res call({
 String id, String authorId, String categoryId, String title, String description, double latitude, double longitude, int severity, double priorityScore, String status, int confirmationCount, DateTime createdAt, String address, String source, List<Map<String, dynamic>> media, Map<String, dynamic> priorityExplanation, double? aiConfidence, String? aiExplanation
});




}
/// @nodoc
class __$IncidentCopyWithImpl<$Res>
    implements _$IncidentCopyWith<$Res> {
  __$IncidentCopyWithImpl(this._self, this._then);

  final _Incident _self;
  final $Res Function(_Incident) _then;

/// Create a copy of Incident
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? authorId = null,Object? categoryId = null,Object? title = null,Object? description = null,Object? latitude = null,Object? longitude = null,Object? severity = null,Object? priorityScore = null,Object? status = null,Object? confirmationCount = null,Object? createdAt = null,Object? address = null,Object? source = null,Object? media = null,Object? priorityExplanation = null,Object? aiConfidence = freezed,Object? aiExplanation = freezed,}) {
  return _then(_Incident(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,authorId: null == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as int,priorityScore: null == priorityScore ? _self.priorityScore : priorityScore // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,confirmationCount: null == confirmationCount ? _self.confirmationCount : confirmationCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,media: null == media ? _self._media : media // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,priorityExplanation: null == priorityExplanation ? _self._priorityExplanation : priorityExplanation // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,aiConfidence: freezed == aiConfidence ? _self.aiConfidence : aiConfidence // ignore: cast_nullable_to_non_nullable
as double?,aiExplanation: freezed == aiExplanation ? _self.aiExplanation : aiExplanation // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$IncidentDraft {

 String get key; String? get photoPath; String? get photoBase64; String? get uploadId; double? get latitude; double? get longitude; String get description; String get title; String get categoryId; int get severity; String get address; int get step; bool get reviewed; bool get cloudConsent; bool get waitingToSend; String get audioPath; String? get audioUploadId; Map<String, dynamic>? get analysis; Map<String, dynamic>? get pendingPayload; String? get publicationError;
/// Create a copy of IncidentDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IncidentDraftCopyWith<IncidentDraft> get copyWith => _$IncidentDraftCopyWithImpl<IncidentDraft>(this as IncidentDraft, _$identity);

  /// Serializes this IncidentDraft to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IncidentDraft&&(identical(other.key, key) || other.key == key)&&(identical(other.photoPath, photoPath) || other.photoPath == photoPath)&&(identical(other.photoBase64, photoBase64) || other.photoBase64 == photoBase64)&&(identical(other.uploadId, uploadId) || other.uploadId == uploadId)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.description, description) || other.description == description)&&(identical(other.title, title) || other.title == title)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.address, address) || other.address == address)&&(identical(other.step, step) || other.step == step)&&(identical(other.reviewed, reviewed) || other.reviewed == reviewed)&&(identical(other.cloudConsent, cloudConsent) || other.cloudConsent == cloudConsent)&&(identical(other.waitingToSend, waitingToSend) || other.waitingToSend == waitingToSend)&&(identical(other.audioPath, audioPath) || other.audioPath == audioPath)&&(identical(other.audioUploadId, audioUploadId) || other.audioUploadId == audioUploadId)&&const DeepCollectionEquality().equals(other.analysis, analysis)&&const DeepCollectionEquality().equals(other.pendingPayload, pendingPayload)&&(identical(other.publicationError, publicationError) || other.publicationError == publicationError));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,key,photoPath,photoBase64,uploadId,latitude,longitude,description,title,categoryId,severity,address,step,reviewed,cloudConsent,waitingToSend,audioPath,audioUploadId,const DeepCollectionEquality().hash(analysis),const DeepCollectionEquality().hash(pendingPayload),publicationError]);

@override
String toString() {
  return 'IncidentDraft(key: $key, photoPath: $photoPath, photoBase64: $photoBase64, uploadId: $uploadId, latitude: $latitude, longitude: $longitude, description: $description, title: $title, categoryId: $categoryId, severity: $severity, address: $address, step: $step, reviewed: $reviewed, cloudConsent: $cloudConsent, waitingToSend: $waitingToSend, audioPath: $audioPath, audioUploadId: $audioUploadId, analysis: $analysis, pendingPayload: $pendingPayload, publicationError: $publicationError)';
}


}

/// @nodoc
abstract mixin class $IncidentDraftCopyWith<$Res>  {
  factory $IncidentDraftCopyWith(IncidentDraft value, $Res Function(IncidentDraft) _then) = _$IncidentDraftCopyWithImpl;
@useResult
$Res call({
 String key, String? photoPath, String? photoBase64, String? uploadId, double? latitude, double? longitude, String description, String title, String categoryId, int severity, String address, int step, bool reviewed, bool cloudConsent, bool waitingToSend, String audioPath, String? audioUploadId, Map<String, dynamic>? analysis, Map<String, dynamic>? pendingPayload, String? publicationError
});




}
/// @nodoc
class _$IncidentDraftCopyWithImpl<$Res>
    implements $IncidentDraftCopyWith<$Res> {
  _$IncidentDraftCopyWithImpl(this._self, this._then);

  final IncidentDraft _self;
  final $Res Function(IncidentDraft) _then;

/// Create a copy of IncidentDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? photoPath = freezed,Object? photoBase64 = freezed,Object? uploadId = freezed,Object? latitude = freezed,Object? longitude = freezed,Object? description = null,Object? title = null,Object? categoryId = null,Object? severity = null,Object? address = null,Object? step = null,Object? reviewed = null,Object? cloudConsent = null,Object? waitingToSend = null,Object? audioPath = null,Object? audioUploadId = freezed,Object? analysis = freezed,Object? pendingPayload = freezed,Object? publicationError = freezed,}) {
  return _then(_self.copyWith(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,photoPath: freezed == photoPath ? _self.photoPath : photoPath // ignore: cast_nullable_to_non_nullable
as String?,photoBase64: freezed == photoBase64 ? _self.photoBase64 : photoBase64 // ignore: cast_nullable_to_non_nullable
as String?,uploadId: freezed == uploadId ? _self.uploadId : uploadId // ignore: cast_nullable_to_non_nullable
as String?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as int,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as int,reviewed: null == reviewed ? _self.reviewed : reviewed // ignore: cast_nullable_to_non_nullable
as bool,cloudConsent: null == cloudConsent ? _self.cloudConsent : cloudConsent // ignore: cast_nullable_to_non_nullable
as bool,waitingToSend: null == waitingToSend ? _self.waitingToSend : waitingToSend // ignore: cast_nullable_to_non_nullable
as bool,audioPath: null == audioPath ? _self.audioPath : audioPath // ignore: cast_nullable_to_non_nullable
as String,audioUploadId: freezed == audioUploadId ? _self.audioUploadId : audioUploadId // ignore: cast_nullable_to_non_nullable
as String?,analysis: freezed == analysis ? _self.analysis : analysis // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,pendingPayload: freezed == pendingPayload ? _self.pendingPayload : pendingPayload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,publicationError: freezed == publicationError ? _self.publicationError : publicationError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [IncidentDraft].
extension IncidentDraftPatterns on IncidentDraft {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IncidentDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IncidentDraft() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IncidentDraft value)  $default,){
final _that = this;
switch (_that) {
case _IncidentDraft():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IncidentDraft value)?  $default,){
final _that = this;
switch (_that) {
case _IncidentDraft() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  String? photoPath,  String? photoBase64,  String? uploadId,  double? latitude,  double? longitude,  String description,  String title,  String categoryId,  int severity,  String address,  int step,  bool reviewed,  bool cloudConsent,  bool waitingToSend,  String audioPath,  String? audioUploadId,  Map<String, dynamic>? analysis,  Map<String, dynamic>? pendingPayload,  String? publicationError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IncidentDraft() when $default != null:
return $default(_that.key,_that.photoPath,_that.photoBase64,_that.uploadId,_that.latitude,_that.longitude,_that.description,_that.title,_that.categoryId,_that.severity,_that.address,_that.step,_that.reviewed,_that.cloudConsent,_that.waitingToSend,_that.audioPath,_that.audioUploadId,_that.analysis,_that.pendingPayload,_that.publicationError);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  String? photoPath,  String? photoBase64,  String? uploadId,  double? latitude,  double? longitude,  String description,  String title,  String categoryId,  int severity,  String address,  int step,  bool reviewed,  bool cloudConsent,  bool waitingToSend,  String audioPath,  String? audioUploadId,  Map<String, dynamic>? analysis,  Map<String, dynamic>? pendingPayload,  String? publicationError)  $default,) {final _that = this;
switch (_that) {
case _IncidentDraft():
return $default(_that.key,_that.photoPath,_that.photoBase64,_that.uploadId,_that.latitude,_that.longitude,_that.description,_that.title,_that.categoryId,_that.severity,_that.address,_that.step,_that.reviewed,_that.cloudConsent,_that.waitingToSend,_that.audioPath,_that.audioUploadId,_that.analysis,_that.pendingPayload,_that.publicationError);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  String? photoPath,  String? photoBase64,  String? uploadId,  double? latitude,  double? longitude,  String description,  String title,  String categoryId,  int severity,  String address,  int step,  bool reviewed,  bool cloudConsent,  bool waitingToSend,  String audioPath,  String? audioUploadId,  Map<String, dynamic>? analysis,  Map<String, dynamic>? pendingPayload,  String? publicationError)?  $default,) {final _that = this;
switch (_that) {
case _IncidentDraft() when $default != null:
return $default(_that.key,_that.photoPath,_that.photoBase64,_that.uploadId,_that.latitude,_that.longitude,_that.description,_that.title,_that.categoryId,_that.severity,_that.address,_that.step,_that.reviewed,_that.cloudConsent,_that.waitingToSend,_that.audioPath,_that.audioUploadId,_that.analysis,_that.pendingPayload,_that.publicationError);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IncidentDraft implements IncidentDraft {
  const _IncidentDraft({required this.key, this.photoPath, this.photoBase64, this.uploadId, this.latitude, this.longitude, this.description = '', this.title = '', this.categoryId = 'other', this.severity = 3, this.address = '', this.step = 0, this.reviewed = false, this.cloudConsent = false, this.waitingToSend = false, this.audioPath = '', this.audioUploadId, final  Map<String, dynamic>? analysis, final  Map<String, dynamic>? pendingPayload, this.publicationError}): _analysis = analysis,_pendingPayload = pendingPayload;
  factory _IncidentDraft.fromJson(Map<String, dynamic> json) => _$IncidentDraftFromJson(json);

@override final  String key;
@override final  String? photoPath;
@override final  String? photoBase64;
@override final  String? uploadId;
@override final  double? latitude;
@override final  double? longitude;
@override@JsonKey() final  String description;
@override@JsonKey() final  String title;
@override@JsonKey() final  String categoryId;
@override@JsonKey() final  int severity;
@override@JsonKey() final  String address;
@override@JsonKey() final  int step;
@override@JsonKey() final  bool reviewed;
@override@JsonKey() final  bool cloudConsent;
@override@JsonKey() final  bool waitingToSend;
@override@JsonKey() final  String audioPath;
@override final  String? audioUploadId;
 final  Map<String, dynamic>? _analysis;
@override Map<String, dynamic>? get analysis {
  final value = _analysis;
  if (value == null) return null;
  if (_analysis is EqualUnmodifiableMapView) return _analysis;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, dynamic>? _pendingPayload;
@override Map<String, dynamic>? get pendingPayload {
  final value = _pendingPayload;
  if (value == null) return null;
  if (_pendingPayload is EqualUnmodifiableMapView) return _pendingPayload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  String? publicationError;

/// Create a copy of IncidentDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IncidentDraftCopyWith<_IncidentDraft> get copyWith => __$IncidentDraftCopyWithImpl<_IncidentDraft>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IncidentDraftToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IncidentDraft&&(identical(other.key, key) || other.key == key)&&(identical(other.photoPath, photoPath) || other.photoPath == photoPath)&&(identical(other.photoBase64, photoBase64) || other.photoBase64 == photoBase64)&&(identical(other.uploadId, uploadId) || other.uploadId == uploadId)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.description, description) || other.description == description)&&(identical(other.title, title) || other.title == title)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.address, address) || other.address == address)&&(identical(other.step, step) || other.step == step)&&(identical(other.reviewed, reviewed) || other.reviewed == reviewed)&&(identical(other.cloudConsent, cloudConsent) || other.cloudConsent == cloudConsent)&&(identical(other.waitingToSend, waitingToSend) || other.waitingToSend == waitingToSend)&&(identical(other.audioPath, audioPath) || other.audioPath == audioPath)&&(identical(other.audioUploadId, audioUploadId) || other.audioUploadId == audioUploadId)&&const DeepCollectionEquality().equals(other._analysis, _analysis)&&const DeepCollectionEquality().equals(other._pendingPayload, _pendingPayload)&&(identical(other.publicationError, publicationError) || other.publicationError == publicationError));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,key,photoPath,photoBase64,uploadId,latitude,longitude,description,title,categoryId,severity,address,step,reviewed,cloudConsent,waitingToSend,audioPath,audioUploadId,const DeepCollectionEquality().hash(_analysis),const DeepCollectionEquality().hash(_pendingPayload),publicationError]);

@override
String toString() {
  return 'IncidentDraft(key: $key, photoPath: $photoPath, photoBase64: $photoBase64, uploadId: $uploadId, latitude: $latitude, longitude: $longitude, description: $description, title: $title, categoryId: $categoryId, severity: $severity, address: $address, step: $step, reviewed: $reviewed, cloudConsent: $cloudConsent, waitingToSend: $waitingToSend, audioPath: $audioPath, audioUploadId: $audioUploadId, analysis: $analysis, pendingPayload: $pendingPayload, publicationError: $publicationError)';
}


}

/// @nodoc
abstract mixin class _$IncidentDraftCopyWith<$Res> implements $IncidentDraftCopyWith<$Res> {
  factory _$IncidentDraftCopyWith(_IncidentDraft value, $Res Function(_IncidentDraft) _then) = __$IncidentDraftCopyWithImpl;
@override @useResult
$Res call({
 String key, String? photoPath, String? photoBase64, String? uploadId, double? latitude, double? longitude, String description, String title, String categoryId, int severity, String address, int step, bool reviewed, bool cloudConsent, bool waitingToSend, String audioPath, String? audioUploadId, Map<String, dynamic>? analysis, Map<String, dynamic>? pendingPayload, String? publicationError
});




}
/// @nodoc
class __$IncidentDraftCopyWithImpl<$Res>
    implements _$IncidentDraftCopyWith<$Res> {
  __$IncidentDraftCopyWithImpl(this._self, this._then);

  final _IncidentDraft _self;
  final $Res Function(_IncidentDraft) _then;

/// Create a copy of IncidentDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? photoPath = freezed,Object? photoBase64 = freezed,Object? uploadId = freezed,Object? latitude = freezed,Object? longitude = freezed,Object? description = null,Object? title = null,Object? categoryId = null,Object? severity = null,Object? address = null,Object? step = null,Object? reviewed = null,Object? cloudConsent = null,Object? waitingToSend = null,Object? audioPath = null,Object? audioUploadId = freezed,Object? analysis = freezed,Object? pendingPayload = freezed,Object? publicationError = freezed,}) {
  return _then(_IncidentDraft(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,photoPath: freezed == photoPath ? _self.photoPath : photoPath // ignore: cast_nullable_to_non_nullable
as String?,photoBase64: freezed == photoBase64 ? _self.photoBase64 : photoBase64 // ignore: cast_nullable_to_non_nullable
as String?,uploadId: freezed == uploadId ? _self.uploadId : uploadId // ignore: cast_nullable_to_non_nullable
as String?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as int,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as int,reviewed: null == reviewed ? _self.reviewed : reviewed // ignore: cast_nullable_to_non_nullable
as bool,cloudConsent: null == cloudConsent ? _self.cloudConsent : cloudConsent // ignore: cast_nullable_to_non_nullable
as bool,waitingToSend: null == waitingToSend ? _self.waitingToSend : waitingToSend // ignore: cast_nullable_to_non_nullable
as bool,audioPath: null == audioPath ? _self.audioPath : audioPath // ignore: cast_nullable_to_non_nullable
as String,audioUploadId: freezed == audioUploadId ? _self.audioUploadId : audioUploadId // ignore: cast_nullable_to_non_nullable
as String?,analysis: freezed == analysis ? _self._analysis : analysis // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,pendingPayload: freezed == pendingPayload ? _self._pendingPayload : pendingPayload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,publicationError: freezed == publicationError ? _self.publicationError : publicationError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
