#!/usr/bin/env bash
# Undoes #48's one-time change, should it ever need undoing: puts the
# reminder the day before back on the teams it switched to No reminders,
# where they're still on No reminders (teams whose admins chose something
# since are left alone). It reads the teams from ops/migrations and records
# what it put back there. Claude runs it from the owner's Mac, signed in to
# Google Cloud with the project's owner account:
#
#   gcloud auth application-default login
#   tools/undo_reminder_defaults.sh battleplan-prod
set -euo pipefail
cd "$(dirname "$0")/.."

project="${1:?Usage: tools/undo_reminder_defaults.sh <project id, e.g. battleplan-prod>}"

npm --prefix functions run build >/dev/null
GCLOUD_PROJECT="$project" node -e "
const { undoReminderDefaultsOff } = require('./functions/lib/teams/migrations.js');
undoReminderDefaultsOff().then(
  (back) => console.log('Put the reminder the day before back on ' + back.length + ' teams: ' + back.join(', ')),
  (e) => { console.error(e); process.exit(1); },
);
"
