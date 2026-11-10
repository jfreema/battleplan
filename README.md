# Battleplan

Team chat and scheduling for sports teams, free for every team and with no ads. Battleplan does in one app what GroupMe (chat) and TeamReach (schedules and RSVPs) do separately. It's [on the App Store](https://apps.apple.com/app/id6823884728) for iPhone and iPad and runs in any modern browser; an Android app is on the way.

- **Teams and Profile:** every team you're on in one list, each with a back arrow home, a Team tab for its roster, invites, and dues, and a gear for Team settings: the color scheme you see it in, its notifications and calendar link, and Admin settings for its admins; your default color scheme on Teams; your icon (a photo, or your initials on a color you pick), name, a time zone that stays put when you travel, and settings on Profile.
- **Team chat:** photos, reactions, replies, @mentions, pinned messages, announcements, and search by the words in a message.
- **Direct messages:** one-to-one conversations with anyone you share a team with, from the Messages button or their profile.
- **Profiles:** tap someone's photo to see the teams you share with them, and whether they coach.
- **Schedule and RSVPs:** games, practices, and events with opponents, places, and reminders; Going, Maybe, or Not going in one tap, or from an email a coach sends to whoever hasn't answered; assignments like snacks, drinks, and scorekeeper that families volunteer for; and a private calendar link that keeps Google, Apple, or Outlook Calendar in sync.
- **Dues:** admins track who owes and who's paid for uniforms, team fees, and the like, in full or a part at a time, see who owes what by due and by person, and share how to pay with Venmo, Cash App, or Apple Cash; the money goes person to person, never through Battleplan, and only admins see what anyone else owes.
- **Polls**, **Documents**, and **Photos** (every photo shared in the chat) for each team.
- **Plays:** directly below Documents in the main navigation, the coach's whiteboard, made for an iPad and good with a mouse, with real baseball, basketball, soccer, and football fields: drag players and the ball to show how a play unfolds, draw routes, play the steps back, and save the plays worth keeping for the team, then post one to the chat, or save or share it as an animated GIF.
- **Players and parents:** on a team, RSVPs are for players: adult players answer for themselves, and parents and guardians answer for their kids, who don't need accounts.
- **Groups:** besides teams, plain groups for anything else, as simple as they can be: the same chat, schedule, RSVPs, and documents, but no players or Plays, and everyone answers for themselves. A group's owner can make it a team later.
- **New seasons:** a team's owner starts the next season as a new team, bringing the players, parents, coaches, and anyone else they choose, who are on it at once with nothing to accept; the old season is archived with its chat, photos, and schedule.
- **Sign-in:** Continue with Google or Apple; an email and password, or an emailed link, for whoever needs one.
- **Color schemes:** one look, Open Field, in five schemes: Dark (the default), Army green, Light, Navy, and Light blue. A team's admins set its default; each person can pick their own for a team or group, and a default for the rest.
- **Import:** bring a team over from GroupMe (messages, photos, files, and events) or TeamSnap (schedule, players, and files), and schedules from TeamReach, GameChanger, or Google Calendar.

## Sites

| | Website | Web app |
|---|---|---|
| **Production** | [getbattleplan.app](https://getbattleplan.app) | [getbattleplan.app/app](https://getbattleplan.app/app) |
| **Dev** | [battleplan-dev-ecce4.web.app](https://battleplan-dev-ecce4.web.app) | [battleplan-dev-ecce4.web.app/app](https://battleplan-dev-ecce4.web.app/app) |

Every push to `main` deploys everything to dev once CI passes, server functions included; **Release to dev** in GitHub Actions does the same by hand, for any branch. Production changes only when someone runs **Release to prod**. **Release iOS** uploads the iPhone and iPad app to TestFlight. **Release Android** uploads the Android app to a Google Play testing track, or to production as a draft.

## Built with

Flutter (web, iOS, and Android from one codebase) and Firebase: Authentication, Firestore, Cloud Functions in TypeScript, Storage, and Hosting. The website in `website/` is plain HTML and CSS in the app's Open Field look; its color scheme picker is pure CSS, with one optional line of script. The app and the website use the same fonts, Lilita One, Fredoka, and Nunito, with Black Ops One on the app's header eyebrows and the site's, bundled with the app and served from the site, as are the web app's fonts for emoji and other scripts: never from Google Fonts.

## Docs

- [SPEC.md](docs/SPEC.md): what the app does, feature by feature.
- [ARCHITECTURE.md](docs/ARCHITECTURE.md): how it's built.
- [ROADMAP.md](docs/ROADMAP.md): what's done and what's next.
- [DEVELOPMENT.md](docs/DEVELOPMENT.md): running it locally with the Firebase emulators, testing, and releasing.
- [STORE-CHECKLIST.md](docs/STORE-CHECKLIST.md): what has to be done before the App Store and Google Play will approve the apps.
- [STORE-LISTING.md](docs/STORE-LISTING.md): the App Store listing, age rating answers, and App Review notes, ready to paste in.
- [STORE-LISTING-PLAY.md](docs/STORE-LISTING-PLAY.md): the Google Play listing and App content answers, ready to paste in.
