// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workspace.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Workspace {

 String get id; String get name; String get icon; WorkspaceType get type;@EpochMillisConverter() DateTime get createdAt;@EpochMillisConverter() DateTime get updatedAt;
/// Create a copy of Workspace
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkspaceCopyWith<Workspace> get copyWith => _$WorkspaceCopyWithImpl<Workspace>(this as Workspace, _$identity);

  /// Serializes this Workspace to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Workspace;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Workspace&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.icon, _this.icon) || other.icon == _this.icon)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Workspace;
  return Object.hash(runtimeType,_this.id,_this.name,_this.icon,_this.type,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as Workspace;
  return 'Workspace(id: ${_this.id}, name: ${_this.name}, icon: ${_this.icon}, type: ${_this.type}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $WorkspaceCopyWith<$Res>  {
  factory $WorkspaceCopyWith(Workspace value, $Res Function(Workspace) _then) = _$WorkspaceCopyWithImpl;
@useResult
$Res call({
 String id, String name, String icon, WorkspaceType type,@EpochMillisConverter() DateTime createdAt,@EpochMillisConverter() DateTime updatedAt
});




}
/// @nodoc
class _$WorkspaceCopyWithImpl<$Res>
    implements $WorkspaceCopyWith<$Res> {
  _$WorkspaceCopyWithImpl(this._self, this._then);

  final Workspace _self;
  final $Res Function(Workspace) _then;

/// Create a copy of Workspace
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? icon = null,Object? type = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(Workspace(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as WorkspaceType,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Workspace].
extension WorkspacePatterns on Workspace {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Workspace value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Workspace() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Workspace value)  $default,){
final _that = this;
switch (_that) {
case _Workspace():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Workspace value)?  $default,){
final _that = this;
switch (_that) {
case _Workspace() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String icon,  WorkspaceType type, @EpochMillisConverter()  DateTime createdAt, @EpochMillisConverter()  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Workspace() when $default != null:
return $default(_that.id,_that.name,_that.icon,_that.type,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String icon,  WorkspaceType type, @EpochMillisConverter()  DateTime createdAt, @EpochMillisConverter()  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Workspace():
return $default(_that.id,_that.name,_that.icon,_that.type,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String icon,  WorkspaceType type, @EpochMillisConverter()  DateTime createdAt, @EpochMillisConverter()  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Workspace() when $default != null:
return $default(_that.id,_that.name,_that.icon,_that.type,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Workspace implements Workspace {
  const _Workspace({required this.id, required this.name, this.icon = '🚀', this.type = WorkspaceType.personal, @EpochMillisConverter() required this.createdAt, @EpochMillisConverter() required this.updatedAt});
  factory _Workspace.fromJson(Map<String, dynamic> json) => _$WorkspaceFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  String icon;
@override@JsonKey() final  WorkspaceType type;
@override@EpochMillisConverter() final  DateTime createdAt;
@override@EpochMillisConverter() final  DateTime updatedAt;

/// Create a copy of Workspace
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkspaceCopyWith<_Workspace> get copyWith => __$WorkspaceCopyWithImpl<_Workspace>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkspaceToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Workspace&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.type, type) || other.type == type)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,icon,type,createdAt,updatedAt);
}

@override
String toString() {
    return 'Workspace(id: $id, name: $name, icon: $icon, type: $type, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$WorkspaceCopyWith<$Res> implements $WorkspaceCopyWith<$Res> {
  factory _$WorkspaceCopyWith(_Workspace value, $Res Function(_Workspace) _then) = __$WorkspaceCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String icon, WorkspaceType type,@EpochMillisConverter() DateTime createdAt,@EpochMillisConverter() DateTime updatedAt
});




}
/// @nodoc
class __$WorkspaceCopyWithImpl<$Res>
    implements _$WorkspaceCopyWith<$Res> {
  __$WorkspaceCopyWithImpl(this._self, this._then);

  final _Workspace _self;
  final $Res Function(_Workspace) _then;

/// Create a copy of Workspace
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? icon = null,Object? type = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Workspace(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as WorkspaceType,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$WorkspaceStats {

 int get tasks; int get openTasks; int get projects; int get notes; int get docs; int get drawings; int get folders;
/// Create a copy of WorkspaceStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkspaceStatsCopyWith<WorkspaceStats> get copyWith => _$WorkspaceStatsCopyWithImpl<WorkspaceStats>(this as WorkspaceStats, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as WorkspaceStats;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkspaceStats&&(identical(other.tasks, _this.tasks) || other.tasks == _this.tasks)&&(identical(other.openTasks, _this.openTasks) || other.openTasks == _this.openTasks)&&(identical(other.projects, _this.projects) || other.projects == _this.projects)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&(identical(other.docs, _this.docs) || other.docs == _this.docs)&&(identical(other.drawings, _this.drawings) || other.drawings == _this.drawings)&&(identical(other.folders, _this.folders) || other.folders == _this.folders));
}


@override
int get hashCode {
  final _this = this as WorkspaceStats;
  return Object.hash(runtimeType,_this.tasks,_this.openTasks,_this.projects,_this.notes,_this.docs,_this.drawings,_this.folders);
}

@override
String toString() {
  final _this = this as WorkspaceStats;
  return 'WorkspaceStats(tasks: ${_this.tasks}, openTasks: ${_this.openTasks}, projects: ${_this.projects}, notes: ${_this.notes}, docs: ${_this.docs}, drawings: ${_this.drawings}, folders: ${_this.folders})';
}


}

/// @nodoc
abstract mixin class $WorkspaceStatsCopyWith<$Res>  {
  factory $WorkspaceStatsCopyWith(WorkspaceStats value, $Res Function(WorkspaceStats) _then) = _$WorkspaceStatsCopyWithImpl;
@useResult
$Res call({
 int tasks, int openTasks, int projects, int notes, int docs, int drawings, int folders
});




}
/// @nodoc
class _$WorkspaceStatsCopyWithImpl<$Res>
    implements $WorkspaceStatsCopyWith<$Res> {
  _$WorkspaceStatsCopyWithImpl(this._self, this._then);

  final WorkspaceStats _self;
  final $Res Function(WorkspaceStats) _then;

/// Create a copy of WorkspaceStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tasks = null,Object? openTasks = null,Object? projects = null,Object? notes = null,Object? docs = null,Object? drawings = null,Object? folders = null,}) {
  return _then(WorkspaceStats(
tasks: null == tasks ? _self.tasks : tasks // ignore: cast_nullable_to_non_nullable
as int,openTasks: null == openTasks ? _self.openTasks : openTasks // ignore: cast_nullable_to_non_nullable
as int,projects: null == projects ? _self.projects : projects // ignore: cast_nullable_to_non_nullable
as int,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as int,docs: null == docs ? _self.docs : docs // ignore: cast_nullable_to_non_nullable
as int,drawings: null == drawings ? _self.drawings : drawings // ignore: cast_nullable_to_non_nullable
as int,folders: null == folders ? _self.folders : folders // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkspaceStats].
extension WorkspaceStatsPatterns on WorkspaceStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkspaceStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkspaceStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkspaceStats value)  $default,){
final _that = this;
switch (_that) {
case _WorkspaceStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkspaceStats value)?  $default,){
final _that = this;
switch (_that) {
case _WorkspaceStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int tasks,  int openTasks,  int projects,  int notes,  int docs,  int drawings,  int folders)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkspaceStats() when $default != null:
return $default(_that.tasks,_that.openTasks,_that.projects,_that.notes,_that.docs,_that.drawings,_that.folders);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int tasks,  int openTasks,  int projects,  int notes,  int docs,  int drawings,  int folders)  $default,) {final _that = this;
switch (_that) {
case _WorkspaceStats():
return $default(_that.tasks,_that.openTasks,_that.projects,_that.notes,_that.docs,_that.drawings,_that.folders);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int tasks,  int openTasks,  int projects,  int notes,  int docs,  int drawings,  int folders)?  $default,) {final _that = this;
switch (_that) {
case _WorkspaceStats() when $default != null:
return $default(_that.tasks,_that.openTasks,_that.projects,_that.notes,_that.docs,_that.drawings,_that.folders);case _:
  return null;

}
}

}

/// @nodoc


class _WorkspaceStats extends WorkspaceStats {
  const _WorkspaceStats({this.tasks = 0, this.openTasks = 0, this.projects = 0, this.notes = 0, this.docs = 0, this.drawings = 0, this.folders = 0}): super._();
  

@override@JsonKey() final  int tasks;
@override@JsonKey() final  int openTasks;
@override@JsonKey() final  int projects;
@override@JsonKey() final  int notes;
@override@JsonKey() final  int docs;
@override@JsonKey() final  int drawings;
@override@JsonKey() final  int folders;

/// Create a copy of WorkspaceStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkspaceStatsCopyWith<_WorkspaceStats> get copyWith => __$WorkspaceStatsCopyWithImpl<_WorkspaceStats>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkspaceStats&&(identical(other.tasks, tasks) || other.tasks == tasks)&&(identical(other.openTasks, openTasks) || other.openTasks == openTasks)&&(identical(other.projects, projects) || other.projects == projects)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.docs, docs) || other.docs == docs)&&(identical(other.drawings, drawings) || other.drawings == drawings)&&(identical(other.folders, folders) || other.folders == folders));
}


@override
int get hashCode {
    return Object.hash(runtimeType,tasks,openTasks,projects,notes,docs,drawings,folders);
}

@override
String toString() {
    return 'WorkspaceStats(tasks: $tasks, openTasks: $openTasks, projects: $projects, notes: $notes, docs: $docs, drawings: $drawings, folders: $folders)';
}


}

