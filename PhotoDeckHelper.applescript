-- PhotoDeck URL scheme handler
-- Registered as photodeck:// — triggered by the web app
-- URL format: photodeck://build?folder=/path/to/photos&output=/path/to/out.key

on open location this_URL
	-- parse query string
	set x to the offset of "?" in this_URL
	if x is 0 then return
	set arg_string to text from (x + 1) to -1 of this_URL

	set folder_path to ""
	set output_path to ""

	set AppleScript's text item delimiters to "&"
	set pairs to every text item of arg_string
	set AppleScript's text item delimiters to ""

	repeat with pair in pairs
		set AppleScript's text item delimiters to "="
		set kv to every text item of pair
		set AppleScript's text item delimiters to ""
		if (count of kv) is 2 then
			set k to item 1 of kv
			set v to my url_decode(item 2 of kv)
			if k is "folder" then set folder_path to v
			if k is "output" then set output_path to v
		end if
	end repeat

	if folder_path is "" then return

	if output_path is "" then
		-- default: Desktop/<foldername>.key
		set AppleScript's text item delimiters to "/"
		set parts to every text item of folder_path
		set AppleScript's text item delimiters to ""
		set fname to item -1 of parts
		if fname is "" then set fname to item ((count of parts) - 1) of parts
		set output_path to (POSIX path of (path to desktop)) & fname & ".key"
	end if

	set script_path to POSIX path of (path to resource "build_photo_deck.applescript")
	do shell script "osascript " & quoted form of script_path & " " & quoted form of folder_path & " " & quoted form of output_path

	display notification "Saved to " & output_path with title "PhotoDeck" subtitle "Keynote deck ready"
end open location

on url_decode(str)
	set s to str
	-- replace + with space
	set AppleScript's text item delimiters to "+"
	set parts to every text item of s
	set AppleScript's text item delimiters to " "
	set s to parts as string
	set AppleScript's text item delimiters to ""
	-- basic %XX decode via shell
	try
		set s to do shell script "python3 -c \"import sys,urllib.parse; print(urllib.parse.unquote(sys.argv[1]))\" " & quoted form of s
	end try
	return s
end url_decode
