import 'package:flutter/material.dart';
import '../models/story_event.dart';
import '../state/story_provider.dart';
import '../theme/app_theme.dart';
import 'event_card.dart';
import 'event_dialog.dart';

class EventPoolSidebar extends StatelessWidget {
  final StoryProvider provider;
  final VoidCallback onClose;
  final Future<void> Function() onAddEvent;

  const EventPoolSidebar({
    super.key,
    required this.provider,
    required this.onClose,
    required this.onAddEvent,
  });

  @override
  Widget build(BuildContext context) {
    final unassigned = provider.project.getUnassignedEvents();

    final filteredEvents = unassigned.where((ev) {
      if (provider.eventSearchQuery.isNotEmpty) {
        final q = provider.eventSearchQuery.toLowerCase();
        final matchTitle = ev.title.toLowerCase().contains(q);
        final matchDesc = ev.description.toLowerCase().contains(q);
        final matchLoc = ev.location.toLowerCase().contains(q);
        final matchChars = ev.characters.any(
          (c) => c.toLowerCase().contains(q),
        );
        if (!matchTitle && !matchDesc && !matchLoc && !matchChars) return false;
      }
      return true;
    }).toList();

    return Container(
      width: 340,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(left: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 20,
                  color: AppTheme.goldAccent,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Story Event Pool',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Unassigned story beats & ideas',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderHighlight),
                  ),
                  child: Text(
                    '${unassigned.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.goldAccent,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  tooltip: 'Close Event Pool',
                  onPressed: onClose,
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    size: 14,
                    color: AppTheme.goldAccent,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Drag events into beats',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search story events...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: provider.eventSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () => provider.setEventSearchQuery(''),
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (val) => provider.setEventSearchQuery(val),
                ),
              ],
            ),
          ),

          // Drag Target to return events to the pool!
          DragTarget<StoryEvent>(
            onWillAcceptWithDetails: (details) => details.data.beatId != null,
            onAcceptWithDetails: (details) {
              provider.unassignEvent(details.data.id);
            },
            builder: (context, candidateData, rejectedData) {
              final isHovered = candidateData.isNotEmpty;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: isHovered
                      ? AppTheme.goldAccent.withOpacity(0.15)
                      : AppTheme.surfaceElevated.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isHovered ? AppTheme.goldAccent : AppTheme.border,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.move_to_inbox_outlined,
                      size: 16,
                      color: isHovered
                          ? AppTheme.goldAccent
                          : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        isHovered
                            ? 'Drop to move back to Pool'
                            : 'Drop events here to unassign',
                        style: TextStyle(
                          fontSize: 11,
                          color: isHovered
                              ? AppTheme.goldAccent
                              : AppTheme.textMuted,
                          fontWeight: isHovered
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 6),

          // Events List
          Expanded(
            child: filteredEvents.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 36,
                            color: AppTheme.textMuted.withOpacity(0.5),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Event Pool is Empty',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Write down story moments, twists, and character actions to build your story foundation.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    itemCount: filteredEvents.length,
                    itemBuilder: (context, index) {
                      final ev = filteredEvents[index];
                      return EventCard(
                        event: ev,
                        onEdit: () async {
                          final updated = await EventDialog.show(
                            context,
                            initialEvent: ev,
                            onSaveAndContinue: (event, isEditing) {
                              if (isEditing) {
                                provider.updateEvent(event);
                              } else {
                                provider.createEvent(
                                  title: event.title,
                                  description: event.description,
                                  beatId: event.beatId,
                                  characters: event.characters,
                                  location: event.location,
                                );
                              }
                            },
                          );
                          if (updated != null) {
                            if (updated.id.isEmpty) {
                              provider.createEvent(
                                title: updated.title,
                                description: updated.description,
                                beatId: updated.beatId,
                                characters: updated.characters,
                                location: updated.location,
                              );
                            } else {
                              provider.updateEvent(updated);
                            }
                          }
                        },
                        onDelete: () => provider.deleteEvent(ev.id),
                        onUnassign: null,
                      );
                    },
                  ),
          ),

          // Quick Add Footer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.border)),
            ),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Story Event  (%E)'),
              onPressed: onAddEvent,
            ),
          ),
        ],
      ),
    );
  }
}
