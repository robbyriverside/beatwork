import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/story_project.dart';
import '../services/export_service.dart';
import '../state/story_provider.dart';
import '../theme/app_theme.dart';

class ExportDialog extends StatefulWidget {
  final StoryProvider provider;

  const ExportDialog({super.key, required this.provider});

  static Future<void> show(BuildContext context, {required StoryProvider provider}) {
    return showDialog(
      context: context,
      builder: (context) => ExportDialog(provider: provider),
    );
  }

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isExporting = false;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _exportFinalDraft() async {
    setState(() {
      _isExporting = true;
      _statusMessage = 'Generating Final Draft (.fdx) file...';
      _isSuccess = false;
    });

    try {
      final path = await ExportService.saveFinalDraftToFile(widget.provider.project);
      setState(() {
        _isExporting = false;
        if (path != null) {
          _isSuccess = true;
          _statusMessage = 'Successfully exported Final Draft to:\n$path';
        } else {
          _statusMessage = 'Export cancelled.';
        }
      });
    } catch (e) {
      setState(() {
        _isExporting = false;
        _isSuccess = false;
        _statusMessage = 'Export failed: $e';
      });
    }
  }

  Future<void> _exportPdf() async {
    setState(() {
      _isExporting = true;
      _statusMessage = 'Rendering Screenplay PDF with Courier typeface...';
      _isSuccess = false;
    });

    try {
      final path = await ExportService.savePdfToFile(widget.provider.project);
      setState(() {
        _isExporting = false;
        if (path != null) {
          _isSuccess = true;
          _statusMessage = 'Successfully exported Screenplay PDF to:\n$path';
        } else {
          _statusMessage = 'Export cancelled.';
        }
      });
    } catch (e) {
      setState(() {
        _isExporting = false;
        _isSuccess = false;
        _statusMessage = 'Export failed: $e';
      });
    }
  }

  Future<void> _exportFountain() async {
    setState(() {
      _isExporting = true;
      _statusMessage = 'Generating Fountain script...';
      _isSuccess = false;
    });

    try {
      final path = await ExportService.saveFountainToFile(widget.provider.project);
      setState(() {
        _isExporting = false;
        if (path != null) {
          _isSuccess = true;
          _statusMessage = 'Successfully exported Fountain file to:\n$path';
        } else {
          _statusMessage = 'Export cancelled.';
        }
      });
    } catch (e) {
      setState(() {
        _isExporting = false;
        _isSuccess = false;
        _statusMessage = 'Export failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final collected = widget.provider.project.getCollectedTimeline();
    final fdxPreview = ExportService.generateFinalDraftFdx(widget.provider.project);
    final fountainPreview = ExportService.generateFountain(widget.provider.project);

    return Dialog(
      backgroundColor: AppTheme.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.borderHighlight),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.file_download, color: AppTheme.goldAccent, size: 24),
                  const SizedBox(width: 10),
                  const Text(
                    'Export Screenplay Timeline',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Collects all ${collected.length} scenes across your 15 Save the Cat beat timelines into industry-standard screenwriting formats.',
                style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),

              // Export Options Cards
              Row(
                children: [
                  // Final Draft Card
                  Expanded(
                    child: _buildExportCard(
                      title: 'Final Draft (.fdx)',
                      description: 'Industry standard XML format used in Final Draft 8-12',
                      icon: Icons.movie_outlined,
                      accentColor: AppTheme.goldAccent,
                      onExport: _isExporting ? null : _exportFinalDraft,
                      buttonText: 'Save .FDX File',
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Screenplay PDF Card
                  Expanded(
                    child: _buildExportCard(
                      title: 'Screenplay PDF',
                      description: 'Formatted letter page layout with standard Courier typography',
                      icon: Icons.picture_as_pdf_outlined,
                      accentColor: AppTheme.crimsonAccent,
                      onExport: _isExporting ? null : _exportPdf,
                      buttonText: 'Save PDF File',
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Fountain Card
                  Expanded(
                    child: _buildExportCard(
                      title: 'Fountain (.fountain)',
                      description: 'Universal plain-text screenplay format for Highland & Scrivener',
                      icon: Icons.text_snippet_outlined,
                      accentColor: AppTheme.cyanAccent,
                      onExport: _isExporting ? null : _exportFountain,
                      buttonText: 'Save .Fountain',
                    ),
                  ),
                ],
              ),

              // Status Banner
              if (_statusMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isSuccess
                        ? AppTheme.emeraldAccent.withOpacity(0.15)
                        : (_isExporting
                            ? AppTheme.goldAccent.withOpacity(0.15)
                            : AppTheme.crimsonAccent.withOpacity(0.15)),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _isSuccess
                          ? AppTheme.emeraldAccent
                          : (_isExporting ? AppTheme.goldAccent : AppTheme.crimsonAccent),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (_isExporting)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          _isSuccess ? Icons.check_circle : Icons.info_outline,
                          size: 18,
                          color: _isSuccess ? AppTheme.emeraldAccent : AppTheme.crimsonAccent,
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _isSuccess
                                ? AppTheme.emeraldAccent
                                : (_isExporting ? AppTheme.goldAccent : AppTheme.crimsonAccent),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              // Tab preview
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.goldAccent,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.goldAccent,
                tabs: const [
                  Tab(text: 'Final Draft XML Preview'),
                  Tab(text: 'Fountain Text Preview'),
                  Tab(text: 'Story Statistics'),
                ],
              ),
              const SizedBox(height: 10),

              // Tab View Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // FDX Tab
                    _buildCodePreview(
                      content: fdxPreview,
                      copyLabel: 'Copy Final Draft XML',
                    ),
                    // Fountain Tab
                    _buildCodePreview(
                      content: fountainPreview,
                      copyLabel: 'Copy Fountain Text',
                    ),
                    // Statistics Tab
                    _buildStatsTab(collected),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportCard({
    required String title,
    required String description,
    required IconData icon,
    required Color accentColor,
    required VoidCallback? onExport,
    required String buttonText,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onPressed: onExport,
              child: Text(buttonText, style: const TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodePreview({required String content, required String copyLabel}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF10121A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.copy, size: 14),
                label: Text(copyLabel, style: const TextStyle(fontSize: 11)),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied to clipboard!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: SelectableText(
                content,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 11.5,
                  color: Color(0xFFD1D5DB),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab(List<CollectedSceneEntry> collected) {
    final eventsAssigned =
        widget.provider.project.events.where((e) => e.beatId != null).length;
    final eventsInPool = widget.provider.project.getUnassignedEvents().length;
    final beatsWithScenes =
        collected.map((c) => c.beat.id).toSet().length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListView(
        children: [
          _statRow('Project Title', widget.provider.project.title),
          _statRow('Genre / Format', widget.provider.project.genre),
          _statRow('Author', widget.provider.project.author),
          const Divider(color: AppTheme.border),
          _statRow('Total Scenes on Timeline', '${collected.length} scenes'),
          _statRow('Beats with Scenes', '$beatsWithScenes of 15 beats active'),
          _statRow('Events Assigned to Beats', '$eventsAssigned events'),
          _statRow('Events in Unassigned Pool', '$eventsInPool events'),
          _statRow('Last Modified', widget.provider.project.lastModified.toLocal().toString().split('.')[0]),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
