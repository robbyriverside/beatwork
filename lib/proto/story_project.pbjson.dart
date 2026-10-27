// This is a generated file - do not edit.
//
// Generated from proto/story_project.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use storyProjectDocumentDescriptor instead')
const StoryProjectDocument$json = {
  '1': 'StoryProjectDocument',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'logline', '3': 3, '4': 1, '5': 9, '10': 'logline'},
    {'1': 'genre', '3': 4, '4': 1, '5': 9, '10': 'genre'},
    {'1': 'author', '3': 5, '4': 1, '5': 9, '10': 'author'},
    {'1': 'is_sample', '3': 6, '4': 1, '5': 8, '10': 'isSample'},
    {
      '1': 'events',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.beatwork.StoryEventDocument',
      '10': 'events'
    },
    {
      '1': 'scenes',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.beatwork.SceneDocument',
      '10': 'scenes'
    },
    {
      '1': 'last_modified_micros',
      '3': 9,
      '4': 1,
      '5': 3,
      '10': 'lastModifiedMicros'
    },
    {'1': 'author_email', '3': 10, '4': 1, '5': 9, '10': 'authorEmail'},
  ],
};

/// Descriptor for `StoryProjectDocument`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List storyProjectDocumentDescriptor = $convert.base64Decode(
    'ChRTdG9yeVByb2plY3REb2N1bWVudBIOCgJpZBgBIAEoCVICaWQSFAoFdGl0bGUYAiABKAlSBX'
    'RpdGxlEhgKB2xvZ2xpbmUYAyABKAlSB2xvZ2xpbmUSFAoFZ2VucmUYBCABKAlSBWdlbnJlEhYK'
    'BmF1dGhvchgFIAEoCVIGYXV0aG9yEhsKCWlzX3NhbXBsZRgGIAEoCFIIaXNTYW1wbGUSNAoGZX'
    'ZlbnRzGAcgAygLMhwuYmVhdHdvcmsuU3RvcnlFdmVudERvY3VtZW50UgZldmVudHMSLwoGc2Nl'
    'bmVzGAggAygLMhcuYmVhdHdvcmsuU2NlbmVEb2N1bWVudFIGc2NlbmVzEjAKFGxhc3RfbW9kaW'
    'ZpZWRfbWljcm9zGAkgASgDUhJsYXN0TW9kaWZpZWRNaWNyb3MSIQoMYXV0aG9yX2VtYWlsGAog'
    'ASgJUgthdXRob3JFbWFpbA==');

@$core.Deprecated('Use storyEventDocumentDescriptor instead')
const StoryEventDocument$json = {
  '1': 'StoryEventDocument',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'description', '3': 3, '4': 1, '5': 9, '10': 'description'},
    {
      '1': 'beat_id',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'beatId',
      '17': true
    },
    {'1': 'characters', '3': 5, '4': 3, '5': 9, '10': 'characters'},
    {'1': 'location', '3': 6, '4': 1, '5': 9, '10': 'location'},
    {'1': 'order_index', '3': 7, '4': 1, '5': 5, '10': 'orderIndex'},
    {'1': 'created_at_micros', '3': 8, '4': 1, '5': 3, '10': 'createdAtMicros'},
  ],
  '8': [
    {'1': '_beat_id'},
  ],
};

/// Descriptor for `StoryEventDocument`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List storyEventDocumentDescriptor = $convert.base64Decode(
    'ChJTdG9yeUV2ZW50RG9jdW1lbnQSDgoCaWQYASABKAlSAmlkEhQKBXRpdGxlGAIgASgJUgV0aX'
    'RsZRIgCgtkZXNjcmlwdGlvbhgDIAEoCVILZGVzY3JpcHRpb24SHAoHYmVhdF9pZBgEIAEoCUgA'
    'UgZiZWF0SWSIAQESHgoKY2hhcmFjdGVycxgFIAMoCVIKY2hhcmFjdGVycxIaCghsb2NhdGlvbh'
    'gGIAEoCVIIbG9jYXRpb24SHwoLb3JkZXJfaW5kZXgYByABKAVSCm9yZGVySW5kZXgSKgoRY3Jl'
    'YXRlZF9hdF9taWNyb3MYCCABKANSD2NyZWF0ZWRBdE1pY3Jvc0IKCghfYmVhdF9pZA==');

