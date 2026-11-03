// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Task {

 String get id; String get workspaceId; String? get projectId; String get title; String get description; TaskStatus get status; Priority get priority;/// `YYYY-MM-DD`, local calendar day.
 String? get dueDate;/// `HH:mm` on [dueDate].
 String? get dueTime; Recurrence? get recurrence; List<String> get tags;@JsonKey(name: 'order') double get sortOrder;@NullableEpochMillisConverter() DateTime? get completedAt;@EpochMillisConverter() DateTime get createdAt;@EpochMillisConverter() DateTime get updatedAt;/// Derived from the task's subtasks when read from storage; not persisted.
@JsonKey(includeFromJson: false, includeToJson: false) int get subtaskCount;@JsonKey(includeFromJson: false, includeToJson: false) int get subtasksDone;
/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskCopyWith<Task> get copyWith => _$TaskCopyWithImpl<Task>(this as Task, _$identity);

  /// Serializes this Task to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Task;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Task&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.workspaceId, _this.workspaceId) || other.workspaceId == _this.workspaceId)&&(identical(other.projectId, _this.projectId) || other.projectId == _this.projectId)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.priority, _this.priority) || other.priority == _this.priority)&&(identical(other.dueDate, _this.dueDate) || other.dueDate == _this.dueDate)&&(identical(other.dueTime, _this.dueTime) || other.dueTime == _this.dueTime)&&(identical(other.recurrence, _this.recurrence) || other.recurrence == _this.recurrence)&&const DeepCollectionEquality().equals(other.tags, _this.tags)&&(identical(other.sortOrder, _this.sortOrder) || other.sortOrder == _this.sortOrder)&&(identical(other.completedAt, _this.completedAt) || other.completedAt == _this.completedAt)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.subtaskCount, _this.subtaskCount) || other.subtaskCount == _this.subtaskCount)&&(identical(other.subtasksDone, _this.subtasksDone) || other.subtasksDone == _this.subtasksDone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Task;
  return Object.hash(runtimeType,_this.id,_this.workspaceId,_this.projectId,_this.title,_this.description,_this.status,_this.priority,_this.dueDate,_this.dueTime,_this.recurrence,const DeepCollectionEquality().hash(_this.tags),_this.sortOrder,_this.completedAt,_this.createdAt,_this.updatedAt,_this.subtaskCount,_this.subtasksDone);
}

@override
String toString() {
  final _this = this as Task;
  return 'Task(id: ${_this.id}, workspaceId: ${_this.workspaceId}, projectId: ${_this.projectId}, title: ${_this.title}, description: ${_this.description}, status: ${_this.status}, priority: ${_this.priority}, dueDate: ${_this.dueDate}, dueTime: ${_this.dueTime}, recurrence: ${_this.recurrence}, tags: ${_this.tags}, sortOrder: ${_this.sortOrder}, completedAt: ${_this.completedAt}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, subtaskCount: ${_this.subtaskCount}, subtasksDone: ${_this.subtasksDone})';
}


}

