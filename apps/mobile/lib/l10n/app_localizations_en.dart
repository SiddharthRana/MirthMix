// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MirthMix';

  @override
  String get tagline => 'Party games for one phone';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Let\'s play';

  @override
  String get onboarding1Title => 'Party games for one phone';

  @override
  String get onboarding1Body =>
      'Quick games for friends, couples and families sitting together. No setup, no app for everyone.';

  @override
  String get onboarding2Title => 'Read it out. Vote together.';

  @override
  String get onboarding2Body => 'One person reads, everyone answers. Pass the phone around or let a host keep score.';

  @override
  String get onboarding3Title => 'No sign-up. Just play.';

  @override
  String get onboarding3Body => 'Start a game in seconds. Nothing you play leaves your phone.';

  @override
  String get onboardingAge => 'MirthMix is made for ages 13 and up.';

  @override
  String get homeGreeting => 'Ready to play?';

  @override
  String get homeQuickPlay => 'Quick play';

  @override
  String get homeQuickPlayBody => '10 rounds of Would You Rather, mixed free categories.';

  @override
  String get homeResumeTitle => 'Game in progress';

  @override
  String homeResumeBody(String mode, int round, int total) {
    return '$mode · round $round of $total';
  }

  @override
  String get homeResume => 'Resume';

  @override
  String get homeDiscard => 'Discard';

  @override
  String get homeAllGames => 'All games';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get settings => 'Settings';

  @override
  String get libraryTitle => 'Games';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get modeWyrName => 'Would You Rather';

  @override
  String get modeWyrBlurb => 'Two choices. Everyone picks a side.';

  @override
  String get modeWyrRules =>
      'Read both options aloud. Everyone raises a hand for their pick, then tap each side once per vote. Reveal to see how the room split.';

  @override
  String get modeTotName => 'This or That';

  @override
  String get modeTotBlurb => 'Rapid-fire picks with big buttons.';

  @override
  String get modeTriviaName => 'Trivia Blitz';

  @override
  String get modeTriviaBlurb => 'Beat the timer, top the table.';

  @override
  String get modeGuessName => 'Guess the Answer';

  @override
  String get modeGuessBlurb => 'Fewer clues, more points.';

  @override
  String get modeCustomName => 'Custom Party Pack';

  @override
  String get modeCustomBlurb => 'Mix modes into one session.';

  @override
  String get setupTitle => 'Set up the game';

  @override
  String get setupHowToPlay => 'How to play';

  @override
  String get setupCategories => 'Categories';

  @override
  String get setupCategoriesHint => 'Pick at least one.';

  @override
  String get setupRounds => 'Rounds';

  @override
  String get setupGroupSize => 'Group size';

  @override
  String get setupGroupSizeHint => 'Optional. Limits votes per round to the number of players.';

  @override
  String get setupGroupSizeAny => 'Any';

  @override
  String setupGroupSizeValue(int count) {
    return '$count players';
  }

  @override
  String get setupPlayersDecrease => 'Fewer players';

  @override
  String get setupPlayersIncrease => 'More players';

  @override
  String get setupStart => 'Start game';

  @override
  String setupQuestionsAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count questions', one: '1 question');
    return '$_temp0';
  }

  @override
  String setupFewerQuestions(int count) {
    return 'Only $count questions in these categories, so you\'ll play $count rounds.';
  }

  @override
  String get premiumLabel => 'Premium';

  @override
  String get premiumLocked => 'Premium packs are coming soon.';

  @override
  String get regionIndia => 'India';

  @override
  String get ageTeen => '13+';

  @override
  String playRound(int round, int total) {
    return 'Round $round of $total';
  }

  @override
  String get playPrompt => 'Would you rather…';

  @override
  String get playOr => 'or';

  @override
  String get playHint => 'Raise hands, then tap a side once for each vote.';

  @override
  String playVotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count votes',
      one: '1 vote',
      zero: 'No votes',
    );
    return '$_temp0';
  }

  @override
  String playVotesOfPlayers(int count, int players) {
    return '$count of $players votes';
  }

  @override
  String playVoteFor(String option) {
    return 'Add a vote for: $option';
  }

  @override
  String get playUndo => 'Undo';

  @override
  String get playSkip => 'Skip';

  @override
  String get playSkipTooltip => 'Skip this question';

  @override
  String get playReveal => 'Reveal';

  @override
  String get playNext => 'Next round';

  @override
  String get playFinish => 'See results';

  @override
  String get playQuit => 'Quit game';

  @override
  String get playQuitTitle => 'Quit this game?';

  @override
  String get playQuitBody => 'Your progress in this game will be lost.';

  @override
  String get playQuitConfirm => 'Quit';

  @override
  String get playKeepPlaying => 'Keep playing';

  @override
  String playSplit(int percent) {
    return '$percent%';
  }

  @override
  String get playTie => 'Perfect split!';

  @override
  String get playUnanimous => 'Everyone agrees!';

  @override
  String get playNoVotes => 'No votes this round.';

  @override
  String get resultsTitle => 'Results';

  @override
  String resultsSummary(int rounds, int votes) {
    String _temp0 = intl.Intl.pluralLogic(rounds, locale: localeName, other: '$rounds rounds', one: '1 round');
    String _temp1 = intl.Intl.pluralLogic(votes, locale: localeName, other: '$votes votes', one: '1 vote');
    return '$_temp0 · $_temp1';
  }

  @override
  String get resultsDivisive => 'Most divisive';

  @override
  String get resultsUnanimous => 'Most unanimous';

  @override
  String get resultsAllRounds => 'Every round';

  @override
  String get resultsSkipped => 'Skipped';

  @override
  String get resultsPlayAgain => 'Play again';

  @override
  String get resultsChangeSetup => 'Change setup';

  @override
  String get resultsHome => 'Home';

  @override
  String resultsSplit(int a, int b) {
    return '$a – $b';
  }

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsPlay => 'Play';

  @override
  String get settingsBigText => 'Big text';

  @override
  String get settingsBigTextBody => 'Larger questions for reading across the room.';

  @override
  String get settingsReduceMotion => 'Reduce motion';

  @override
  String get settingsReduceMotionBody => 'Turn off animations. Your system setting is always respected.';

  @override
  String get settingsHaptics => 'Vibration';

  @override
  String get settingsHapticsBody => 'A small buzz when you tap a vote.';

  @override
  String get settingsShowOnboarding => 'Show the introduction again';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsPrivacyBody =>
      'MirthMix has no accounts and no analytics in this version. Games, settings and player counts are stored only on this phone.';

  @override
  String get settingsAge => 'Age guidance';

  @override
  String get settingsAgeBody =>
      'MirthMix is made for ages 13 and up. Categories marked 13+ include more mature themes, never explicit content.';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsLicenses => 'Open-source licences';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get errorContentTitle => 'Games couldn\'t load';

  @override
  String get errorContentBody =>
      'The game content on this phone looks damaged. Reinstalling the app usually fixes this.';

  @override
  String get errorEmptyCategories => 'No questions are available for the selected categories.';

  @override
  String get errorNotFound => 'That page doesn\'t exist.';

  @override
  String get goHome => 'Go home';
}
