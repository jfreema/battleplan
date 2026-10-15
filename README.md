# Battleplan

Team chat and scheduling for sports teams, free for every team and with no ads. Battleplan does in one app what GroupMe (chat) and TeamReach (schedules and RSVPs) do separately. It runs in any modern browser today; iPhone and Android apps are on the way.

- **Team chat:** photos, reactions, replies, @mentions, pinned messages, and announcements.
- **Schedule and RSVPs:** games, practices, and events with opponents, places, and reminders; Going, Maybe, or Not going in one tap.
- **Polls** and **Documents** for each team.
- **Whiteboard:** directly below Documents in the main navigation, the coach's whiteboard, made for an iPad and good with a mouse, with real baseball, basketball, soccer, and football fields: drag players and the ball to show how a play unfolds, draw routes, play the steps back, and save the plays worth keeping for the team.
- **Players and parents:** adult players answer for themselves; parents and guardians answer for their kids, who don't need accounts.
- **Import:** bring a team over from GroupMe (messages, photos, files, and events) or TeamSnap (schedule, players, and files), and schedules from TeamReach, GameChanger, or Google Calendar.

## Sites

| | Website | Web app |
|---|---|---|
| **Production** | [getbattleplan.app](https://getbattleplan.app) | [getbattleplan.app/app](https://getbattleplan.app/app) |
| **Dev** | [battleplan-dev-ecce4.web.app](https://battleplan-dev-ecce4.web.app) | [battleplan-dev-ecce4.web.app/app](https://battleplan-dev-ecce4.web.app/app) |

Every push to `main` updates dev's web app once CI passes; **Release to dev** in GitHub Actions deploys everything there, server functions included. Production changes only when someone runs **Release to prod**.

## Built with

Flutter (web, iOS, and Android from one codebase) and Firebase: Authentication, Firestore, Cloud Functions in TypeScript, Storage, and Hosting. The website in `website/` is plain HTML and CSS.

## Docs

- [SPEC.md](docs/SPEC.md): what the app does, feature by feature.
- [ARCHITECTURE.md](docs/ARCHITECTURE.md): how it's built.
- [ROADMAP.md](docs/ROADMAP.md): what's done and what's next.
- [DEVELOPMENT.md](docs/DEVELOPMENT.md): running it locally with the Firebase emulators, testing, and releasing.
