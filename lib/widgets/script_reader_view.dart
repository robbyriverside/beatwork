import 'package:flutter/material.dart';
import '../models/story_project.dart';
import '../services/export_service.dart';
import '../state/story_provider.dart';
import '../theme/app_theme.dart';
import 'beat_detail_dialog.dart';
import 'export_dialog.dart';

class ScriptReaderView extends StatefulWidget {
  final StoryProvider provider;

  const ScriptReaderView({super.key, required this.provider});

  @override
  State<ScriptReaderView> createState() => _ScriptReaderViewState();
}

class _ScriptReaderViewState extends State<ScriptReaderView> {
  Future<void> _exportTimelinePdf() async {
    try {
      final savedPath = await ExportService.saveBeatWorkTimelinePdf(
        widget.provider.project,
      );
      if (mounted && savedPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('BeatWork Timeline PDF saved: $savedPath')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not export Timeline PDF: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final collected = provider.project.getCollectedTimeline();

    // Calculate approximate stats
    int totalWords = 0;
    for (final item in collected) {
      final text = item.scene.activeVersion.scriptContent;
      totalWords += text
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .length;
    }
    // Estimated script pages (~200 words per formatted screenplay page)
    final estimatedPages = (totalWords / 200).ceil().clamp(
      collected.isEmpty ? 0 : 1,
      999,
    );

    return Column(
      children: [
        // Top Toolbar & Stats
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            border: Border(bottom: BorderSide(color: AppTheme.border)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.auto_stories,
                color: AppTheme.goldAccent,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SCRIPT TIMELINE: ${provider.project.title.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      'All beat timelines unified into a single screenplay draft',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Stats
              _buildStatPill(
                Icons.movie_outlined,
                '${collected.length} Scenes',
              ),
              const SizedBox(width: 8),
              _buildStatPill(
                Icons.description_outlined,
                '~$estimatedPages Pages',
              ),
              const SizedBox(width: 8),
              _buildStatPill(Icons.text_fields, '$totalWords Words'),
              const SizedBox(width: 16),
              // Export Button
              ElevatedButton.icon(
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Export Script (FDX / PDF)'),
                onPressed: () {
                  ExportDialog.show(context, provider: provider);
                },
              ),
            ],
          ),
        ),

        // Screenplay Pages Reader
        Expanded(
          child: collected.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.menu_book_outlined,
                          size: 48,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Scenes on the Story Timeline Yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Open any beat in the Beat Sheet, add scenes to the beat timeline, and they will collect here automatically.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 56,
                          vertical: 48,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.border),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 24,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Script Title Header
                            Center(
                              child: Text(
                                provider.project.title.toUpperCase(),
                                style: const TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Center(
                              child: Text(
                                'written by ${provider.project.author}',
                                style: const TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            if (provider.project.logline.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Center(
                                child: Text(
                                  '"${provider.project.logline}"',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Courier',
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 32),
                            const Divider(
                              color: AppTheme.border,
                              thickness: 1.5,
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                'Copyright © ${DateTime.now().year} BeatWork ScriptWriter',
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 10,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: ElevatedButton.icon(
                                key: const ValueKey(
                                  'export-beatwork-timeline-button',
                                ),
                                icon: const Icon(Icons.picture_as_pdf),
                                label: const Text('Export BeatWork'),
                                onPressed: _exportTimelinePdf,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Script content broken down by beat timeline
                            ..._buildTimelineScriptElements(collected),

                            const SizedBox(height: 48),
                            const Center(
                              child: Text(
                                'THE END',
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 3,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildStatPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTimelineScriptElements(
    List<CollectedSceneEntry> collected,
  ) {
    final List<Widget> list = [];
    String? currentBeatId;

    for (final entry in collected) {
      if (currentBeatId != entry.beat.id) {
        currentBeatId = entry.beat.id;
        list.add(
          InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () async {
              await BeatDetailDialog.show(
                context,
                beat: entry.beat,
                provider: widget.provider,
              );
              if (mounted) setState(() {});
            },
            child: Container(
              margin: const EdgeInsets.only(top: 28, bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: entry.beat.act.accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: entry.beat.act.accentColor.withOpacity(0.4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SAVE THE CAT: BEAT ${entry.beat.number} - ${entry.beat.name.toUpperCase()}',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: entry.beat.act.accentColor,
                    ),
                  ),
                  Text(
                    '${entry.beat.act.title} • ${entry.beat.targetPage}',
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      final version = entry.scene.activeVersion;

      // Scene Slugline
      list.add(
        Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  version.slugline.toUpperCase(),
                  style: AppTheme.screenplaySlugline,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Scene #${entry.overallIndex} • v${version.versionNumber}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'Courier',
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      final metadataLines = <String>[];
      if (version.summary.trim().isNotEmpty) {
        metadataLines.add('Summary: ${version.summary.trim()}');
      }
      if (version.notes.trim().isNotEmpty) {
        metadataLines.add('Writer Notes: ${version.notes.trim()}');
      }
      if (entry.mappedEvents.isNotEmpty) {
        metadataLines.add(
          'Events: ${entry.mappedEvents.map((event) => event.title).join('; ')}',
        );
      }

      if (metadataLines.isNotEmpty) {
        list.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: ['/*', ...metadataLines, '*/']
                    .map(
                      (line) => Text(
                        line,
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: entry.beat.act.accentColor,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        );
      }

      // Script Content
      final lines = version.scriptContent.split('\n');
      for (final rawLine in lines) {
        final line = rawLine.trim();
        if (line.isEmpty) {
          list.add(const SizedBox(height: 10));
          continue;
        }

        final upper = line.toUpperCase();
        if (_isCharacterName(line)) {
          // Character cue
          list.add(
            Container(
              margin: const EdgeInsets.only(top: 14, left: 160),
              child: Text(upper, style: AppTheme.screenplayCharacter),
            ),
          );
        } else if (line.startsWith('(') && line.endsWith(')')) {
          // Parenthetical
          list.add(
            Container(
              margin: const EdgeInsets.only(top: 2, left: 120),
              child: Text(
                line,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          );
        } else if (upper.endsWith('TO:') || upper.startsWith('FADE ')) {
          // Transition
          list.add(
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(upper, style: AppTheme.screenplaySlugline),
              ),
            ),
          );
        } else {
          // Action block
          list.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(line, style: AppTheme.screenplayAction),
            ),
          );
        }
      }

      list.add(const SizedBox(height: 18));
    }

    return list;
  }

  static bool _isCharacterName(String line) {
    if (line.isEmpty || line.length > 32) return false;
    final upper = line.toUpperCase();
    if (upper != line) return false;
    if (upper.startsWith('INT.') ||
        upper.startsWith('EXT.') ||
        upper.endsWith('TO:') ||
        upper.startsWith('FADE ')) {
      return false;
    }
    return RegExp(r'^[A-Z0-9\s\.\(\)\-_]+$').hasMatch(line);
  }
}
