import 'package:flutter/material.dart';

enum StoryAct {
  act1('Act 1', 'Exposition & Catalyst', Color(0xFF3B82F6), Color(0xFF1E3A8A)),
  act2A('Act 2A', 'Promise of the Premise', Color(0xFF10B981), Color(0xFF064E3B)),
  act2B('Act 2B', 'Bad Guys Close In & Crisis', Color(0xFFF59E0B), Color(0xFF78350F)),
  act3('Act 3', 'Climax & Resolution', Color(0xFF8B5CF6), Color(0xFF4C1D95));

  final String title;
  final String subtitle;
  final Color accentColor;
  final Color darkBg;

  const StoryAct(this.title, this.subtitle, this.accentColor, this.darkBg);
}

class BeatDefinition {
  final String id;
  final int number;
  final String name;
  final StoryAct act;
  final String targetPage;
  final String percentage;
  final String shortSummary;
  final String guidance;
  final IconData icon;

  const BeatDefinition({
    required this.id,
    required this.number,
    required this.name,
    required this.act,
    required this.targetPage,
    required this.percentage,
    required this.shortSummary,
    required this.guidance,
    required this.icon,
  });

  static const List<BeatDefinition> saveTheCatBeats = [
    // Act 1
    BeatDefinition(
      id: 'opening_image',
      number: 1,
      name: 'Opening Image',
      act: StoryAct.act1,
      targetPage: 'Page 1',
      percentage: '0% - 1%',
      shortSummary: 'The visual starting point and snapshot of the protagonist\'s flawed world.',
      guidance: 'Give us a snapshot of the hero\'s current world, flaw, and status quo before everything changes. Should contrast directly with the Final Image.',
      icon: Icons.movie_creation_outlined,
    ),
    BeatDefinition(
      id: 'theme_stated',
      number: 2,
      name: 'Theme Stated',
      act: StoryAct.act1,
      targetPage: 'Page 5',
      percentage: '5%',
      shortSummary: 'The philosophical core or lesson the protagonist must learn.',
      guidance: 'Usually spoken to or near the hero by a secondary character. The hero does not understand or accept it yet, but it states the true moral/internal journey.',
      icon: Icons.lightbulb_outline,
    ),
    BeatDefinition(
      id: 'set_up',
      number: 3,
      name: 'Set-Up',
      act: StoryAct.act1,
      targetPage: 'Pages 1 - 10',
      percentage: '1% - 10%',
      shortSummary: 'Explore the hero\'s life, relationships, and the "stasis = death" dilemma.',
      guidance: 'Introduce the main characters, the rules of this universe, and show why continuing the current way of living will result in spiritual or physical death.',
      icon: Icons.home_work_outlined,
    ),
    BeatDefinition(
      id: 'catalyst',
      number: 4,
      name: 'Catalyst',
      act: StoryAct.act1,
      targetPage: 'Page 12',
      percentage: '10% - 12%',
      shortSummary: 'The inciting incident that disrupts the status quo forever.',
      guidance: 'An unexpected event, telegram, murder, discovery, or offer that shakes the hero out of equilibrium. There is no going back to the old normal.',
      icon: Icons.bolt,
    ),
    BeatDefinition(
      id: 'debate',
      number: 5,
      name: 'Debate',
      act: StoryAct.act1,
      targetPage: 'Pages 12 - 25',
      percentage: '12% - 25%',
      shortSummary: 'Hesitation, doubt, and weighing the risks before taking the leap.',
      guidance: 'Should I stay or should I go? The hero prepares, hesitates, searches for an easy out, or tests their preparedness before accepting the call.',
      icon: Icons.question_mark_rounded,
    ),

    // Act 2A
    BeatDefinition(
      id: 'break_into_two',
      number: 6,
      name: 'Break into Two',
      act: StoryAct.act2A,
      targetPage: 'Page 25',
      percentage: '25%',
      shortSummary: 'The active choice to enter the upside-down, unfamiliar world.',
      guidance: 'The hero makes a deliberate, proactive choice to step across the threshold into Act 2. They enter a new arena with new rules.',
      icon: Icons.door_front_door_outlined,
    ),
    BeatDefinition(
      id: 'b_story',
      number: 7,
      name: 'B Story',
      act: StoryAct.act2A,
      targetPage: 'Page 30',
      percentage: '30%',
      shortSummary: 'Introduction of the love interest, mentor, or thematic ally.',
      guidance: 'The secondary relationship that provides breathing room from the main plot and delivers the thematic truth the hero desperately needs to evolve.',
      icon: Icons.favorite_border,
    ),
    BeatDefinition(
      id: 'fun_and_games',
      number: 8,
      name: 'Fun and Games',
      act: StoryAct.act2A,
      targetPage: 'Pages 30 - 55',
      percentage: '30% - 50%',
      shortSummary: 'The "Promise of the Premise" – iconic trailer moments.',
      guidance: 'The audience gets what was promised on the movie poster! Fish out of water adventures, training montages, initial heists, or budding romance.',
      icon: Icons.sports_esports_outlined,
    ),
    BeatDefinition(
      id: 'midpoint',
      number: 9,
      name: 'Midpoint',
      act: StoryAct.act2A,
      targetPage: 'Page 55',
      percentage: '50%',
      shortSummary: 'A major inflection point: false victory or false defeat; stakes escalate.',
      guidance: 'A turning point where the hero gets what they thought they wanted (false victory) or suffers a severe setback (false defeat). A ticking clock starts.',
      icon: Icons.hourglass_top_outlined,
    ),

    // Act 2B
    BeatDefinition(
      id: 'bad_guys_close_in',
      number: 10,
      name: 'Bad Guys Close In',
      act: StoryAct.act2B,
      targetPage: 'Pages 55 - 75',
      percentage: '50% - 75%',
      shortSummary: 'External antagonists regroup while internal doubts fracture alliances.',
      guidance: 'Enemies mount a counterattack, betrayal stirs from within, and the hero\'s unresolved flaws begin to unravel the progress they made.',
      icon: Icons.warning_amber_rounded,
    ),
    BeatDefinition(
      id: 'all_hope_is_lost',
      number: 11,
      name: 'All Hope Is Lost',
      act: StoryAct.act2B,
      targetPage: 'Page 75',
      percentage: '75%',
      shortSummary: 'The lowest point and the symbolic or literal "whiff of death".',
      guidance: 'The darkest nadir. The mentor dies, the plan fails catastrophically, the lovers split. The old way of operating is completely shattered.',
      icon: Icons.heart_broken_outlined,
    ),
    BeatDefinition(
      id: 'dark_night_of_the_soul',
      number: 12,
      name: 'Dark Night of the Soul',
      act: StoryAct.act2B,
      targetPage: 'Pages 75 - 85',
      percentage: '75% - 85%',
      shortSummary: 'Mourning the loss, hitting rock bottom, and discovering inner truth.',
      guidance: 'The hero is isolated and ready to give up. In this silence, they finally internalize the theme and realize how they must change from within.',
      icon: Icons.nights_stay_outlined,
    ),

    // Act 3
    BeatDefinition(
      id: 'break_into_three',
      number: 13,
      name: 'Break into Three',
      act: StoryAct.act3,
      targetPage: 'Page 85',
      percentage: '85%',
      shortSummary: 'The Eureka / Epiphany moment: a new synthesis is born.',
      guidance: 'Thanks to the B Story\'s wisdom and surviving the rock bottom, the hero devises a bold new solution that combines their outer goal with inner truth.',
      icon: Icons.wb_incandescent_outlined,
    ),
    BeatDefinition(
      id: 'finale',
      number: 14,
      name: 'Finale',
      act: StoryAct.act3,
      targetPage: 'Pages 85 - 110',
      percentage: '85% - 99%',
      shortSummary: 'The 5-point climax where the hero conquers the primary antagonist.',
      guidance: 'Gathering the team, executing the new plan, confronting high tower surprises, making the ultimate sacrifice/choice, and establishing the new order.',
      icon: Icons.military_tech_outlined,
    ),
    BeatDefinition(
      id: 'final_image',
      number: 15,
      name: 'Final Image',
      act: StoryAct.act3,
      targetPage: 'Page 110',
      percentage: '100%',
      shortSummary: 'The "after" mirror image demonstrating profound transformation.',
      guidance: 'The visual opposite of the Opening Image. Proves unequivocally that the hero and their world have evolved through this ordeal.',
      icon: Icons.verified_outlined,
    ),
  ];

  static BeatDefinition getById(String id) {
    return saveTheCatBeats.firstWhere(
      (b) => b.id == id,
      orElse: () => saveTheCatBeats.first,
    );
  }
}
