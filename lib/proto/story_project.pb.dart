// This is a generated file - do not edit.
//
// Generated from proto/story_project.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class StoryProjectDocument extends $pb.GeneratedMessage {
  factory StoryProjectDocument({
    $core.String? id,
    $core.String? title,
    $core.String? logline,
    $core.String? genre,
    $core.String? author,
    $core.bool? isSample,
    $core.Iterable<StoryEventDocument>? events,
    $core.Iterable<SceneDocument>? scenes,
    $fixnum.Int64? lastModifiedMicros,
  }) {
    final result = StoryProjectDocument._();
    if (id != null) result.id = id;
    if (title != null) result.title = title;
    if (logline != null) result.logline = logline;
    if (genre != null) result.genre = genre;
    if (author != null) result.author = author;
    if (isSample != null) result.isSample = isSample;
    if (events != null) result.events.addAll(events);
    if (scenes != null) result.scenes.addAll(scenes);
    if (lastModifiedMicros != null)
      result.lastModifiedMicros = lastModifiedMicros;
    return result;
  }

  StoryProjectDocument._();

  factory StoryProjectDocument.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StoryProjectDocument()..mergeFromBuffer(data, registry);
  factory StoryProjectDocument.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StoryProjectDocument()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StoryProjectDocument',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'beatwork'),
      createEmptyInstance: StoryProjectDocument.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'logline')
    ..aOS(4, _omitFieldNames ? '' : 'genre')
    ..aOS(5, _omitFieldNames ? '' : 'author')
    ..aOB(6, _omitFieldNames ? '' : 'isSample')
    ..pPM<StoryEventDocument>(7, _omitFieldNames ? '' : 'events',
        subBuilder: StoryEventDocument.$_createMessage)
    ..pPM<SceneDocument>(8, _omitFieldNames ? '' : 'scenes',
        subBuilder: SceneDocument.$_createMessage)
    ..aInt64(9, _omitFieldNames ? '' : 'lastModifiedMicros')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StoryProjectDocument clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StoryProjectDocument copyWith(void Function(StoryProjectDocument) updates) =>
      super.copyWith((message) => updates(message as StoryProjectDocument))
          as StoryProjectDocument;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use StoryProjectDocument() / StoryProjectDocument.new instead')
  static StoryProjectDocument create() => StoryProjectDocument._();
  static $pb.GeneratedMessage $_createMessage() => StoryProjectDocument._();
  @$core.override
  StoryProjectDocument createEmptyInstance() => StoryProjectDocument._();
  @$core.pragma('dart2js:noInline')
  static StoryProjectDocument getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StoryProjectDocument>(
          StoryProjectDocument.$_createMessage);
  static StoryProjectDocument? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get logline => $_getSZ(2);
  @$pb.TagNumber(3)
  set logline($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLogline() => $_has(2);
  @$pb.TagNumber(3)
  void clearLogline() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get genre => $_getSZ(3);
  @$pb.TagNumber(4)
  set genre($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasGenre() => $_has(3);
  @$pb.TagNumber(4)
  void clearGenre() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get author => $_getSZ(4);
  @$pb.TagNumber(5)
  set author($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAuthor() => $_has(4);
  @$pb.TagNumber(5)
  void clearAuthor() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get isSample => $_getBF(5);
  @$pb.TagNumber(6)
  set isSample($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasIsSample() => $_has(5);
  @$pb.TagNumber(6)
  void clearIsSample() => $_clearField(6);

  @$pb.TagNumber(7)
  $pb.PbList<StoryEventDocument> get events => $_getList(6);

  @$pb.TagNumber(8)
  $pb.PbList<SceneDocument> get scenes => $_getList(7);

  @$pb.TagNumber(9)
  $fixnum.Int64 get lastModifiedMicros => $_getI64(8);
  @$pb.TagNumber(9)
  set lastModifiedMicros($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasLastModifiedMicros() => $_has(8);
  @$pb.TagNumber(9)
  void clearLastModifiedMicros() => $_clearField(9);
}

class StoryEventDocument extends $pb.GeneratedMessage {
  factory StoryEventDocument({
    $core.String? id,
    $core.String? title,
    $core.String? description,
    $core.String? beatId,
    $core.Iterable<$core.String>? characters,
    $core.String? location,
    $core.int? orderIndex,
    $fixnum.Int64? createdAtMicros,
  }) {
    final result = StoryEventDocument._();
    if (id != null) result.id = id;
    if (title != null) result.title = title;
    if (description != null) result.description = description;
    if (beatId != null) result.beatId = beatId;
    if (characters != null) result.characters.addAll(characters);
    if (location != null) result.location = location;
    if (orderIndex != null) result.orderIndex = orderIndex;
    if (createdAtMicros != null) result.createdAtMicros = createdAtMicros;
    return result;
  }

  StoryEventDocument._();

  factory StoryEventDocument.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StoryEventDocument()..mergeFromBuffer(data, registry);
  factory StoryEventDocument.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StoryEventDocument()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StoryEventDocument',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'beatwork'),
      createEmptyInstance: StoryEventDocument.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'description')
    ..aOS(4, _omitFieldNames ? '' : 'beatId')
    ..pPS(5, _omitFieldNames ? '' : 'characters')
    ..aOS(6, _omitFieldNames ? '' : 'location')
    ..aI(7, _omitFieldNames ? '' : 'orderIndex')
    ..aInt64(8, _omitFieldNames ? '' : 'createdAtMicros')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StoryEventDocument clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StoryEventDocument copyWith(void Function(StoryEventDocument) updates) =>
      super.copyWith((message) => updates(message as StoryEventDocument))
          as StoryEventDocument;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use StoryEventDocument() / StoryEventDocument.new instead')
  static StoryEventDocument create() => StoryEventDocument._();
  static $pb.GeneratedMessage $_createMessage() => StoryEventDocument._();
  @$core.override
  StoryEventDocument createEmptyInstance() => StoryEventDocument._();
  @$core.pragma('dart2js:noInline')
  static StoryEventDocument getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StoryEventDocument>(
          StoryEventDocument.$_createMessage);
  static StoryEventDocument? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get description => $_getSZ(2);
  @$pb.TagNumber(3)
  set description($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDescription() => $_has(2);
  @$pb.TagNumber(3)
  void clearDescription() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get beatId => $_getSZ(3);
  @$pb.TagNumber(4)
  set beatId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBeatId() => $_has(3);
  @$pb.TagNumber(4)
  void clearBeatId() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get characters => $_getList(4);

  @$pb.TagNumber(6)
  $core.String get location => $_getSZ(5);
  @$pb.TagNumber(6)
  set location($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLocation() => $_has(5);
  @$pb.TagNumber(6)
  void clearLocation() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get orderIndex => $_getIZ(6);
  @$pb.TagNumber(7)
  set orderIndex($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasOrderIndex() => $_has(6);
  @$pb.TagNumber(7)
  void clearOrderIndex() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get createdAtMicros => $_getI64(7);
  @$pb.TagNumber(8)
  set createdAtMicros($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasCreatedAtMicros() => $_has(7);
  @$pb.TagNumber(8)
  void clearCreatedAtMicros() => $_clearField(8);
}

class SceneDocument extends $pb.GeneratedMessage {
  factory SceneDocument({
    $core.String? id,
    $core.String? beatId,
    $core.String? title,
    $core.int? timelineOrder,
    $core.Iterable<$core.String>? mappedEventIds,
    $core.Iterable<SceneVersionDocument>? versions,
    $core.String? activeVersionId,
  }) {
    final result = SceneDocument._();
    if (id != null) result.id = id;
    if (beatId != null) result.beatId = beatId;
    if (title != null) result.title = title;
    if (timelineOrder != null) result.timelineOrder = timelineOrder;
    if (mappedEventIds != null) result.mappedEventIds.addAll(mappedEventIds);
    if (versions != null) result.versions.addAll(versions);
    if (activeVersionId != null) result.activeVersionId = activeVersionId;
    return result;
  }

  SceneDocument._();

  factory SceneDocument.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SceneDocument()..mergeFromBuffer(data, registry);
  factory SceneDocument.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SceneDocument()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SceneDocument',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'beatwork'),
      createEmptyInstance: SceneDocument.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'beatId')
    ..aOS(3, _omitFieldNames ? '' : 'title')
    ..aI(4, _omitFieldNames ? '' : 'timelineOrder')
    ..pPS(5, _omitFieldNames ? '' : 'mappedEventIds')
    ..pPM<SceneVersionDocument>(6, _omitFieldNames ? '' : 'versions',
        subBuilder: SceneVersionDocument.$_createMessage)
    ..aOS(7, _omitFieldNames ? '' : 'activeVersionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SceneDocument clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SceneDocument copyWith(void Function(SceneDocument) updates) =>
      super.copyWith((message) => updates(message as SceneDocument))
          as SceneDocument;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SceneDocument() / SceneDocument.new instead')
  static SceneDocument create() => SceneDocument._();
  static $pb.GeneratedMessage $_createMessage() => SceneDocument._();
  @$core.override
  SceneDocument createEmptyInstance() => SceneDocument._();
  @$core.pragma('dart2js:noInline')
  static SceneDocument getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SceneDocument>(
          SceneDocument.$_createMessage);
  static SceneDocument? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get beatId => $_getSZ(1);
  @$pb.TagNumber(2)
  set beatId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBeatId() => $_has(1);
  @$pb.TagNumber(2)
  void clearBeatId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get title => $_getSZ(2);
  @$pb.TagNumber(3)
  set title($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTitle() => $_has(2);
  @$pb.TagNumber(3)
  void clearTitle() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get timelineOrder => $_getIZ(3);
  @$pb.TagNumber(4)
  set timelineOrder($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTimelineOrder() => $_has(3);
  @$pb.TagNumber(4)
  void clearTimelineOrder() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get mappedEventIds => $_getList(4);

  @$pb.TagNumber(6)
  $pb.PbList<SceneVersionDocument> get versions => $_getList(5);

  @$pb.TagNumber(7)
  $core.String get activeVersionId => $_getSZ(6);
  @$pb.TagNumber(7)
  set activeVersionId($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasActiveVersionId() => $_has(6);
  @$pb.TagNumber(7)
  void clearActiveVersionId() => $_clearField(7);
}

class SceneVersionDocument extends $pb.GeneratedMessage {
  factory SceneVersionDocument({
    $core.String? id,
    $core.int? versionNumber,
    $core.String? label,
    $core.String? slugline,
    $core.String? summary,
    $core.String? scriptContent,
    $core.String? notes,
    $fixnum.Int64? createdAtMicros,
  }) {
    final result = SceneVersionDocument._();
    if (id != null) result.id = id;
    if (versionNumber != null) result.versionNumber = versionNumber;
    if (label != null) result.label = label;
    if (slugline != null) result.slugline = slugline;
    if (summary != null) result.summary = summary;
    if (scriptContent != null) result.scriptContent = scriptContent;
    if (notes != null) result.notes = notes;
    if (createdAtMicros != null) result.createdAtMicros = createdAtMicros;
    return result;
  }

  SceneVersionDocument._();

  factory SceneVersionDocument.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SceneVersionDocument()..mergeFromBuffer(data, registry);
  factory SceneVersionDocument.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SceneVersionDocument()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SceneVersionDocument',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'beatwork'),
      createEmptyInstance: SceneVersionDocument.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aI(2, _omitFieldNames ? '' : 'versionNumber')
    ..aOS(3, _omitFieldNames ? '' : 'label')
    ..aOS(4, _omitFieldNames ? '' : 'slugline')
    ..aOS(5, _omitFieldNames ? '' : 'summary')
    ..aOS(6, _omitFieldNames ? '' : 'scriptContent')
    ..aOS(7, _omitFieldNames ? '' : 'notes')
    ..aInt64(8, _omitFieldNames ? '' : 'createdAtMicros')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SceneVersionDocument clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SceneVersionDocument copyWith(void Function(SceneVersionDocument) updates) =>
      super.copyWith((message) => updates(message as SceneVersionDocument))
          as SceneVersionDocument;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SceneVersionDocument() / SceneVersionDocument.new instead')
  static SceneVersionDocument create() => SceneVersionDocument._();
  static $pb.GeneratedMessage $_createMessage() => SceneVersionDocument._();
  @$core.override
  SceneVersionDocument createEmptyInstance() => SceneVersionDocument._();
  @$core.pragma('dart2js:noInline')
  static SceneVersionDocument getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SceneVersionDocument>(
          SceneVersionDocument.$_createMessage);
  static SceneVersionDocument? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get versionNumber => $_getIZ(1);
  @$pb.TagNumber(2)
  set versionNumber($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVersionNumber() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersionNumber() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get label => $_getSZ(2);
  @$pb.TagNumber(3)
  set label($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLabel() => $_has(2);
  @$pb.TagNumber(3)
  void clearLabel() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get slugline => $_getSZ(3);
  @$pb.TagNumber(4)
  set slugline($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSlugline() => $_has(3);
  @$pb.TagNumber(4)
  void clearSlugline() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get summary => $_getSZ(4);
  @$pb.TagNumber(5)
  set summary($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSummary() => $_has(4);
  @$pb.TagNumber(5)
  void clearSummary() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get scriptContent => $_getSZ(5);
  @$pb.TagNumber(6)
  set scriptContent($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasScriptContent() => $_has(5);
  @$pb.TagNumber(6)
  void clearScriptContent() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get notes => $_getSZ(6);
  @$pb.TagNumber(7)
  set notes($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasNotes() => $_has(6);
  @$pb.TagNumber(7)
  void clearNotes() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get createdAtMicros => $_getI64(7);
  @$pb.TagNumber(8)
  set createdAtMicros($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasCreatedAtMicros() => $_has(7);
  @$pb.TagNumber(8)
  void clearCreatedAtMicros() => $_clearField(8);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
