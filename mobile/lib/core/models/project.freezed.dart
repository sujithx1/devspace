// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Project {

 String get id; String get workspaceId; String get name; String get description; ProjectStatus get status; Priority get priority; ProjectColor get color; String? get startDate; String? get dueDate;@EpochMillisConverter() DateTime get createdAt;@EpochMillisConverter() DateTime get updatedAt;/// Derived from linked tasks when read from storage; not persisted.
@JsonKey(includeFromJson: false, includeToJson: false) int get taskCount;@JsonKey(includeFromJson: false, includeToJson: false) int get completedTaskCount;
/// Create a copy of Project
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectCopyWith<Project> get copyWith => _$ProjectCopyWithImpl<Project>(this as Project, _$identity);

  /// Serializes this Project to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Project;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Project&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.workspaceId, _this.workspaceId) || other.workspaceId == _this.workspaceId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.priority, _this.priority) || other.priority == _this.priority)&&(identical(other.color, _this.color) || other.color == _this.color)&&(identical(other.startDate, _this.startDate) || other.startDate == _this.startDate)&&(identical(other.dueDate, _this.dueDate) || other.dueDate == _this.dueDate)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.taskCount, _this.taskCount) || other.taskCount == _this.taskCount)&&(identical(other.completedTaskCount, _this.completedTaskCount) || other.completedTaskCount == _this.completedTaskCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Project;
  return Object.hash(runtimeType,_this.id,_this.workspaceId,_this.name,_this.description,_this.status,_this.priority,_this.color,_this.startDate,_this.dueDate,_this.createdAt,_this.updatedAt,_this.taskCount,_this.completedTaskCount);
}

@override
String toString() {
  final _this = this as Project;
  return 'Project(id: ${_this.id}, workspaceId: ${_this.workspaceId}, name: ${_this.name}, description: ${_this.description}, status: ${_this.status}, priority: ${_this.priority}, color: ${_this.color}, startDate: ${_this.startDate}, dueDate: ${_this.dueDate}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, taskCount: ${_this.taskCount}, completedTaskCount: ${_this.completedTaskCount})';
}


}