/// @nodoc
abstract mixin class _$WorkspaceStatsCopyWith<$Res> implements $WorkspaceStatsCopyWith<$Res> {
  factory _$WorkspaceStatsCopyWith(_WorkspaceStats value, $Res Function(_WorkspaceStats) _then) = __$WorkspaceStatsCopyWithImpl;
@override @useResult
$Res call({
 int tasks, int openTasks, int projects, int notes, int docs, int drawings, int folders
});




}
/// @nodoc
class __$WorkspaceStatsCopyWithImpl<$Res>
    implements _$WorkspaceStatsCopyWith<$Res> {
  __$WorkspaceStatsCopyWithImpl(this._self, this._then);

  final _WorkspaceStats _self;
  final $Res Function(_WorkspaceStats) _then;

/// Create a copy of WorkspaceStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tasks = null,Object? openTasks = null,Object? projects = null,Object? notes = null,Object? docs = null,Object? drawings = null,Object? folders = null,}) {
  return _then(_WorkspaceStats(
tasks: null == tasks ? _self.tasks : tasks // ignore: cast_nullable_to_non_nullable
as int,openTasks: null == openTasks ? _self.openTasks : openTasks // ignore: cast_nullable_to_non_nullable
as int,projects: null == projects ? _self.projects : projects // ignore: cast_nullable_to_non_nullable
as int,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as int,docs: null == docs ? _self.docs : docs // ignore: cast_nullable_to_non_nullable
as int,drawings: null == drawings ? _self.drawings : drawings // ignore: cast_nullable_to_non_nullable
as int,folders: null == folders ? _self.folders : folders // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
