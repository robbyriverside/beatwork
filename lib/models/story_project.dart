import 'package:uuid/uuid.dart';
import 'beat_model.dart';
import 'story_event.dart';
import 'scene_model.dart';

class StoryProject {
  final String id;
  String title;
  String logline;
  String genre;
  String author;
  List<StoryEvent> events;
  List<Scene> scenes;
  bool isSample;
  DateTime lastModified;

  StoryProject({
    required this.id,
    required this.title,
    this.logline = '',
    this.genre = 'Feature Film',
    this.author = 'Screenwriter',
    this.isSample = false,
    List<StoryEvent>? events,
    List<Scene>? scenes,
    DateTime? lastModified,
  }) : events = events ?? [],
       scenes = scenes ?? [],
       lastModified = lastModified ?? DateTime.now();

  List<StoryEvent> getUnassignedEvents() {
    return events.where((e) => e.beatId == null || e.beatId!.isEmpty).toList();
  }

  List<StoryEvent> getEventsForBeat(String beatId) {
    return events.where((e) => e.beatId == beatId).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }

  List<Scene> getScenesForBeat(String beatId) {
    return scenes.where((s) => s.beatId == beatId).toList()
      ..sort((a, b) => a.timelineOrder.compareTo(b.timelineOrder));
  }

  /// Collects all beat timelines in canonical Save the Cat order (1 to 15),
  /// and within each beat by its timeline sequence.
  List<CollectedSceneEntry> getCollectedTimeline() {
    final List<CollectedSceneEntry> collected = [];
    int overallIndex = 1;

    for (final beatDef in BeatDefinition.saveTheCatBeats) {
      final beatScenes = getScenesForBeat(beatDef.id);
      for (final scene in beatScenes) {
        final mappedEvents = events
            .where((e) => scene.mappedEventIds.contains(e.id))
            .toList();

        collected.add(
          CollectedSceneEntry(
            overallIndex: overallIndex++,
            beat: beatDef,
            scene: scene,
            mappedEvents: mappedEvents,
          ),
        );
      }
    }
    return collected;
  }

