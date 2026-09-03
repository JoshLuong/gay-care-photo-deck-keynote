-- PhotoDeck: launches the bundled HTTP server on startup
-- Server listens on localhost:7890, receives files from the web app,
-- runs build_photo_deck.applescript, and returns the .key file.

on run
	set server_bin to POSIX path of (path to resource "photodeck-server")
	do shell script quoted form of server_bin & " > /tmp/photodeck-server.log 2>&1 &"
	display notification "PhotoDeck is running. Go to the website to build your deck." with title "PhotoDeck"
end run