/// @nodoc
abstract mixin class $ProjectCopyWith<$Res>  {
  factory $ProjectCopyWith(Project value, $Res Function(Project) _then) = _$ProjectCopyWithImpl;
@useResult
$Res call({
 String id, String workspaceId, String name, String description, ProjectStatus status, Priority priority, ProjectColor color, String? startDate, String? dueDate,@EpochMillisConverter() DateTime createdAt,@EpochMillisConverter() DateTime updatedAt,@JsonKey(includeFromJson: false, includeToJson: false) int taskCount,@JsonKey(includeFromJson: false, includeToJson: false) int completedTaskCount
});




}
/// @nodoc
class _$ProjectCopyWithImpl<$Res>
    implements $ProjectCopyWith<$Res> {
  _$ProjectCopyWithImpl(this._self, this._then);

  final Project _self;
  final $Res Function(Project) _then;

/// Create a copy of Project
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? workspaceId = null,Object? name = null,Object? description = null,Object? status = null,Object? priority = null,Object? color = null,Object? startDate = freezed,Object? dueDate = freezed,Object? createdAt = null,Object? updatedAt = null,Object? taskCount = null,Object? completedTaskCount = null,}) {
  return _then(Project(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProjectStatus,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as Priority,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as ProjectColor,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String?,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,taskCount: null == taskCount ? _self.taskCount : taskCount // ignore: cast_nullable_to_non_nullable
as int,completedTaskCount: null == completedTaskCount ? _self.completedTaskCount : completedTaskCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Project].
extension ProjectPatterns on Project {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Project value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Project() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Project value)  $default,){
final _that = this;
switch (_that) {
case _Project():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Project value)?  $default,){
final _that = this;
switch (_that) {
case _Project() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String workspaceId,  String name,  String description,  ProjectStatus status,  Priority priority,  ProjectColor color,  String? startDate,  String? dueDate, @EpochMillisConverter()  DateTime createdAt, @EpochMillisConverter()  DateTime updatedAt, @JsonKey(includeFromJson: false, includeToJson: false)  int taskCount, @JsonKey(includeFromJson: false, includeToJson: false)  int completedTaskCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Project() when $default != null:
return $default(_that.id,_that.workspaceId,_that.name,_that.description,_that.status,_that.priority,_that.color,_that.startDate,_that.dueDate,_that.createdAt,_that.updatedAt,_that.taskCount,_that.completedTaskCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String workspaceId,  String name,  String description,  ProjectStatus status,  Priority priority,  ProjectColor color,  String? startDate,  String? dueDate, @EpochMillisConverter()  DateTime createdAt, @EpochMillisConverter()  DateTime updatedAt, @JsonKey(includeFromJson: false, includeToJson: false)  int taskCount, @JsonKey(includeFromJson: false, includeToJson: false)  int completedTaskCount)  $default,) {final _that = this;
switch (_that) {
case _Project():
return $default(_that.id,_that.workspaceId,_that.name,_that.description,_that.status,_that.priority,_that.color,_that.startDate,_that.dueDate,_that.createdAt,_that.updatedAt,_that.taskCount,_that.completedTaskCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String workspaceId,  String name,  String description,  ProjectStatus status,  Priority priority,  ProjectColor color,  String? startDate,  String? dueDate, @EpochMillisConverter()  DateTime createdAt, @EpochMillisConverter()  DateTime updatedAt, @JsonKey(includeFromJson: false, includeToJson: false)  int taskCount, @JsonKey(includeFromJson: false, includeToJson: false)  int completedTaskCount)?  $default,) {final _that = this;
switch (_that) {
case _Project() when $default != null:
return $default(_that.id,_that.workspaceId,_that.name,_that.description,_that.status,_that.priority,_that.color,_that.startDate,_that.dueDate,_that.createdAt,_that.updatedAt,_that.taskCount,_that.completedTaskCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Project extends Project {
  const _Project({required this.id, required this.workspaceId, required this.name, this.description = '', this.status = ProjectStatus.planning, this.priority = Priority.medium, this.color = ProjectColor.indigo, this.startDate, this.dueDate, @EpochMillisConverter() required this.createdAt, @EpochMillisConverter() required this.updatedAt, @JsonKey(includeFromJson: false, includeToJson: false) this.taskCount = 0, @JsonKey(includeFromJson: false, includeToJson: false) this.completedTaskCount = 0}): super._();
  factory _Project.fromJson(Map<String, dynamic> json) => _$ProjectFromJson(json);

@override final  String id;
@override final  String workspaceId;
@override final  String name;
@override@JsonKey() final  String description;
@override@JsonKey() final  ProjectStatus status;
@override@JsonKey() final  Priority priority;
@override@JsonKey() final  ProjectColor color;
@override final  String? startDate;
@override final  String? dueDate;
@override@EpochMillisConverter() final  DateTime createdAt;
@override@EpochMillisConverter() final  DateTime updatedAt;
/// Derived from linked tasks when read from storage; not persisted.
@override@JsonKey(includeFromJson: false, includeToJson: false) final  int taskCount;
@override@JsonKey(includeFromJson: false, includeToJson: false) final  int completedTaskCount;

/// Create a copy of Project
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectCopyWith<_Project> get copyWith => __$ProjectCopyWithImpl<_Project>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Project&&(identical(other.id, id) || other.id == id)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.status, status) || other.status == status)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.color, color) || other.color == color)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.taskCount, taskCount) || other.taskCount == taskCount)&&(identical(other.completedTaskCount, completedTaskCount) || other.completedTaskCount == completedTaskCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,workspaceId,name,description,status,priority,color,startDate,dueDate,createdAt,updatedAt,taskCount,completedTaskCount);
}

@override
String toString() {
    return 'Project(id: $id, workspaceId: $workspaceId, name: $name, description: $description, status: $status, priority: $priority, color: $color, startDate: $startDate, dueDate: $dueDate, createdAt: $createdAt, updatedAt: $updatedAt, taskCount: $taskCount, completedTaskCount: $completedTaskCount)';
}


}

/// @nodoc
abstract mixin class _$ProjectCopyWith<$Res> implements $ProjectCopyWith<$Res> {
  factory _$ProjectCopyWith(_Project value, $Res Function(_Project) _then) = __$ProjectCopyWithImpl;
@override @useResult
$Res call({
 String id, String workspaceId, String name, String description, ProjectStatus status, Priority priority, ProjectColor color, String? startDate, String? dueDate,@EpochMillisConverter() DateTime createdAt,@EpochMillisConverter() DateTime updatedAt,@JsonKey(includeFromJson: false, includeToJson: false) int taskCount,@JsonKey(includeFromJson: false, includeToJson: false) int completedTaskCount
});




}
/// @nodoc
class __$ProjectCopyWithImpl<$Res>
    implements _$ProjectCopyWith<$Res> {
  __$ProjectCopyWithImpl(this._self, this._then);

  final _Project _self;
  final $Res Function(_Project) _then;

/// Create a copy of Project
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? workspaceId = null,Object? name = null,Object? description = null,Object? status = null,Object? priority = null,Object? color = null,Object? startDate = freezed,Object? dueDate = freezed,Object? createdAt = null,Object? updatedAt = null,Object? taskCount = null,Object? completedTaskCount = null,}) {
  return _then(_Project(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProjectStatus,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as Priority,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as ProjectColor,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String?,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,taskCount: null == taskCount ? _self.taskCount : taskCount // ignore: cast_nullable_to_non_nullable
as int,completedTaskCount: null == completedTaskCount ? _self.completedTaskCount : completedTaskCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
