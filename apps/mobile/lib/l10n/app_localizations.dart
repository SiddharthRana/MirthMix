import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'MirthMix'**
  String get appTitle;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Party games for one phone'**
  String get tagline;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Let\'s play'**
  String get onboardingStart;

  /// No description provided for @onboarding1Title.
  ///
  /// In en, this message translates to:
  /// **'Party games for one phone'**
  String get onboarding1Title;

  /// No description provided for @onboarding1Body.
  ///
  /// In en, this message translates to:
  /// **'Quick games for friends, couples and families sitting together. No setup, no app for everyone.'**
  String get onboarding1Body;

  /// No description provided for @onboarding2Title.
  ///
  /// In en, this message translates to:
  /// **'Read it out. Vote together.'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Body.
  ///
  /// In en, this message translates to:
  /// **'One person reads, everyone answers. Pass the phone around or let a host keep score.'**
  String get onboarding2Body;

  /// No description provided for @onboarding3Title.
  ///
  /// In en, this message translates to:
  /// **'No sign-up. Just play.'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Body.
  ///
  /// In en, this message translates to:
  /// **'Start a game in seconds. Nothing you play leaves your phone.'**
  String get onboarding3Body;

  /// No description provided for @onboardingAge.
  ///
  /// In en, this message translates to:
  /// **'MirthMix is made for ages 13 and up.'**
  String get onboardingAge;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Ready to play?'**
  String get homeGreeting;

  /// No description provided for @homeQuickPlay.
  ///
  /// In en, this message translates to:
  /// **'Quick play'**
  String get homeQuickPlay;

  /// No description provided for @homeQuickPlayBody.
  ///
  /// In en, this message translates to:
  /// **'10 rounds of Would You Rather, mixed free categories.'**
  String get homeQuickPlayBody;

  /// No description provided for @homeResumeTitle.
  ///
  /// In en, this message translates to:
  /// **'Game in progress'**
  String get homeResumeTitle;

  /// No description provided for @homeResumeBody.
  ///
  /// In en, this message translates to:
  /// **'{mode} · round {round} of {total}'**
  String homeResumeBody(String mode, int round, int total);

  /// No description provided for @homeResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get homeResume;

  /// No description provided for @homeDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get homeDiscard;

  /// No description provided for @homeAllGames.
  ///
  /// In en, this message translates to:
  /// **'All games'**
  String get homeAllGames;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get libraryTitle;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @modeWyrName.
  ///
  /// In en, this message translates to:
  /// **'Would You Rather'**
  String get modeWyrName;

  /// No description provided for @modeWyrBlurb.
  ///
  /// In en, this message translates to:
  /// **'Two choices. Everyone picks a side.'**
  String get modeWyrBlurb;

  /// No description provided for @modeWyrRules.
  ///
  /// In en, this message translates to:
  /// **'Read both options aloud. Everyone raises a hand for their pick, then tap each side once per vote. Reveal to see how the room split.'**
  String get modeWyrRules;

  /// No description provided for @modeTotName.
  ///
  /// In en, this message translates to:
  /// **'This or That'**
  String get modeTotName;

  /// No description provided for @modeTotBlurb.
  ///
  /// In en, this message translates to:
  /// **'Rapid-fire picks with big buttons.'**
  String get modeTotBlurb;

  /// No description provided for @modeTriviaName.
  ///
  /// In en, this message translates to:
  /// **'Trivia Blitz'**
  String get modeTriviaName;

  /// No description provided for @modeTriviaBlurb.
  ///
  /// In en, this message translates to:
  /// **'Beat the timer, top the table.'**
  String get modeTriviaBlurb;

  /// No description provided for @modeGuessName.
  ///
  /// In en, this message translates to:
  /// **'Guess the Answer'**
  String get modeGuessName;

  /// No description provided for @modeGuessBlurb.
  ///
  /// In en, this message translates to:
  /// **'Fewer clues, more points.'**
  String get modeGuessBlurb;

  /// No description provided for @modeCustomName.
  ///
  /// In en, this message translates to:
  /// **'Custom Party Pack'**
  String get modeCustomName;

  /// No description provided for @modeCustomBlurb.
  ///
  /// In en, this message translates to:
  /// **'Mix modes into one session.'**
  String get modeCustomBlurb;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up the game'**
  String get setupTitle;

  /// No description provided for @setupHowToPlay.
  ///
  /// In en, this message translates to:
  /// **'How to play'**
  String get setupHowToPlay;

  /// No description provided for @setupCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get setupCategories;

  /// No description provided for @setupCategoriesHint.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one.'**
  String get setupCategoriesHint;

  /// No description provided for @setupRounds.
  ///
  /// In en, this message translates to:
  /// **'Rounds'**
  String get setupRounds;

  /// No description provided for @setupGroupSize.
  ///
  /// In en, this message translates to:
  /// **'Group size'**
  String get setupGroupSize;

  /// No description provided for @setupGroupSizeHint.
  ///
  /// In en, this message translates to:
  /// **'Optional. Limits votes per round to the number of players.'**
  String get setupGroupSizeHint;

  /// No description provided for @setupGroupSizeAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get setupGroupSizeAny;

  /// No description provided for @setupGroupSizeValue.
  ///
  /// In en, this message translates to:
  /// **'{count} players'**
  String setupGroupSizeValue(int count);

  /// No description provided for @setupPlayersDecrease.
  ///
  /// In en, this message translates to:
  /// **'Fewer players'**
  String get setupPlayersDecrease;

  /// No description provided for @setupPlayersIncrease.
  ///
  /// In en, this message translates to:
  /// **'More players'**
  String get setupPlayersIncrease;

  /// No description provided for @setupStart.
  ///
  /// In en, this message translates to:
  /// **'Start game'**
  String get setupStart;

  /// No description provided for @setupQuestionsAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 question} other{{count} questions}}'**
  String setupQuestionsAvailable(int count);

  /// No description provided for @setupFewerQuestions.
  ///
  /// In en, this message translates to:
  /// **'Only {count} questions in these categories, so you\'ll play {count} rounds.'**
  String setupFewerQuestions(int count);

  /// No description provided for @premiumLabel.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premiumLabel;

  /// No description provided for @premiumLocked.
  ///
  /// In en, this message translates to:
  /// **'Premium packs are coming soon.'**
  String get premiumLocked;

  /// No description provided for @regionIndia.
  ///
  /// In en, this message translates to:
  /// **'India'**
  String get regionIndia;

  /// No description provided for @ageTeen.
  ///
  /// In en, this message translates to:
  /// **'13+'**
  String get ageTeen;

  /// No description provided for @playRound.
  ///
  /// In en, this message translates to:
  /// **'Round {round} of {total}'**
  String playRound(int round, int total);

  /// No description provided for @playPrompt.
  ///
  /// In en, this message translates to:
  /// **'Would you rather…'**
  String get playPrompt;

  /// No description provided for @playOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get playOr;

  /// No description provided for @playHint.
  ///
  /// In en, this message translates to:
  /// **'Raise hands, then tap a side once for each vote.'**
  String get playHint;

  /// No description provided for @playVotes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No votes} =1{1 vote} other{{count} votes}}'**
  String playVotes(int count);

  /// No description provided for @playVotesOfPlayers.
  ///
  /// In en, this message translates to:
  /// **'{count} of {players} votes'**
  String playVotesOfPlayers(int count, int players);

  /// No description provided for @playVoteFor.
  ///
  /// In en, this message translates to:
  /// **'Add a vote for: {option}'**
  String playVoteFor(String option);

  /// No description provided for @playUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get playUndo;

  /// No description provided for @playSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get playSkip;

  /// No description provided for @playSkipTooltip.
  ///
  /// In en, this message translates to:
  /// **'Skip this question'**
  String get playSkipTooltip;

  /// No description provided for @playReveal.
  ///
  /// In en, this message translates to:
  /// **'Reveal'**
  String get playReveal;

  /// No description provided for @playNext.
  ///
  /// In en, this message translates to:
  /// **'Next round'**
  String get playNext;

  /// No description provided for @playFinish.
  ///
  /// In en, this message translates to:
  /// **'See results'**
  String get playFinish;

  /// No description provided for @playQuit.
  ///
  /// In en, this message translates to:
  /// **'Quit game'**
  String get playQuit;

  /// No description provided for @playQuitTitle.
  ///
  /// In en, this message translates to:
  /// **'Quit this game?'**
  String get playQuitTitle;

  /// No description provided for @playQuitBody.
  ///
  /// In en, this message translates to:
  /// **'Your progress in this game will be lost.'**
  String get playQuitBody;

  /// No description provided for @playQuitConfirm.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get playQuitConfirm;

  /// No description provided for @playKeepPlaying.
  ///
  /// In en, this message translates to:
  /// **'Keep playing'**
  String get playKeepPlaying;

  /// No description provided for @playSplit.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String playSplit(int percent);

  /// No description provided for @playTie.
  ///
  /// In en, this message translates to:
  /// **'Perfect split!'**
  String get playTie;

  /// No description provided for @playUnanimous.
  ///
  /// In en, this message translates to:
  /// **'Everyone agrees!'**
  String get playUnanimous;

  /// No description provided for @playNoVotes.
  ///
  /// In en, this message translates to:
  /// **'No votes this round.'**
  String get playNoVotes;

  /// No description provided for @resultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get resultsTitle;

  /// No description provided for @resultsSummary.
  ///
  /// In en, this message translates to:
  /// **'{rounds, plural, =1{1 round} other{{rounds} rounds}} · {votes, plural, =1{1 vote} other{{votes} votes}}'**
  String resultsSummary(int rounds, int votes);

  /// No description provided for @resultsDivisive.
  ///
  /// In en, this message translates to:
  /// **'Most divisive'**
  String get resultsDivisive;

  /// No description provided for @resultsUnanimous.
  ///
  /// In en, this message translates to:
  /// **'Most unanimous'**
  String get resultsUnanimous;

  /// No description provided for @resultsAllRounds.
  ///
  /// In en, this message translates to:
  /// **'Every round'**
  String get resultsAllRounds;

  /// No description provided for @resultsSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get resultsSkipped;

  /// No description provided for @resultsPlayAgain.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get resultsPlayAgain;

  /// No description provided for @resultsChangeSetup.
  ///
  /// In en, this message translates to:
  /// **'Change setup'**
  String get resultsChangeSetup;

  /// No description provided for @resultsHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get resultsHome;

  /// No description provided for @resultsSplit.
  ///
  /// In en, this message translates to:
  /// **'{a} – {b}'**
  String resultsSplit(int a, int b);

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get settingsPlay;

  /// No description provided for @settingsBigText.
  ///
  /// In en, this message translates to:
  /// **'Big text'**
  String get settingsBigText;

  /// No description provided for @settingsBigTextBody.
  ///
  /// In en, this message translates to:
  /// **'Larger questions for reading across the room.'**
  String get settingsBigTextBody;

  /// No description provided for @settingsReduceMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get settingsReduceMotion;

  /// No description provided for @settingsReduceMotionBody.
  ///
  /// In en, this message translates to:
  /// **'Turn off animations. Your system setting is always respected.'**
  String get settingsReduceMotionBody;

  /// No description provided for @settingsHaptics.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get settingsHaptics;

  /// No description provided for @settingsHapticsBody.
  ///
  /// In en, this message translates to:
  /// **'A small buzz when you tap a vote.'**
  String get settingsHapticsBody;

  /// No description provided for @settingsShowOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Show the introduction again'**
  String get settingsShowOnboarding;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// No description provided for @settingsPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'MirthMix has no accounts and no analytics in this version. Games, settings and player counts are stored only on this phone.'**
  String get settingsPrivacyBody;

  /// No description provided for @settingsAge.
  ///
  /// In en, this message translates to:
  /// **'Age guidance'**
  String get settingsAge;

  /// No description provided for @settingsAgeBody.
  ///
  /// In en, this message translates to:
  /// **'MirthMix is made for ages 13 and up. Categories marked 13+ include more mature themes, never explicit content.'**
  String get settingsAgeBody;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get settingsLicenses;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);

  /// No description provided for @errorContentTitle.
  ///
  /// In en, this message translates to:
  /// **'Games couldn\'t load'**
  String get errorContentTitle;

  /// No description provided for @errorContentBody.
  ///
  /// In en, this message translates to:
  /// **'The game content on this phone looks damaged. Reinstalling the app usually fixes this.'**
  String get errorContentBody;

  /// No description provided for @errorEmptyCategories.
  ///
  /// In en, this message translates to:
  /// **'No questions are available for the selected categories.'**
  String get errorEmptyCategories;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'That page doesn\'t exist.'**
  String get errorNotFound;

  /// No description provided for @goHome.
  ///
  /// In en, this message translates to:
  /// **'Go home'**
  String get goHome;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
