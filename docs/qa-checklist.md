# Manual QA checklist

Run on a real Android phone (ideally a small, low-end one) before each release. Tick every box; note the device, Android version and app version.

## First launch

- [ ] Onboarding shows three pages; Next, Skip and "Let's play" all reach Home.
- [ ] The age note (13+) is visible on onboarding.
- [ ] Relaunching the app goes straight to Home.
- [ ] Settings → "Show the introduction again" shows onboarding again.

## Would You Rather — Quick play

- [ ] Home → Quick play starts round 1 of 10 immediately.
- [ ] The screen stays on while playing (wait longer than the screen-off timeout).
- [ ] Tapping each option adds a vote; the counter updates; Undo removes the last vote.
- [ ] Reveal shows percentages and a short verdict (split / everyone agrees / no votes); voting is locked after reveal.
- [ ] Skip replaces the question without using up a round.
- [ ] Next round advances; the last round says "See results".
- [ ] Results show rounds and votes, most divisive / most unanimous (when there are enough votes) and every round's split.
- [ ] Play again starts a new shuffle with the same settings; Change setup opens setup; Home returns home.

## Setup

- [ ] All free categories can be ticked; the premium category shows a lock and can't be ticked.
- [ ] The 13+ category shows its content note.
- [ ] Deselecting every category disables Start.
- [ ] 5 / 10 / 15 / 20 rounds work; choosing more rounds than questions shows the explanation.
- [ ] Group size: "Any" by default; with 3 players, a 4th vote is ignored and the counter shows "3 of 3 votes".
- [ ] The last setup is remembered next time.

## Interruptions

- [ ] Mid-game, press Home, open other apps, return: the game is unchanged.
- [ ] Mid-game, swipe the app away from recents, relaunch: Home offers "Resume" with the right round; votes cast are kept.
- [ ] Discard on Home removes the saved game.
- [ ] System back and the close button both ask before quitting; "Keep playing" returns to the same state.
- [ ] Rotate the phone (if rotation is on): nothing is lost.
- [ ] Receive a call mid-game: the game is unchanged afterwards.

## Accessibility and display

- [ ] TalkBack: options read as "Add a vote for: …" with the current count; reveal reads percentages.
- [ ] System font size at maximum: questions remain readable and nothing is cut off.
- [ ] Big text setting enlarges text further.
- [ ] Reduce motion (in-app and the system "Remove animations") turns off transitions and the reveal animation.
- [ ] Dark theme and light theme both look right; theme setting follows the system when set to System.
- [ ] Every tappable control is comfortable to hit with a thumb.

## Website

- [ ] Home, Games, Would You Rather, Privacy and Terms load on a phone and a desktop.
- [ ] The landing-page demo works and "Another one" shows a different question.
- [ ] Privacy and Terms clearly say they are drafts awaiting legal review.