/// @nodoc
abstract mixin class $TaskCopyWith<$Res>  {
  factory $TaskCopyWith(Task value, $Res Function(Task) _then) = _$TaskCopyWithImpl;
@useResult
$Res call({
 String id, String workspaceId, String? projectId, String title, String description, TaskStatus status, Priority priority, String? dueDate, String? dueTime, Recurrence? recurrence, List<String> tags,@JsonKey(name: 'order') double sortOrder,@NullableEpochMillisConverter() DateTime? completedAt,@EpochMillisConverter() DateTime createdAt,@EpochMillisConverter() DateTime updatedAt,@JsonKey(includeFromJson: false, includeToJson: false) int subtaskCount,@JsonKey(includeFromJson: false, includeToJson: false) int subtasksDone
});




}
/// @nodoc
class _$TaskCopyWithImpl<$Res>
    implements $TaskCopyWith<$Res> {
  _$TaskCopyWithImpl(this._self, this._then);

  final Task _self;
  final $Res Function(Task) _then;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? workspaceId = null,Object? projectId = freezed,Object? title = null,Object? description = null,Object? status = null,Object? priority = null,Object? dueDate = freezed,Object? dueTime = freezed,Object? recurrence = freezed,Object? tags = null,Object? sortOrder = null,Object? completedAt = freezed,Object? createdAt = null,Object? updatedAt = null,Object? subtaskCount = null,Object? subtasksDone = null,}) {
  return _then(Task(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,projectId: freezed == projectId ? _self.projectId : projectId // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TaskStatus,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as Priority,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as String?,dueTime: freezed == dueTime ? _self.dueTime : dueTime // ignore: cast_nullable_to_non_nullable
as String?,recurrence: freezed == recurrence ? _self.recurrence : recurrence // ignore: cast_nullable_to_non_nullable
as Recurrence?,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as double,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,subtaskCount: null == subtaskCount ? _self.subtaskCount : subtaskCount // ignore: cast_nullable_to_non_nullable
as int,subtasksDone: null == subtasksDone ? _self.subtasksDone : subtasksDone // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Task].
extension TaskPatterns on Task {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Task value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Task() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Task value)  $default,){
final _that = this;
switch (_that) {
case _Task():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Task value)?  $default,){
final _that = this;
switch (_that) {
case _Task() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String workspaceId,  String? projectId,  String title,  String description,  TaskStatus status,  Priority priority,  String? dueDate,  String? dueTime,  Recurrence? recurrence,  List<String> tags, @JsonKey(name: 'order')  double sortOrder, @NullableEpochMillisConverter()  DateTime? completedAt, @EpochMillisConverter()  DateTime createdAt, @EpochMillisConverter()  DateTime updatedAt, @JsonKey(includeFromJson: false, includeToJson: false)  int subtaskCount, @JsonKey(includeFromJson: false, includeToJson: false)  int subtasksDone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Task() when $default != null:
return $default(_that.id,_that.workspaceId,_that.projectId,_that.title,_that.description,_that.status,_that.priority,_that.dueDate,_that.dueTime,_that.recurrence,_that.tags,_that.sortOrder,_that.completedAt,_that.createdAt,_that.updatedAt,_that.subtaskCount,_that.subtasksDone);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String workspaceId,  String? projectId,  String title,  String description,  TaskStatus status,  Priority priority,  String? dueDate,  String? dueTime,  Recurrence? recurrence,  List<String> tags, @JsonKey(name: 'order')  double sortOrder, @NullableEpochMillisConverter()  DateTime? completedAt, @EpochMillisConverter()  DateTime createdAt, @EpochMillisConverter()  DateTime updatedAt, @JsonKey(includeFromJson: false, includeToJson: false)  int subtaskCount, @JsonKey(includeFromJson: false, includeToJson: false)  int subtasksDone)  $default,) {final _that = this;
switch (_that) {
case _Task():
return $default(_that.id,_that.workspaceId,_that.projectId,_that.title,_that.description,_that.status,_that.priority,_that.dueDate,_that.dueTime,_that.recurrence,_that.tags,_that.sortOrder,_that.completedAt,_that.createdAt,_that.updatedAt,_that.subtaskCount,_that.subtasksDone);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String workspaceId,  String? projectId,  String title,  String description,  TaskStatus status,  Priority priority,  String? dueDate,  String? dueTime,  Recurrence? recurrence,  List<String> tags, @JsonKey(name: 'order')  double sortOrder, @NullableEpochMillisConverter()  DateTime? completedAt, @EpochMillisConverter()  DateTime createdAt, @EpochMillisConverter()  DateTime updatedAt, @JsonKey(includeFromJson: false, includeToJson: false)  int subtaskCount, @JsonKey(includeFromJson: false, includeToJson: false)  int subtasksDone)?  $default,) {final _that = this;
switch (_that) {
case _Task() when $default != null:
return $default(_that.id,_that.workspaceId,_that.projectId,_that.title,_that.description,_that.status,_that.priority,_that.dueDate,_that.dueTime,_that.recurrence,_that.tags,_that.sortOrder,_that.completedAt,_that.createdAt,_that.updatedAt,_that.subtaskCount,_that.subtasksDone);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Task extends Task {
  const _Task({required this.id, required this.workspaceId, this.projectId, required this.title, this.description = '', this.status = TaskStatus.todo, this.priority = Priority.medium, this.dueDate, this.dueTime, this.recurrence,  List<String> tags = const <String>[], @JsonKey(name: 'order') this.sortOrder = 0, @NullableEpochMillisConverter() this.completedAt, @EpochMillisConverter() required this.createdAt, @EpochMillisConverter() required this.updatedAt, @JsonKey(includeFromJson: false, includeToJson: false) this.subtaskCount = 0, @JsonKey(includeFromJson: false, includeToJson: false) this.subtasksDone = 0}): _tags = tags,super._();
  factory _Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

@override final  String id;
@override final  String workspaceId;
@override final  String? projectId;
@override final  String title;
@override@JsonKey() final  String description;
@override@JsonKey() final  TaskStatus status;
@override@JsonKey() final  Priority priority;
/// `YYYY-MM-DD`, local calendar day.
@override final  String? dueDate;
/// `HH:mm` on [dueDate].
@override final  String? dueTime;
@override final  Recurrence? recurrence;
 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override@JsonKey(name: 'order') final  double sortOrder;
@override@NullableEpochMillisConverter() final  DateTime? completedAt;
@override@EpochMillisConverter() final  DateTime createdAt;
@override@EpochMillisConverter() final  DateTime updatedAt;
/// Derived from the task's subtasks when read from storage; not persisted.
@override@JsonKey(includeFromJson: false, includeToJson: false) final  int subtaskCount;
@override@JsonKey(includeFromJson: false, includeToJson: false) final  int subtasksDone;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskCopyWith<_Task> get copyWith => __$TaskCopyWithImpl<_Task>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Task&&(identical(other.id, id) || other.id == id)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.projectId, projectId) || other.projectId == projectId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.status, status) || other.status == status)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.dueTime, dueTime) || other.dueTime == dueTime)&&(identical(other.recurrence, recurrence) || other.recurrence == recurrence)&&const DeepCollectionEquality().equals(other.tags, _tags)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.subtaskCount, subtaskCount) || other.subtaskCount == subtaskCount)&&(identical(other.subtasksDone, subtasksDone) || other.subtasksDone == subtasksDone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,workspaceId,projectId,title,description,status,priority,dueDate,dueTime,recurrence,const DeepCollectionEquality().hash(_tags),sortOrder,completedAt,createdAt,updatedAt,subtaskCount,subtasksDone);
}

