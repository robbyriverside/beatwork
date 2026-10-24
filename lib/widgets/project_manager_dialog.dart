import 'package:flutter/material.dart';
import '../models/story_project.dart';
import '../state/story_provider.dart';
import '../theme/app_theme.dart';

/// Screenplay Project Manager Dialog
/// Allows screenwriters to switch between screenplays, start new projects,
/// duplicate drafts, restore the sample project, and see all saved screenplay files.
class ProjectManagerDialog extends StatefulWidget {
  final StoryProvider provider;

  const ProjectManagerDialog({super.key, required this.provider});

  static Future<void> show(
    BuildContext context, {
    required StoryProvider provider,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ProjectManagerDialog(provider: provider),
    );
  }

  @override
  State<ProjectManagerDialog> createState() => _ProjectManagerDialogState();
}

class _ProjectManagerDialogState extends State<ProjectManagerDialog> {
  String _searchFilter = '';

  @override
  void initState() {
    super.initState();
    widget.provider.refreshRecentProjects();
  }

  void _showNewProjectDialog() {
    final titleCtrl = TextEditingController(text: 'Untitled Screenplay');
    final loglineCtrl = TextEditingController();
    final genreCtrl = TextEditingController(text: 'Feature Film');
    final authorCtrl = TextEditingController(text: 'Screenwriter');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_box_outlined, color: AppTheme.goldAccent),
            SizedBox(width: 8),
            Text('Create New Screenplay Project'),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Screenplay Title *',
                  hintText: 'e.g. Midnight Horizon',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: loglineCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Logline / Core Premise',
                  hintText:
                      'Protagonist, inciting incident, goal, and central conflict.',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: genreCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Genre / Format',
                        hintText: 'e.g. Sci-Fi Thriller',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: authorCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Screenwriter',
                        hintText: 'Your name',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) return;

              Navigator.of(ctx).pop(); // Close create dialog
              await widget.provider.createNewProject(
                title: title,
                logline: loglineCtrl.text.trim(),
                genre: genreCtrl.text.trim().isEmpty
                    ? 'Feature Film'
                    : genreCtrl.text.trim(),
                author: authorCtrl.text.trim().isEmpty
                    ? 'Screenwriter'
                    : authorCtrl.text.trim(),
              );

              if (mounted) {
                Navigator.of(context).pop(); // Close manager dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Created and opened screenplay "$title"'),
                  ),
                );
              }
            },
            child: const Text('Create & Open'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProject(ProjectMetadata meta) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.delete_outline, color: AppTheme.crimsonAccent),
            const SizedBox(width: 8),
            Text('Delete "${meta.title}"?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this screenplay project and its saved beats, events, and scenes? This cannot be undone.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.crimsonAccent,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await widget.provider.deleteProject(meta.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted "${meta.title}"')),
                );
              }
            },
            child: const Text(
              'Delete Screenplay',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _promptDuplicateProject(ProjectMetadata meta) {
    final titleCtrl = TextEditingController(text: '${meta.title} (Copy)');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.copy_outlined, color: AppTheme.goldAccent),
            SizedBox(width: 8),
            Text('Duplicate Screenplay'),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Copy Title'),
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newTitle = titleCtrl.text.trim();
              Navigator.of(ctx).pop();

              if (meta.id == widget.provider.project.id) {
                await widget.provider.duplicateCurrentProject(
                  newTitle: newTitle,
                );
              } else {
                await widget.provider.switchProject(meta.id);
                await widget.provider.duplicateCurrentProject(
                  newTitle: newTitle,
                );
              }

              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Duplicated and opened "$newTitle"')),
                );
              }
            },
            child: const Text('Duplicate & Open'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 2) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final projects = widget.provider.recentProjects.where((p) {
      if (_searchFilter.isEmpty) return true;
      final q = _searchFilter.toLowerCase();
      return p.title.toLowerCase().contains(q) ||
          p.genre.toLowerCase().contains(q) ||
          p.logline.toLowerCase().contains(q);
    }).toList();

    final currentId = widget.provider.project.id;

    return Dialog(
      backgroundColor: AppTheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780, maxHeight: 680),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceElevated,
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.goldAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.goldAccent),
                    ),
                    child: const Icon(
                      Icons.movie_filter_outlined,
                      color: AppTheme.goldAccent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Screenplay Projects',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Each screenplay is stored separately. The most recent screenplay opens automatically.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary.withValues(
                              alpha: 0.9,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New Screenplay'),
                    onPressed: _showNewProjectDialog,
                  ),
                ],
              ),
            ),

            // Filter Bar & Quick Tools
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText:
                              'Search screenplays by title, genre, or premise...',
                          prefixIcon: const Icon(
                            Icons.search,
                            size: 18,
                            color: AppTheme.textSecondary,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(
                              color: AppTheme.border,
                            ),
                          ),
                        ),
                        onChanged: (val) => setState(() => _searchFilter = val),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    icon: const Icon(
                      Icons.auto_awesome,
                      size: 15,
                      color: AppTheme.goldAccent,
                    ),
                    label: const Text('Load Sample (Chronos Cipher)'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () async {
                      await widget.provider.loadSampleProject();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Loaded sample project "The Chronos Cipher"',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            // Projects List
            Expanded(
              child: projects.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open_outlined,
                            size: 48,
                            color: AppTheme.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No screenplays match your search.',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Create New Screenplay'),
                            onPressed: _showNewProjectDialog,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      itemCount: projects.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final meta = projects[index];
                        final isCurrent = meta.id == currentId;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? AppTheme.goldAccent.withValues(alpha: 0.06)
                                : AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isCurrent
                                  ? AppTheme.goldAccent
                                  : AppTheme.border,
                              width: isCurrent ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? AppTheme.goldAccent.withValues(
                                          alpha: 0.2,
                                        )
                                      : AppTheme.surfaceLighter,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  meta.isSample
                                      ? Icons.stars
                                      : Icons.description_outlined,
                                  size: 22,
                                  color: isCurrent
                                      ? AppTheme.goldAccent
                                      : AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Info Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          meta.title,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isCurrent
                                                ? AppTheme.goldAccent
                                                : AppTheme.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (isCurrent)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.goldAccent,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'ACTIVE',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.black,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        if (meta.isSample) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.cyan.withValues(
                                                alpha: 0.2,
                                              ),
                                              border: Border.all(
                                                color: Colors.cyanAccent
                                                    .withValues(alpha: 0.6),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'SAMPLE',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.cyanAccent,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),

                                    // Genre & Author
                                    Text(
                                      '${meta.genre}  •  Written by ${meta.author}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),

                                    if (meta.logline.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        meta.logline,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                          color: AppTheme.textSecondary
                                              .withValues(alpha: 0.85),
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 8),

                                    // Stats Row
                                    Row(
                                      children: [
                                        _statBadge(
                                          Icons.bolt,
                                          '${meta.eventCount} Events',
                                        ),
                                        const SizedBox(width: 12),
                                        _statBadge(
                                          Icons.movie_outlined,
                                          '${meta.sceneCount} Scenes',
                                        ),
                                        const SizedBox(width: 12),
                                        _statBadge(
                                          Icons.access_time,
                                          'Modified ${_formatDate(meta.lastModified)}',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 16),

                              // Action Buttons
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (!isCurrent)
                                    ElevatedButton.icon(
                                      icon: const Icon(
                                        Icons.arrow_forward,
                                        size: 14,
                                      ),
                                      label: const Text('Open'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                      ),
                                      onPressed: () async {
                                        await widget.provider.switchProject(
                                          meta.id,
                                        );
                                        if (context.mounted) {
                                          Navigator.of(context).pop();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Switched to screenplay "${meta.title}"',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.goldAccent.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: AppTheme.goldAccent.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            size: 14,
                                            color: AppTheme.goldAccent,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Editing Now',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.goldAccent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 8),

                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.copy_outlined,
                                          size: 16,
                                        ),
                                        tooltip: 'Duplicate Screenplay',
                                        onPressed: () =>
                                            _promptDuplicateProject(meta),
                                      ),
                                      if (!meta.isSample || projects.length > 1)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 16,
                                            color: AppTheme.crimsonAccent,
                                          ),
                                          tooltip: 'Delete Screenplay',
                                          onPressed: () =>
                                              _confirmDeleteProject(meta),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceElevated,
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${projects.length} Screenplay Project${projects.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBadge(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 13,
          color: AppTheme.textSecondary.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}
