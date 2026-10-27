# Beat Work

## Initial Description

The key value is that the software allows a screenwriter to assemble the beats in a story. The save the cat beat sheet is the base model in which all the writing is hung. It starts with Events that happen in the story. The writer may even write a bunch of events to define all the things that happen in the story, so far. The story is a work in progress. At some point, the writer assigns the event to a specific beat. The layout of the UI is defined by the beat sheet and dragging events into a beat. Clicking on the beat shows the details, which initially is a list of events in no particular order. There are usually, 3 to 5 events in a single beat. But it can be as many as you wish. A beat is composed of scenes. The work of writing starts with adding scenes to a beat. Scenes are mapped to beat events. The writer may create multiple versions of the same scene. The writer uses the latest version, but has access to all versions as a reference. Finally, the beat has a timeline, which is a series of scenes. The beat timelines are collected so it can be written to Final Draft or PDF.

## macOS Release Build

Create a semantic version tag such as `v1.0.2`, then run:

```sh
sh scripts/build_macos_release.sh
```

The build uses the highest semantic version tag as Flutter's build name. macOS records that version in the app bundle, where it appears in the native About panel. Additional Flutter build options can be passed to the script.
