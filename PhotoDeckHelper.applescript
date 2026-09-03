-- PhotoDeck: launches HTTP server, then polls for build requests and
-- runs osascript itself so Apple Events come from this applet process.

on run
	set resources_path to POSIX path of (path to resource "photodeck-server")
	set server_bin to resources_path
	set script_path to POSIX path of (path to resource "build_photo_deck.applescript")

	-- start the node server in background
	do shell script quoted form of server_bin & " > /tmp/photodeck-server.log 2>&1 &"

	display notification "PhotoDeck is running. Go to the website to build your deck." with title "PhotoDeck"

	-- poll for build trigger files written by the server
	repeat
		delay 1
		try
			set triggerFile to "/tmp/photodeck-trigger.txt"
			set triggerContents to do shell script "cat " & quoted form of triggerFile & " 2>/dev/null || echo ''"
			if triggerContents is not "" then
				-- format: srcFolder|outPath
				set AppleScript's text item delimiters to "|"
				set parts to text items of triggerContents
				set AppleScript's text item delimiters to ""
				set srcFolder to item 1 of parts
				set outPath to item 2 of parts
				-- clear trigger immediately
				do shell script "rm -f " & quoted form of triggerFile
				-- run the keynote script as this applet (gets Apple Events permission)
				do shell script "osascript " & quoted form of script_path & " " & quoted form of srcFolder & " " & quoted form of outPath
				-- signal completion to the server
				do shell script "echo 'done:' " & quoted form of outPath & " > /tmp/photodeck-result.txt"
			end if
		end try
	end repeat
end run
