# Battleplan

Team chat and scheduling for sports teams, free for every team and with no ads. Battleplan does in one app what GroupMe (chat) and TeamReach (schedules and RSVPs) do separately. It runs in any modern browser today; iPhone and Android apps are on the way.

- **Team chat:** photos, reactions, replies, @mentions, pinned messages, and announcements.
- **Direct messages:** one-to-one conversations with anyone you share a team with, from the Messages button or their profile.
- **Profiles:** tap someone's photo to see the teams you share with them, and whether they coach.
- **Schedule and RSVPs:** games, practices, and events with opponents, places, and reminders; Going, Maybe, or Not going in one tap, or from an email a coach sends to whoever hasn't answered; and a private calendar link that keeps Google, Apple, or Outlook Calendar in sync.
- **Polls** and **Documents** for each team.
- **Plays:** directly below Documents in the main navigation, the coach's whiteboard, made for an iPad and good with a mouse, with real baseball, basketball, soccer, and football fields: drag players and the ball to show how a play unfolds, draw routes, play the steps back, and save the plays worth keeping for the team.
- **Players and parents:** adult players answer for themselves; parents and guardians answer for their kids, who don't need accounts.
- **Sign-in:** Continue with Google or Apple; an email and password, or an emailed link, for whoever needs one.
- **Themes:** Gumdrop Pop Dark (the default), Gumdrop Pop Light, and Gumdrop Candy, and each team's color shows in the background of every screen in the team.
- **Import:** bring a team over from GroupMe (messages, photos, files, and events) or TeamSnap (schedule, players, and files), and schedules from TeamReach, GameChanger, or Google Calendar.

## Sites

| | Website | Web app |
|---|---|---|
| **Production** | [getbattleplan.app](https://getbattleplan.app) | [getbattleplan.app/app](https://getbattleplan.app/app) |
| **Dev** | [battleplan-dev-ecce4.web.app](https://battleplan-dev-ecce4.web.app) | [battleplan-dev-ecce4.web.app/app](https://battleplan-dev-ecce4.web.app/app) |

Every push to `main` updates dev's web app once CI passes; **Release to dev** in GitHub Actions deploys everything there, server functions included. Production changes only when someone runs **Release to prod**. **Release iOS** uploads the iPhone and iPad app to TestFlight. **Release Android** uploads the Android app to a Google Play testing track, or to production as a draft.

## Built with

Flutter (web, iOS, and Android from one codebase) and Firebase: Authentication, Firestore, Cloud Functions in TypeScript, Storage, and Hosting. The website in `website/` is plain HTML and CSS, with one small script for its slider. The app and the website use the same three fonts, Lilita One, Fredoka, and Nunito, bundled with the app and served from the site, never from Google Fonts.

## Docs

- [SPEC.md](docs/SPEC.md): what the app does, feature by feature.
- [ARCHITECTURE.md](docs/ARCHITECTURE.md): how it's built.
- [ROADMAP.md](docs/ROADMAP.md): what's done and what's next.
- [DEVELOPMENT.md](docs/DEVELOPMENT.md): running it locally with the Firebase emulators, testing, and releasing.
- [STORE-CHECKLIST.md](docs/STORE-CHECKLIST.md): what has to be done before the App Store and Google Play will approve the apps.
- [STORE-LISTING.md](docs/STORE-LISTING.md): the App Store listing, age rating answers, and App Review notes, ready to paste in.
- [STORE-LISTING-PLAY.md](docs/STORE-LISTING-PLAY.md): the Google Play listing and App content answers, ready to paste in.
