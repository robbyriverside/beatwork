import 'package:flutter/material.dart';
import '../models/story_event.dart';
import '../theme/app_theme.dart';

class EventCard extends StatelessWidget {
  final StoryEvent event;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onUnassign;
  final bool isCompact;
  final bool enableDrag;

  const EventCard({
    super.key,
    required this.event,
    this.onEdit,
    this.onDelete,
    this.onUnassign,
    this.isCompact = false,
    this.enableDrag = true,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidget = Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onEdit,
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 8 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: TextStyle(
                          fontSize: isCompact ? 12 : 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: isCompact ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (enableDrag)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.drag_indicator,
                          size: 16,
                          color: AppTheme.textMuted,
                        ),
                      ),
                  ],
                ),
                if (!isCompact && event.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    event.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (event.location.isNotEmpty) ...[
                      const Icon(Icons.place_outlined, size: 12, color: AppTheme.textMuted),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          event.location,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (event.characters.isNotEmpty)
                      Expanded(
                        child: Text(
                          event.characters.join(', '),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.goldLight,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    // Action popup
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz, size: 16, color: AppTheme.textMuted),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      itemBuilder: (context) => [
                        if (onEdit != null)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 16),
                                SizedBox(width: 8),
                                Text('Edit Event'),
                              ],
                            ),
                          ),
                        if (onUnassign != null && event.beatId != null)
                          const PopupMenuItem(
                            value: 'unassign',
                            child: Row(
                              children: [
                                Icon(Icons.move_to_inbox_outlined, size: 16),
                                SizedBox(width: 8),
                                Text('Move to Pool'),
                              ],
                            ),
                          ),
                        if (onDelete != null)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 16, color: AppTheme.crimsonAccent),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: AppTheme.crimsonAccent)),
                              ],
                            ),
                          ),
                      ],
                      onSelected: (val) {
                        if (val == 'edit') onEdit?.call();
                        if (val == 'unassign') onUnassign?.call();
                        if (val == 'delete') onDelete?.call();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!enableDrag) return cardWidget;

    return Draggable<StoryEvent>(
      data: event,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.goldAccent, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: cardWidget),
      child: cardWidget,
    );
  }
}
