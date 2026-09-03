#!/bin/bash
APP="$HOME/Applications/PhotoDeck.app"
SYSTEM_APP="/Applications/PhotoDeck.app"

# Find wherever they installed it
if [ -d "$SYSTEM_APP" ]; then
  TARGET="$SYSTEM_APP"
elif [ -d "$APP" ]; then
  TARGET="$APP"
else
  osascript -e 'display alert "PhotoDeck.app not found" message "Please unzip PhotoDeck.app.zip and drag PhotoDeck.app to your Applications folder, then run this script again."'
  exit 1
fi

xattr -cr "$TARGET"
open "$TARGET"
osascript -e 'display notification "PhotoDeck is ready. Return to the website to drag your photos." with title "PhotoDeck Installed"'
