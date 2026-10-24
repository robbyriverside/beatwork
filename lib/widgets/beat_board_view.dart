import 'package:flutter/material.dart';
import '../models/beat_model.dart';
import '../state/story_provider.dart';
import '../theme/app_theme.dart';
import 'beat_card.dart';

class BeatBoardView extends StatefulWidget {
  final StoryProvider provider;
  final Function(BeatDefinition) onOpenBeat;

  const BeatBoardView({
    super.key,
    required this.provider,
    required this.onOpenBeat,
  });

  @override
  State<BeatBoardView> createState() => _BeatBoardViewState();
}

class _BeatBoardViewState extends State<BeatBoardView> {
  StoryAct? _selectedActFilter;

  @override
  Widget build(BuildContext context) {
    final filteredBeats = _selectedActFilter == null
        ? BeatDefinition.saveTheCatBeats
        : BeatDefinition.saveTheCatBeats
            .where((b) => b.act == _selectedActFilter)
            .toList();

    return Column(
      children: [
        // Act Filter & Navigation Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            border: Border(bottom: BorderSide(color: AppTheme.border)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 950;
              return Row(
                children: [
                  const Text(
                    'SAVE THE CAT!',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AppTheme.goldAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            selected: _selectedActFilter == null,
                            label: const Text('All 15 Beats'),
                            onSelected: (_) => setState(() => _selectedActFilter = null),
                            backgroundColor: AppTheme.surfaceElevated,
                            selectedColor: AppTheme.goldAccent.withValues(alpha: 0.2),
                            labelStyle: TextStyle(
                              fontSize: 11.5,
                              fontWeight: _selectedActFilter == null ? FontWeight.bold : FontWeight.normal,
                              color: _selectedActFilter == null ? AppTheme.goldAccent : AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          ...StoryAct.values.map(
                            (act) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                selected: _selectedActFilter == act,
                                label: Text('${act.title}: ${act.subtitle}'),
                                onSelected: (sel) =>
                                    setState(() => _selectedActFilter = sel ? act : null),
                                backgroundColor: AppTheme.surfaceElevated,
                                selectedColor: act.accentColor.withValues(alpha: 0.2),
                                labelStyle: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: _selectedActFilter == act ? FontWeight.bold : FontWeight.normal,
                                  color: _selectedActFilter == act ? act.accentColor : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isWide) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app_outlined, size: 14, color: AppTheme.goldAccent),
                          SizedBox(width: 4),
                          Text(
                            'Drag events into beats',
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),

        // Beat Sheet Grid
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate responsive columns based on available width
              int crossAxisCount = 4;
              if (constraints.maxWidth < 800) {
                crossAxisCount = 1;
              } else if (constraints.maxWidth < 1150) {
                crossAxisCount = 2;
              } else if (constraints.maxWidth < 1500) {
                crossAxisCount = 3;
              } else {
                crossAxisCount = 4;
              }

              return GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.95,
                ),
                itemCount: filteredBeats.length,
                itemBuilder: (context, index) {
                  final beat = filteredBeats[index];
                  return BeatCard(
                    beat: beat,
                    provider: widget.provider,
                    onTap: () => widget.onOpenBeat(beat),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
