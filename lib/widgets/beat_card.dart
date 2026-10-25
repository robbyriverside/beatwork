import 'package:flutter/material.dart';
import '../models/beat_model.dart';
import '../models/story_event.dart';
import '../state/story_provider.dart';
import '../theme/app_theme.dart';

class BeatCard extends StatelessWidget {
  final BeatDefinition beat;
  final StoryProvider provider;
  final VoidCallback onTap;

  const BeatCard({
    super.key,
    required this.beat,
    required this.provider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final beatEvents = provider.project.getEventsForBeat(beat.id);
    final beatScenes = provider.project.getScenesForBeat(beat.id);
    final isSelected = provider.selectedBeatId == beat.id;

    return DragTarget<StoryEvent>(
      onWillAcceptWithDetails: (details) {
        // Accept events that aren't already in this beat
        return details.data.beatId != beat.id;
      },
      onAcceptWithDetails: (details) {
        provider.assignEventToBeat(details.data.id, beat.id);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isHovered
                ? beat.act.accentColor.withValues(alpha: 0.16)
                : beat.act.accentColor.withValues(
                    alpha: isSelected ? 0.11 : 0.06,
                  ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHovered
                  ? beat.act.accentColor
                  : (isSelected ? AppTheme.goldAccent : AppTheme.border),
              width: (isHovered || isSelected) ? 2 : 1,
            ),
            boxShadow: isHovered
                ? [
                    BoxShadow(
                      color: beat.act.accentColor.withOpacity(0.3),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top: Beat Index & Act Indicator
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: beat.act.accentColor.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: beat.act.accentColor.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            'BEAT ${beat.number.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: beat.act.accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          beat.act.title,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            beat.targetPage,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Beat Name & Icon
                    Row(
                      children: [
                        Icon(beat.icon, size: 18, color: beat.act.accentColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            beat.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Short Summary
                    Text(
                      beat.shortSummary,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textSecondary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 10),
                    const Divider(height: 1, color: AppTheme.border),
                    const SizedBox(height: 10),

                    // Events preview or Drag Drop Target
                    Expanded(
                      child: isHovered
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.file_download_outlined,
                                    size: 32,
                                    color: beat.act.accentColor,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Drop to assign to ${beat.name}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: beat.act.accentColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : beatEvents.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_to_photos_outlined,
                                    size: 24,
                                    color: AppTheme.textMuted.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Drag events here\n(or click to open)',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: beatEvents.length > 3
                                  ? 3
                                  : beatEvents.length,
                              itemBuilder: (context, idx) {
                                final ev = beatEvents[idx];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceElevated,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: AppTheme.border.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        ev.emotionalCharge.symbol,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(
                                            ev.emotionalCharge.colorValue,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          ev.title,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),

                    // Card Footer: Event Count & Scene Count Badges
                    Row(
                      children: [
                        // Event count badge (highlighting 3-5 standard)
                        _buildCounterBadge(
                          icon: Icons.bolt,
                          label: '${beatEvents.length} Events',
                          isOptimal:
                              beatEvents.length >= 3 && beatEvents.length <= 5,
                          color: beat.act.accentColor,
                        ),
                        const SizedBox(width: 8),
                        // Scene count badge
                        _buildCounterBadge(
                          icon: Icons.movie_outlined,
                          label: '${beatScenes.length} Scenes',
                          isOptimal: beatScenes.isNotEmpty,
                          color: AppTheme.cyanAccent,
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: AppTheme.textMuted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCounterBadge({
    required IconData icon,
    required String label,
    required bool isOptimal,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isOptimal ? color.withOpacity(0.4) : AppTheme.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isOptimal ? AppTheme.textPrimary : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