@$core.Deprecated('Use sceneDocumentDescriptor instead')
const SceneDocument$json = {
  '1': 'SceneDocument',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'beat_id', '3': 2, '4': 1, '5': 9, '10': 'beatId'},
    {'1': 'title', '3': 3, '4': 1, '5': 9, '10': 'title'},
    {'1': 'timeline_order', '3': 4, '4': 1, '5': 5, '10': 'timelineOrder'},
    {'1': 'mapped_event_ids', '3': 5, '4': 3, '5': 9, '10': 'mappedEventIds'},
    {
      '1': 'versions',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.beatwork.SceneVersionDocument',
      '10': 'versions'
    },
    {
      '1': 'active_version_id',
      '3': 7,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'activeVersionId',
      '17': true
    },
  ],
  '8': [
    {'1': '_active_version_id'},
  ],
};

/// Descriptor for `SceneDocument`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sceneDocumentDescriptor = $convert.base64Decode(
    'Cg1TY2VuZURvY3VtZW50Eg4KAmlkGAEgASgJUgJpZBIXCgdiZWF0X2lkGAIgASgJUgZiZWF0SW'
    'QSFAoFdGl0bGUYAyABKAlSBXRpdGxlEiUKDnRpbWVsaW5lX29yZGVyGAQgASgFUg10aW1lbGlu'
    'ZU9yZGVyEigKEG1hcHBlZF9ldmVudF9pZHMYBSADKAlSDm1hcHBlZEV2ZW50SWRzEjoKCHZlcn'
    'Npb25zGAYgAygLMh4uYmVhdHdvcmsuU2NlbmVWZXJzaW9uRG9jdW1lbnRSCHZlcnNpb25zEi8K'
    'EWFjdGl2ZV92ZXJzaW9uX2lkGAcgASgJSABSD2FjdGl2ZVZlcnNpb25JZIgBAUIUChJfYWN0aX'
    'ZlX3ZlcnNpb25faWQ=');

@$core.Deprecated('Use sceneVersionDocumentDescriptor instead')
const SceneVersionDocument$json = {
  '1': 'SceneVersionDocument',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'version_number', '3': 2, '4': 1, '5': 5, '10': 'versionNumber'},
    {'1': 'label', '3': 3, '4': 1, '5': 9, '10': 'label'},
    {'1': 'slugline', '3': 4, '4': 1, '5': 9, '10': 'slugline'},
    {'1': 'summary', '3': 5, '4': 1, '5': 9, '10': 'summary'},
    {'1': 'script_content', '3': 6, '4': 1, '5': 9, '10': 'scriptContent'},
    {'1': 'notes', '3': 7, '4': 1, '5': 9, '10': 'notes'},
    {'1': 'created_at_micros', '3': 8, '4': 1, '5': 3, '10': 'createdAtMicros'},
  ],
};

/// Descriptor for `SceneVersionDocument`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sceneVersionDocumentDescriptor = $convert.base64Decode(
    'ChRTY2VuZVZlcnNpb25Eb2N1bWVudBIOCgJpZBgBIAEoCVICaWQSJQoOdmVyc2lvbl9udW1iZX'
    'IYAiABKAVSDXZlcnNpb25OdW1iZXISFAoFbGFiZWwYAyABKAlSBWxhYmVsEhoKCHNsdWdsaW5l'
    'GAQgASgJUghzbHVnbGluZRIYCgdzdW1tYXJ5GAUgASgJUgdzdW1tYXJ5EiUKDnNjcmlwdF9jb2'
    '50ZW50GAYgASgJUg1zY3JpcHRDb250ZW50EhQKBW5vdGVzGAcgASgJUgVub3RlcxIqChFjcmVh'
    'dGVkX2F0X21pY3JvcxgIIAEoA1IPY3JlYXRlZEF0TWljcm9z');