@override
String toString() {
    return 'Task(id: $id, workspaceId: $workspaceId, projectId: $projectId, title: $title, description: $description, status: $status, priority: $priority, dueDate: $dueDate, dueTime: $dueTime, recurrence: $recurrence, tags: $tags, sortOrder: $sortOrder, completedAt: $completedAt, createdAt: $createdAt, updatedAt: $updatedAt, subtaskCount: $subtaskCount, subtasksDone: $subtasksDone)';
}


}

/// @nodoc
abstract mixin class _$TaskCopyWith<$Res> implements $TaskCopyWith<$Res> {
  factory _$TaskCopyWith(_Task value, $Res Function(_Task) _then) = __$TaskCopyWithImpl;
@override @useResult
$Res call({
 String id, String workspaceId, String? projectId, String title, String description, TaskStatus status, Priority priority, String? dueDate, String? dueTime, Recurrence? recurrence, List<String> tags,@JsonKey(name: 'order') double sortOrder,@NullableEpochMillisConverter() DateTime? completedAt,@EpochMillisConverter() DateTime createdAt,@EpochMillisConverter() DateTime updatedAt,@JsonKey(includeFromJson: false, includeToJson: false) int subtaskCount,@JsonKey(includeFromJson: false, includeToJson: false) int subtasksDone
});




}
/// @nodoc
class __$TaskCopyWithImpl<$Res>
    implements _$TaskCopyWith<$Res> {
  __$TaskCopyWithImpl(this._self, this._then);

  final _Task _self;
  final $Res Function(_Task) _then;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? workspaceId = null,Object? projectId = freezed,Object? title = null,Object? description = null,Object? status = null,Object? priority = null,Object? dueDate = freezed,Object? dueTime = freezed,Object? recurrence = freezed,Object? tags = null,Object? sortOrder = null,Object? completedAt = freezed,Object? createdAt = null,Object? updatedAt = null,Object? subtaskCount = null,Object? subtasksDone = null,}) {
  return _then(_Task(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,projectId: freezed == projectId ? _self.projectId : projectId // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TaskStatus,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as Priority,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as String?,dueTime: freezed == dueTime ? _self.dueTime : dueTime // ignore: cast_nullable_to_non_nullable
as String?,recurrence: freezed == recurrence ? _self.recurrence : recurrence // ignore: cast_nullable_to_non_nullable
as Recurrence?,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as double,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,subtaskCount: null == subtaskCount ? _self.subtaskCount : subtaskCount // ignore: cast_nullable_to_non_nullable
as int,subtasksDone: null == subtasksDone ? _self.subtasksDone : subtasksDone // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$Subtask {

 String get id; String get taskId; String get title; bool get isDone; double get sortOrder;@EpochMillisConverter() DateTime get createdAt;@EpochMillisConverter() DateTime get updatedAt;
/// Create a copy of Subtask
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubtaskCopyWith<Subtask> get copyWith => _$SubtaskCopyWithImpl<Subtask>(this as Subtask, _$identity);

  /// Serializes this Subtask to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Subtask;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Subtask&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.taskId, _this.taskId) || other.taskId == _this.taskId)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.isDone, _this.isDone) || other.isDone == _this.isDone)&&(identical(other.sortOrder, _this.sortOrder) || other.sortOrder == _this.sortOrder)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Subtask;
  return Object.hash(runtimeType,_this.id,_this.taskId,_this.title,_this.isDone,_this.sortOrder,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as Subtask;
  return 'Subtask(id: ${_this.id}, taskId: ${_this.taskId}, title: ${_this.title}, isDone: ${_this.isDone}, sortOrder: ${_this.sortOrder}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $SubtaskCopyWith<$Res>  {
  factory $SubtaskCopyWith(Subtask value, $Res Function(Subtask) _then) = _$SubtaskCopyWithImpl;
@useResult
$Res call({
 String id, String taskId, String title, bool isDone, double sortOrder,@EpochMillisConverter() DateTime createdAt,@EpochMillisConverter() DateTime updatedAt
});




}
/// @nodoc
class _$SubtaskCopyWithImpl<$Res>
    implements $SubtaskCopyWith<$Res> {
  _$SubtaskCopyWithImpl(this._self, this._then);

  final Subtask _self;
  final $Res Function(Subtask) _then;

/// Create a copy of Subtask
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? taskId = null,Object? title = null,Object? isDone = null,Object? sortOrder = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(Subtask(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,isDone: null == isDone ? _self.isDone : isDone // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as double,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Subtask].
extension SubtaskPatterns on Subtask {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Subtask value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Subtask() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Subtask value)  $default,){
final _that = this;
switch (_that) {
case _Subtask():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Subtask value)?  $default,){
final _that = this;
switch (_that) {
case _Subtask() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String taskId,  String title,  bool isDone,  double sortOrder, @EpochMillisConverter()  DateTime createdAt, @EpochMillisConverter()  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Subtask() when $default != null:
return $default(_that.id,_that.taskId,_that.title,_that.isDone,_that.sortOrder,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String taskId,  String title,  bool isDone,  double sortOrder, @EpochMillisConverter()  DateTime createdAt, @EpochMillisConverter()  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Subtask():
return $default(_that.id,_that.taskId,_that.title,_that.isDone,_that.sortOrder,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String taskId,  String title,  bool isDone,  double sortOrder, @EpochMillisConverter()  DateTime createdAt, @EpochMillisConverter()  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Subtask() when $default != null:
return $default(_that.id,_that.taskId,_that.title,_that.isDone,_that.sortOrder,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Subtask implements Subtask {
  const _Subtask({required this.id, required this.taskId, required this.title, this.isDone = false, this.sortOrder = 0, @EpochMillisConverter() required this.createdAt, @EpochMillisConverter() required this.updatedAt});
  factory _Subtask.fromJson(Map<String, dynamic> json) => _$SubtaskFromJson(json);

@override final  String id;
@override final  String taskId;
@override final  String title;
@override@JsonKey() final  bool isDone;
@override@JsonKey() final  double sortOrder;
@override@EpochMillisConverter() final  DateTime createdAt;
@override@EpochMillisConverter() final  DateTime updatedAt;

/// Create a copy of Subtask
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubtaskCopyWith<_Subtask> get copyWith => __$SubtaskCopyWithImpl<_Subtask>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubtaskToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Subtask&&(identical(other.id, id) || other.id == id)&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.title, title) || other.title == title)&&(identical(other.isDone, isDone) || other.isDone == isDone)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,taskId,title,isDone,sortOrder,createdAt,updatedAt);
}

@override
String toString() {
    return 'Subtask(id: $id, taskId: $taskId, title: $title, isDone: $isDone, sortOrder: $sortOrder, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$SubtaskCopyWith<$Res> implements $SubtaskCopyWith<$Res> {
  factory _$SubtaskCopyWith(_Subtask value, $Res Function(_Subtask) _then) = __$SubtaskCopyWithImpl;
@override @useResult
$Res call({
 String id, String taskId, String title, bool isDone, double sortOrder,@EpochMillisConverter() DateTime createdAt,@EpochMillisConverter() DateTime updatedAt
});




}
/// @nodoc
class __$SubtaskCopyWithImpl<$Res>
    implements _$SubtaskCopyWith<$Res> {
  __$SubtaskCopyWithImpl(this._self, this._then);

  final _Subtask _self;
  final $Res Function(_Subtask) _then;

/// Create a copy of Subtask
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? taskId = null,Object? title = null,Object? isDone = null,Object? sortOrder = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Subtask(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,isDone: null == isDone ? _self.isDone : isDone // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as double,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$TaskSnapshot {

 Task get task; List<Subtask> get subtasks;
/// Create a copy of TaskSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskSnapshotCopyWith<TaskSnapshot> get copyWith => _$TaskSnapshotCopyWithImpl<TaskSnapshot>(this as TaskSnapshot, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TaskSnapshot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskSnapshot&&(identical(other.task, _this.task) || other.task == _this.task)&&const DeepCollectionEquality().equals(other.subtasks, _this.subtasks));
}


@override
int get hashCode {
  final _this = this as TaskSnapshot;
  return Object.hash(runtimeType,_this.task,const DeepCollectionEquality().hash(_this.subtasks));
}

@override
String toString() {
  final _this = this as TaskSnapshot;
  return 'TaskSnapshot(task: ${_this.task}, subtasks: ${_this.subtasks})';
}


}

/// @nodoc
abstract mixin class $TaskSnapshotCopyWith<$Res>  {
  factory $TaskSnapshotCopyWith(TaskSnapshot value, $Res Function(TaskSnapshot) _then) = _$TaskSnapshotCopyWithImpl;
@useResult
$Res call({
 Task task, List<Subtask> subtasks
});


$TaskCopyWith<$Res> get task;

}
/// @nodoc
class _$TaskSnapshotCopyWithImpl<$Res>
    implements $TaskSnapshotCopyWith<$Res> {
  _$TaskSnapshotCopyWithImpl(this._self, this._then);

  final TaskSnapshot _self;
  final $Res Function(TaskSnapshot) _then;

/// Create a copy of TaskSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? task = null,Object? subtasks = null,}) {
  return _then(TaskSnapshot(
task: null == task ? _self.task : task // ignore: cast_nullable_to_non_nullable
as Task,subtasks: null == subtasks ? _self.subtasks : subtasks // ignore: cast_nullable_to_non_nullable
as List<Subtask>,
  ));
}
/// Create a copy of TaskSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaskCopyWith<$Res> get task {
  
  return $TaskCopyWith<$Res>(_self.task, (value) {
    return _then(_self.copyWith(task: value));
  });
}
}


/// Adds pattern-matching-related methods to [TaskSnapshot].
extension TaskSnapshotPatterns on TaskSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _TaskSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _TaskSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Task task,  List<Subtask> subtasks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskSnapshot() when $default != null:
return $default(_that.task,_that.subtasks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Task task,  List<Subtask> subtasks)  $default,) {final _that = this;
switch (_that) {
case _TaskSnapshot():
return $default(_that.task,_that.subtasks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Task task,  List<Subtask> subtasks)?  $default,) {final _that = this;
switch (_that) {
case _TaskSnapshot() when $default != null:
return $default(_that.task,_that.subtasks);case _:
  return null;

}
}

}

/// @nodoc


class _TaskSnapshot implements TaskSnapshot {
  const _TaskSnapshot({required this.task, required  List<Subtask> subtasks}): _subtasks = subtasks;
  

@override final  Task task;
 final  List<Subtask> _subtasks;
@override List<Subtask> get subtasks {
  if (_subtasks is EqualUnmodifiableListView) return _subtasks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_subtasks);
}


/// Create a copy of TaskSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskSnapshotCopyWith<_TaskSnapshot> get copyWith => __$TaskSnapshotCopyWithImpl<_TaskSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskSnapshot&&(identical(other.task, task) || other.task == task)&&const DeepCollectionEquality().equals(other.subtasks, _subtasks));
}


@override
int get hashCode {
    return Object.hash(runtimeType,task,const DeepCollectionEquality().hash(_subtasks));
}

@override
String toString() {
    return 'TaskSnapshot(task: $task, subtasks: $subtasks)';
}


}

/// @nodoc
abstract mixin class _$TaskSnapshotCopyWith<$Res> implements $TaskSnapshotCopyWith<$Res> {
  factory _$TaskSnapshotCopyWith(_TaskSnapshot value, $Res Function(_TaskSnapshot) _then) = __$TaskSnapshotCopyWithImpl;
@override @useResult
$Res call({
 Task task, List<Subtask> subtasks
});


@override $TaskCopyWith<$Res> get task;

}
/// @nodoc
class __$TaskSnapshotCopyWithImpl<$Res>
    implements _$TaskSnapshotCopyWith<$Res> {
  __$TaskSnapshotCopyWithImpl(this._self, this._then);

  final _TaskSnapshot _self;
  final $Res Function(_TaskSnapshot) _then;

/// Create a copy of TaskSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? task = null,Object? subtasks = null,}) {
  return _then(_TaskSnapshot(
task: null == task ? _self.task : task // ignore: cast_nullable_to_non_nullable
as Task,subtasks: null == subtasks ? _self._subtasks : subtasks // ignore: cast_nullable_to_non_nullable
as List<Subtask>,
  ));
}

/// Create a copy of TaskSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaskCopyWith<$Res> get task {
  
  return $TaskCopyWith<$Res>(_self.task, (value) {
    return _then(_self.copyWith(task: value));
  });
}
}

// dart format on
