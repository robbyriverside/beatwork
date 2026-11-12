# Beat Work

## Initial Description

The key value is that the software allows a screenwriter to assemble the beats in a story. The save the cat beat sheet is the base model in which all the writing is hung. It starts with Events that happen in the story. The writer may even write a bunch of events to define all the things that happen in the story, so far. The story is a work in progress. At some point, the writer assigns the event to a specific beat. The layout of the UI is defined by the beat sheet and dragging events into a beat. Clicking on the beat shows the details, which initially is a list of events in no particular order. There are usually, 3 to 5 events in a single beat. But it can be as many as you wish. A beat is composed of scenes. The work of writing starts with adding scenes to a beat. Scenes are mapped to beat events. The writer may create multiple versions of the same scene. The writer uses the latest version, but has access to all versions as a reference. Finally, the beat has a timeline, which is a series of scenes. The beat timelines are collected so it can be written to Final Draft or PDF.

Scenes can be marked unused in the beat timeline. They remain saved and editable, appear at the end of the list, and can be hidden or marked used again. Unused scenes are excluded from the Script Timeline and screenplay exports. To permanently delete a scene, first mark it unused and then confirm deletion. To delete an event, first move it to the event pool.

When adding or editing a scene, choose a slugline prefix and time and enter a location. The location menu includes locations from events and all scene versions in the current project; you can also type a new one. New scenes default to `INT.` and `DAY`. Press Return in the scene title to move to the location field. Existing nonstandard headings are preserved until their slugline fields are edited.

## Beat sheets

New projects require a title and can specify a logline and genre, as well as a
beat sheet and target length in pages (or minutes). The shared author name and
email are configured under Settings > Author and used for all projects and
exports. They are stored in the application's settings, not in project files.
Legacy project author fields are ignored and omitted when a project is saved.
The beat-sheet choice and resulting beats are saved in the project; they cannot be changed
after creation, and later template edits do not change existing projects.
Existing projects without a sheet use the original Save the Cat layout.

The bundled [Save the Cat](assets/beat_sheets/save_the_cat.yaml) template
preserves the original 19 beats and their page guidance. Its fixed page
references do not scale with the target length. The
[Five-Act Classic](assets/beat_sheets/five_act.yaml) template is a simple
Shakespeare-inspired structure. It estimates the total number of beats as the
target length divided by five pages/minutes, rounded up, with at least three
beats per act. Beats are distributed as evenly as possible among the five acts,
and extra development beats are inserted before each act's final anchor.
The five-page average and page positions are planning estimates, not limits
on the number or length of scenes.

The [Five-Act Hierarchy](assets/beat_sheets/five_act_hierarchy.yaml) template
uses the same estimation rule but treats each act as a complete conflict,
climax, and resolution. Each resolution sets up the next act; the final one
closes the story. Its interlocking pursuits, investigation, confrontation, and
aftermath are inspired by the structure of the US film *The Girl with the
Dragon Tattoo*.

Templates are YAML files bundled under `assets/beat_sheets/`. Each version 1
sheet has an `id`, `name`, `timeline_label`, `mode`, and ordered `acts`. Each
act supplies an `id`, `title`, `subtitle`, six-digit RGB `color` and
`dark_color`, and ordered `beats` with unique IDs, names, summaries and
guidance. A `fixed` sheet additionally gives each beat a `target_page`
(`Page N` or `Pages N - N`), `percentage`, and supported Material icon name,
as illustrated by the Save the Cat template. An `estimated` sheet specifies
`pages_per_beat`, `minimum_beats_per_act`, and `repeat_name`,
`repeat_summary`, and `repeat_guidance`; each act must provide exactly that
many anchor beats. Available bundled templates are discovered at startup for
the new-project dialog; adding one requires rebuilding the app.

The [JSON Schema](assets/beat_sheets/beat_sheet.schema.json) describes the
YAML format for editors and validators. It checks structure, required fields,
colors, page-label syntax, and supported fixed-beat icons. Standard JSON Schema
cannot check all loader rules: act IDs and beat IDs must each be unique (also
avoiding generated development beat IDs), an estimated act's anchor count must
equal `minimum_beats_per_act`, and a page range's end cannot precede its start.
The loader checks these rules when a template is used. Write integer fields as
YAML integers and quote color strings, including those containing only digits.

## macOS Release Build

Once you checkin your code.

Create a semantic version tag such as `v1.0.2`...

```sh
sh git tag -a v1.0.2 -m "new version"
```

...then run:

```sh
sh scripts/build_macos_release.sh
```

The build uses the highest semantic version tag as Flutter's build name. macOS records that version in the app bundle, where it appears in the native About panel. After the build, the script packages `beatwork.app` in a ZIP archive under `build/macos/Build/Products/Release/beatwork_<version>/`, with the leading `v` removed and periods replaced by underscores. For example, tag `v1.0.2` produces `beatwork_1_0_2/beatwork_1_0_2.zip`. Additional Flutter build options can be passed to the script.