  StoryProject duplicate({String? newTitle}) {
    final jsonCopy = toJson();
    jsonCopy['id'] = const Uuid().v4();
    jsonCopy['title'] = newTitle ?? '$title (Copy)';
    jsonCopy['isSample'] = false;
    jsonCopy['lastModified'] = DateTime.now().toIso8601String();
    return StoryProject.fromJson(jsonCopy);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'logline': logline,
      'genre': genre,
      'author': author,
      'isSample': isSample,
      'events': events.map((e) => e.toJson()).toList(),
      'scenes': scenes.map((s) => s.toJson()).toList(),
      'lastModified': lastModified.toIso8601String(),
    };
  }

  factory StoryProject.fromJson(Map<String, dynamic> json) {
    return StoryProject(
      id: json['id'] as String,
      title: json['title'] as String,
      logline: json['logline'] as String? ?? '',
      genre: json['genre'] as String? ?? 'Feature Film',
      author: json['author'] as String? ?? 'Screenwriter',
      isSample: json['isSample'] as bool? ?? false,
      events:
          (json['events'] as List<dynamic>?)
              ?.map((e) => StoryEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      scenes:
          (json['scenes'] as List<dynamic>?)
              ?.map((s) => Scene.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      lastModified: json['lastModified'] != null
          ? DateTime.tryParse(json['lastModified'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static StoryProject createEmptyProject({
    String title = 'Untitled Screenplay',
    String logline = '',
    String genre = 'Feature Film',
    String author = 'Screenwriter',
  }) {
    return StoryProject(
      id: const Uuid().v4(),
      title: title,
      logline: logline,
      genre: genre,
      author: author,
      isSample: false,
    );
  }

  /// Generates a rich, realistic sample project ("THE CHRONOS CIPHER")
  /// illustrating unassigned event pools, beat assignments, and scene versioning.
  static StoryProject createSampleProject({String? id}) {
    const uuid = Uuid();
    final projId = uuid.v4();

    // 1. Initial Story Events (Pool & Beat assignments)
    final e1 = StoryEvent(
      id: 'ev-open-1',
      title: 'Kael hacks a sub-orbital drone to pay back debts',
      description:
          'Dangling from a skyscraper antenna in Neo-Chicago, Kael risks his life for pocket money.',
      beatId: 'opening_image',
      characters: ['Kael'],
      location: 'Antenna Spire, Neo-Chicago',
      orderIndex: 0,
    );
    final e2 = StoryEvent(
      id: 'ev-open-2',
      title: 'Kael looks at an old photo of his estranged sister Maya',
      description:
          'Establishes his internal emotional wound and motivation to reconnect.',
      beatId: 'opening_image',
      characters: ['Kael'],
      location: 'Kael\'s Rooftop Shanty',
      orderIndex: 1,
    );

    final e3 = StoryEvent(
      id: 'ev-theme-1',
      title: 'Elena remarks that "Code has no conscience; people do"',
      description:
          'Elena warns Kael that algorithms will never save his family if he keeps running solo.',
      beatId: 'theme_stated',
      characters: ['Elena', 'Kael'],
      location: 'The Rusty Relay Bar',
      orderIndex: 0,
    );

    final e4 = StoryEvent(
      id: 'ev-setup-1',
      title: 'The Syndicates tighten control over black-market memory drives',
      description:
          'Showcasing the world rules: memory drives are currency, and Kael is drowning in debt.',
      beatId: 'set_up',
      characters: ['Kael', 'Baron Voss'],
      location: 'Underground Bazaar',
      orderIndex: 0,
    );
    final e5 = StoryEvent(
      id: 'ev-setup-2',
      title: 'Kael visits Maya in the quarantine ward',
      description:
          'Maya\'s neurological decay gives Kael a ticking clock to find a cure.',
      beatId: 'set_up',
      characters: ['Kael', 'Maya'],
      location: 'Metro General Quarantine',
      orderIndex: 1,
    );

    final e6 = StoryEvent(
      id: 'ev-cat-1',
      title: 'A dying courier drops the Chronos Core in Kael\'s lap',
      description:
          'A bleeding courier stumbles into Kael\'s workshop and transfers an encrypted quantum drive.',
      beatId: 'catalyst',
      characters: ['Kael', 'Courier Jax'],
      location: 'Kael\'s Workshop Alley',
      orderIndex: 0,
    );

    final e7 = StoryEvent(
      id: 'ev-deb-1',
      title: 'Kael tries to pawn the drive, but every fence flees in terror',
      description:
          'Debating whether to ditch the drive or figure out what is inside.',
      beatId: 'debate',
      characters: ['Kael', 'Pawn Broker'],
      location: 'Chrome Alley Pawn',
      orderIndex: 0,
    );
    final e8 = StoryEvent(
      id: 'ev-deb-2',
      title: 'Voss\'s cyber-hounds raid the alley; Kael must run',
      description: 'There is no staying neutral anymore.',
      beatId: 'debate',
      characters: ['Kael', 'Cyber Hounds'],
      location: 'Alleyways',
      orderIndex: 1,
    );

    final e9 = StoryEvent(
      id: 'ev-b2-1',
      title: 'Kael decides to infiltrate the Chronos Summit with Elena',
      description:
          'Actively choosing to cross into the corporate lion\'s den to decrypt the drive.',
      beatId: 'break_into_two',
      characters: ['Kael', 'Elena'],
      location: 'Monorail Terminal',
      orderIndex: 0,
    );

    // Unassigned Pool Events (brainstorming inbox!)
    final pool1 = StoryEvent(
      id: 'ev-pool-1',
      title: 'High-speed hovercraft chase through magnetic train tunnels',
      description:
          'Visual spectacle idea: EMP grenades causing neon train sparks.',
      beatId: null,
      characters: ['Kael', 'Elena', 'Pursuers'],
      location: 'Mag-Lev Tunnels',
    );
    final pool2 = StoryEvent(
      id: 'ev-pool-2',
      title: 'Elena reveals she was once lead architect for Chronos Corp',
      description: 'Personal betrayal twist or emotional vulnerability reveal.',
      beatId: null,
      characters: ['Elena'],
      location: 'Safehouse Hideout',
    );
    final pool3 = StoryEvent(
      id: 'ev-pool-3',
      title: 'Power grid blackout across the Lower Quarter',
      description:
          'Atmospheric beat: complete silence followed by red emergency flares.',
      beatId: null,
      characters: ['Civilians', 'Kael'],
      location: 'Lower Ward',
    );
    final pool4 = StoryEvent(
      id: 'ev-pool-4',
      title:
          'Kael discovers the Core contains a backup of Maya\'s lost consciousness',
      description:
          'Emotional revelation that turns the heist into a personal rescue.',
      beatId: null,
      characters: ['Kael'],
      location: 'Server Room',
    );
    final pool5 = StoryEvent(
      id: 'ev-pool-5',
      title: 'The AI in the core whispers a countdown in Kael\'s audio implant',
      description: 'Creepy psychological tension builder.',
      beatId: null,
      characters: ['Kael', 'Chronos AI'],
      location: 'Anywhere',
    );

    // 2. Sample Scenes with Multiple Versions and Event Mappings
    final s1v1 = SceneVersion(
      id: uuid.v4(),
      versionNumber: 1,
      label: 'Draft 1 (Raw Action)',
      slugline: 'EXT. NEO-CHICAGO SPIDERTOWER - NIGHT',
      summary: 'Kael splices into a drone while hanging 80 stories up.',
      scriptContent: '''EXT. NEO-CHICAGO SPIDERTOWER - NIGHT

Eighty floors above the toxic neon soup, wind screams against rusted steel girders.

KAELEN "KAEL" VANCE (28) hangs by a single nylon tether. Rain plasters his synthetic coat to his ribs.

In his left hand: a sparking EMP pry-tool. In his right: the trembling belly plate of a corporate courier drone.

KAEL
(whispering to himself)
Three seconds to bypass. Two seconds to live. One second to regret my career choices.

He jams the pry-tool into the drone's optic port. BLUE LIGHT FLASHES.

The drone's rotors sputter, then whir dead. Kael grabs the memory spool just as the frame plunges into the abyss.''',
      notes:
          'Initial scene draft. Needs more focus on his worn-out gloves to highlight poverty.',
    );

    final s1v2 = SceneVersion(
      id: uuid.v4(),
      versionNumber: 2,
      label: 'Draft 2 (Screenplay Polish)',
      slugline: 'EXT. SPIDERTOWER ANTENNA - NIGHT',
      summary:
          'Tightened pacing, introduced the ticking rain and his sister\'s lucky coin.',
      scriptContent: '''EXT. SPIDERTOWER ANTENNA - NIGHT

Rain lashes like buckshot. Eighty stories above the neon sludge of Neo-Chicago.

KAEL (28), lean as wire and twice as tense, clings to a trembling lightning rod.

A MILITARY-SPEC DRONE hovers four feet out, its twin searchlights slicing through the downpour like twin scalpels.

Kael fishes an acoustic pulse-knife from his grease-stained coat.

KAEL
(to the drone)
Hold still, gorgeous. We're both working overtime.

He lunges. Latches onto the drone's chassis with his prosthetic left hook.

ALARM KLAXONS SHRIEK. The drone pitches sideways, dragging Kael into free air!

Kael wrenches the core drive free. SNAP!

The drone spirals into the smog below. Kael swings back, slamming hard into the concrete wall, clutching the glowing glass cylinder to his chest.''',
      notes:
          'Latest polished version. Emphasizes his prosthetic hook and cinematic stakes.',
    );

    final scene1 = Scene(
      id: 'sc-1',
      beatId: 'opening_image',
      title: 'The Skyhook Heist',
      timelineOrder: 0,
      mappedEventIds: [e1.id],
      versions: [s1v1, s1v2],
      activeVersionId: s1v2.id,
    );

    final s2v1 = SceneVersion(
      id: uuid.v4(),
      versionNumber: 1,
      label: 'Draft 1',
      slugline: 'INT. KAEL\'S ROOFTOP SHANTY - DAWN',
      summary: 'Kael cleans his wounds and counts his meager score.',
      scriptContent: '''INT. KAEL'S ROOFTOP SHANTY - DAWN

Water drips from the corrugated iron roof into a plastic bucket. PLINK. PLINK.

Kael sits on an overturned crate, pressing a stim-patch against his bruised collarbone.

He pulls an antique holo-projector from under his mattress. Clicks it on.

A miniature, glowing holo-image of MAYA (22) flickers to life, laughing on a sunlit beach that doesn't exist anymore.

KAEL
Just a little longer, Maya. Almost got the credits.

He pockets the holo as a siren wails in the street below.''',
      notes: 'Emotional anchor establishing the sister connection.',
    );

    final scene2 = Scene(
      id: 'sc-2',
      beatId: 'opening_image',
      title: 'Echoes of Maya',
      timelineOrder: 1,
      mappedEventIds: [e2.id],
      versions: [s2v1],
      activeVersionId: s2v1.id,
    );

    final s3v1 = SceneVersion(
      id: uuid.v4(),
      versionNumber: 1,
      label: 'Draft 1',
      slugline: 'INT. THE RUSTY RELAY BAR - DAY',
      summary: 'Elena cautions Kael about trying to buy his way out of guilt.',
      scriptContent: '''INT. THE RUSTY RELAY BAR - DAY

Holographic neon signs advertise cheap synthetic noodles.

ELENA (30s), sharp eyes behind copper-rimmed spectacles, slides a mug of synthetic coffee across the zinc counter.

ELENA
You look like you fell off a skyscraper, Kael.

KAEL
Only eighty floors. Managed to land on my feet.

Elena glances at the glowing memory core on the table between them.

ELENA
You think you can purchase your sister's salvation with stolen corporate telemetry? Code has no conscience, Kael. Only people do.

Kael looks away, unable to meet her gaze.''',
      notes:
          'States the central theme: community/conscience vs cold algorithm.',
    );

    final scene3 = Scene(
      id: 'sc-3',
      beatId: 'theme_stated',
      title: 'Elena\'s Warning',
      timelineOrder: 0,
      mappedEventIds: [e3.id],
      versions: [s3v1],
      activeVersionId: s3v1.id,
    );

    final s4v1 = SceneVersion(
      id: uuid.v4(),
      versionNumber: 1,
      label: 'Draft 1',
      slugline: 'EXT. KAEL\'S WORKSHOP ALLEY - RAIN',
      summary:
          'Courier Jax collapses in the trash and delivers the Chronos Cipher.',
      scriptContent: '''EXT. KAEL'S WORKSHOP ALLEY - RAIN

Steam curls from ventilation grates.

A FIGURE stumbles through the curtain of rain. Collapses against the dumpster.

It's JAX (40), bleeding black synthetic fluid from his throat.

Kael rushes over, kneeling in the puddles.

KAEL
Jax! Who did this to you?

Jax claws at Kael's jacket, shoving a dense crystalline cube into his palm.

JAX
(choking)
Don't let Voss... don't let them erase her... Chronos is alive...

Jax's ocular implants go dark. His hand falls limp in the gutter.''',
      notes: 'Catalyst scene that initiates the main adventure.',
    );

    final scene4 = Scene(
      id: 'sc-4',
      beatId: 'catalyst',
      title: 'The Dying Courier',
      timelineOrder: 0,
      mappedEventIds: [e6.id],
      versions: [s4v1],
      activeVersionId: s4v1.id,
    );

    return StoryProject(
      id: id ?? 'sample-chronos-cipher',
      title: 'The Chronos Cipher',
      logline:
          'When an outlaw cyberpunk data-thief intercepts an impossible quantum drive containing the uploaded consciousness of his comatose sister, he must join forces with a rogue corporate architect to pull off the ultimate digital heist before an all-seeing Syndicate wipes her existence.',
      genre: 'Sci-Fi / Heist Thriller',
      author: 'Antigravity Screenwriter',
      isSample: true,
      events: [
        e1,
        e2,
        e3,
        e4,
        e5,
        e6,
        e7,
        e8,
        e9,
        pool1,
        pool2,
        pool3,
        pool4,
        pool5,
      ],
      scenes: [scene1, scene2, scene3, scene4],
    );
  }
}

class CollectedSceneEntry {
  final int overallIndex;
  final BeatDefinition beat;
  final Scene scene;
  final List<StoryEvent> mappedEvents;

  CollectedSceneEntry({
    required this.overallIndex,
    required this.beat,
    required this.scene,
    required this.mappedEvents,
  });
}

class ProjectMetadata {
  final String id;
  final String title;
  final String logline;
  final String genre;
  final String author;
  final int eventCount;
  final int sceneCount;
  final bool isSample;
  final DateTime lastModified;

  ProjectMetadata({
    required this.id,
    required this.title,
    this.logline = '',
    this.genre = 'Feature Film',
    this.author = 'Screenwriter',
    required this.eventCount,
    required this.sceneCount,
    this.isSample = false,
    required this.lastModified,
  });

  factory ProjectMetadata.fromProject(StoryProject project) {
    return ProjectMetadata(
      id: project.id,
      title: project.title,
      logline: project.logline,
      genre: project.genre,
      author: project.author,
      eventCount: project.events.length,
      sceneCount: project.scenes.length,
      isSample: project.isSample,
      lastModified: project.lastModified,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'logline': logline,
    'genre': genre,
    'author': author,
    'eventCount': eventCount,
    'sceneCount': sceneCount,
    'isSample': isSample,
    'lastModified': lastModified.toIso8601String(),
  };

  factory ProjectMetadata.fromJson(Map<String, dynamic> json) =>
      ProjectMetadata(
        id: json['id'] as String,
        title: json['title'] as String,
        logline: json['logline'] as String? ?? '',
        genre: json['genre'] as String? ?? 'Feature Film',
        author: json['author'] as String? ?? 'Screenwriter',
        eventCount: json['eventCount'] as int? ?? 0,
        sceneCount: json['sceneCount'] as int? ?? 0,
        isSample: json['isSample'] as bool? ?? false,
        lastModified: json['lastModified'] != null
            ? DateTime.tryParse(json['lastModified'] as String) ??
                  DateTime.now()
            : DateTime.now(),
      );
}
