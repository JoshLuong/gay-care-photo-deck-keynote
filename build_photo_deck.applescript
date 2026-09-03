-- Builds a Keynote deck with one slide per JPEG in a folder.
-- Layout per slide: image aspect-fit, flush-left, filename caption directly
-- under it; an empty notes text box flush-right for the user to type into.
--
-- Usage: osascript build_photo_deck.applescript /path/to/photo/folder [output.key path]
-- If the output path is omitted, saves as "<folder name>.key" inside the source folder.

on run argv
	if (count of argv) is 0 then
		error "Usage: osascript build_photo_deck.applescript /path/to/photo/folder [output.key path]"
	end if

	set srcFolder to item 1 of argv
	if srcFolder does not end with "/" then set srcFolder to srcFolder & "/"
	set folderAlias to POSIX file srcFolder as alias

	-- derive folder name for the default output filename
	set trimmedPath to text 1 thru -2 of srcFolder
	set AppleScript's text item delimiters to "/"
	set pathParts to text items of trimmedPath
	set folderName to item -1 of pathParts
	set AppleScript's text item delimiters to ""

	if (count of argv) > 1 then
		set outPosixPath to item 2 of argv
	else
		set outPosixPath to srcFolder & folderName & ".key"
	end if

	-- gather jpg/jpeg/tiff/png files, sorted alphabetically by filename
	tell application "Finder"
		set matchingFiles to sort (every file of folder folderAlias whose name extension is in {"jpg", "jpeg", "JPG", "JPEG", "tif", "tiff", "TIF", "TIFF", "png", "PNG"}) by name
		set imageFiles to {}
		repeat with f in matchingFiles
			set end of imageFiles to (name of f)
		end repeat
	end tell

	if (count of imageFiles) is 0 then
		error "No image files found in " & srcFolder
	end if

	-- convert non-JPEG images to JPEG in a temp dir (quality 95)
	set tmpDir to do shell script "mktemp -d"
	set origNames to {}
	set useNames to {}
	set useDirs to {}
	repeat with fName in imageFiles
		set ext to ""
		set dotPos to 0
		repeat with c from (length of fName) to 1 by -1
			if character c of fName is "." then
				set dotPos to c
				exit repeat
			end if
		end repeat
		if dotPos > 0 then set ext to text (dotPos + 1) thru -1 of fName
		set lext to do shell script "echo " & quoted form of ext & " | tr '[:upper:]' '[:lower:]'"
		if lext is in {"tif", "tiff", "png"} then
			set baseName to text 1 thru (dotPos - 1) of fName
			set convertedName to baseName & ".jpg"
			do shell script "sips -s format jpeg -s formatOptions 95 " & quoted form of (srcFolder & fName) & " --out " & quoted form of (tmpDir & "/" & convertedName)
			set end of origNames to fName
			set end of useNames to convertedName
			set end of useDirs to tmpDir & "/"
		else
			set end of origNames to fName
			set end of useNames to fName
			set end of useDirs to srcFolder
		end if
	end repeat

	-- layout constants (points)
	set marginX to 40
	set marginY to 40
	set gapX to 24
	set captionH to 26
	set captionGap to 12
	set captionFontSize to 14

	tell application "Keynote"
		activate
		set newDoc to make new document with properties {document theme:theme "White"}
		set blankLayout to slide layout "Blank" of newDoc

		tell newDoc
			set slideW to width
			set slideH to height
		end tell

		set halfW to (slideW - (marginX * 2) - gapX) / 2
		set boxH to slideH - (marginY * 2)
		set imgAreaH to boxH - captionH - captionGap
		set leftX to marginX
		set rightX to marginX + halfW + gapX

		set idx to 0
		repeat with i from 1 to count of useNames
			set idx to i
			set fName to item i of useNames
			set fullPath to (item i of useDirs) & fName

			-- use original filename (without ext) for caption
			set capName to item i of origNames
			set dotPos to 0
			repeat with c from (length of capName) to 1 by -1
				if character c of capName is "." then
					set dotPos to c
					exit repeat
				end if
			end repeat
			if dotPos > 0 then set capName to text 1 thru (dotPos - 1) of capName

			tell newDoc
				if idx is 1 then
					set targetSlide to slide 1
				else
					set targetSlide to make new slide at end of slides
				end if
				tell slide idx to set base layout to blankLayout

				tell targetSlide
					-- image: aspect-fit inside the left box, no cropping/stretching
					set imgObj to make new image with properties {file:(fullPath as POSIX file)}
					set natW to width of imgObj
					set natH to height of imgObj
					set scaleFactor to halfW / natW
					if (imgAreaH / natH) < scaleFactor then set scaleFactor to imgAreaH / natH
					set newW to natW * scaleFactor
					set newH to natH * scaleFactor
					set width of imgObj to newW
					set height of imgObj to newH
					set position of imgObj to {leftX, marginY + ((imgAreaH - newH) / 2)}

					-- caption: original filename (without ext), directly under the actual (scaled) image
					set captionBox to make new text item with properties {object text:capName}
					set position of captionBox to {leftX, marginY + ((imgAreaH - newH) / 2) + newH + captionGap}
					set width of captionBox to halfW
					set height of captionBox to captionH
					set size of object text of captionBox to captionFontSize

					-- notes box: empty, flush-right, for the user to fill in later
					set notesBox to make new text item with properties {object text:""}
					set position of notesBox to {rightX, marginY}
					set width of notesBox to halfW
					set height of notesBox to boxH
				end tell
			end tell
		end repeat

		save newDoc in POSIX file outPosixPath
	end tell

	do shell script "rm -rf " & quoted form of tmpDir
	return "Created " & idx & "-slide deck at " & outPosixPath
end run
