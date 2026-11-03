// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recent_visit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecentVisit {

 String get id; String get workspaceId; EntityType get entityType; String get entityId;@EpochMillisConverter() DateTime get visitedAt;
/// Create a copy of RecentVisit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecentVisitCopyWith<RecentVisit> get copyWith => _$RecentVisitCopyWithImpl<RecentVisit>(this as RecentVisit, _$identity);

  /// Serializes this RecentVisit to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RecentVisit;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecentVisit&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.workspaceId, _this.workspaceId) || other.workspaceId == _this.workspaceId)&&(identical(other.entityType, _this.entityType) || other.entityType == _this.entityType)&&(identical(other.entityId, _this.entityId) || other.entityId == _this.entityId)&&(identical(other.visitedAt, _this.visitedAt) || other.visitedAt == _this.visitedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RecentVisit;
  return Object.hash(runtimeType,_this.id,_this.workspaceId,_this.entityType,_this.entityId,_this.visitedAt);
}

@override
String toString() {
  final _this = this as RecentVisit;
  return 'RecentVisit(id: ${_this.id}, workspaceId: ${_this.workspaceId}, entityType: ${_this.entityType}, entityId: ${_this.entityId}, visitedAt: ${_this.visitedAt})';
}


}

/// @nodoc
abstract mixin class $RecentVisitCopyWith<$Res>  {
  factory $RecentVisitCopyWith(RecentVisit value, $Res Function(RecentVisit) _then) = _$RecentVisitCopyWithImpl;
@useResult
$Res call({
 String id, String workspaceId, EntityType entityType, String entityId,@EpochMillisConverter() DateTime visitedAt
});




}
/// @nodoc
class _$RecentVisitCopyWithImpl<$Res>
    implements $RecentVisitCopyWith<$Res> {
  _$RecentVisitCopyWithImpl(this._self, this._then);

  final RecentVisit _self;
  final $Res Function(RecentVisit) _then;

/// Create a copy of RecentVisit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? workspaceId = null,Object? entityType = null,Object? entityId = null,Object? visitedAt = null,}) {
  return _then(RecentVisit(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as EntityType,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,visitedAt: null == visitedAt ? _self.visitedAt : visitedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [RecentVisit].
extension RecentVisitPatterns on RecentVisit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecentVisit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecentVisit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecentVisit value)  $default,){
final _that = this;
switch (_that) {
case _RecentVisit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecentVisit value)?  $default,){
final _that = this;
switch (_that) {
case _RecentVisit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String workspaceId,  EntityType entityType,  String entityId, @EpochMillisConverter()  DateTime visitedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecentVisit() when $default != null:
return $default(_that.id,_that.workspaceId,_that.entityType,_that.entityId,_that.visitedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String workspaceId,  EntityType entityType,  String entityId, @EpochMillisConverter()  DateTime visitedAt)  $default,) {final _that = this;
switch (_that) {
case _RecentVisit():
return $default(_that.id,_that.workspaceId,_that.entityType,_that.entityId,_that.visitedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String workspaceId,  EntityType entityType,  String entityId, @EpochMillisConverter()  DateTime visitedAt)?  $default,) {final _that = this;
switch (_that) {
case _RecentVisit() when $default != null:
return $default(_that.id,_that.workspaceId,_that.entityType,_that.entityId,_that.visitedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecentVisit implements RecentVisit {
  const _RecentVisit({required this.id, required this.workspaceId, required this.entityType, required this.entityId, @EpochMillisConverter() required this.visitedAt});
  factory _RecentVisit.fromJson(Map<String, dynamic> json) => _$RecentVisitFromJson(json);

@override final  String id;
@override final  String workspaceId;
@override final  EntityType entityType;
@override final  String entityId;
@override@EpochMillisConverter() final  DateTime visitedAt;

/// Create a copy of RecentVisit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecentVisitCopyWith<_RecentVisit> get copyWith => __$RecentVisitCopyWithImpl<_RecentVisit>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecentVisitToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecentVisit&&(identical(other.id, id) || other.id == id)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.visitedAt, visitedAt) || other.visitedAt == visitedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,workspaceId,entityType,entityId,visitedAt);
}

@override
String toString() {
    return 'RecentVisit(id: $id, workspaceId: $workspaceId, entityType: $entityType, entityId: $entityId, visitedAt: $visitedAt)';
}


}

/// @nodoc
abstract mixin class _$RecentVisitCopyWith<$Res> implements $RecentVisitCopyWith<$Res> {
  factory _$RecentVisitCopyWith(_RecentVisit value, $Res Function(_RecentVisit) _then) = __$RecentVisitCopyWithImpl;
@override @useResult
$Res call({
 String id, String workspaceId, EntityType entityType, String entityId,@EpochMillisConverter() DateTime visitedAt
});




}
/// @nodoc
class __$RecentVisitCopyWithImpl<$Res>
    implements _$RecentVisitCopyWith<$Res> {
  __$RecentVisitCopyWithImpl(this._self, this._then);

  final _RecentVisit _self;
  final $Res Function(_RecentVisit) _then;

/// Create a copy of RecentVisit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? workspaceId = null,Object? entityType = null,Object? entityId = null,Object? visitedAt = null,}) {
  return _then(_RecentVisit(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as EntityType,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,visitedAt: null == visitedAt ? _self.visitedAt : visitedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
