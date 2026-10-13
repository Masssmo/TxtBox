class_name DialogueParser
extends RefCounted
## Turns a plain-text script into a list of commands for the player.
##
## Format (one command per line):
##   # comment
##   Alice: Hello! BBCode like [color=yellow]this[/color] works.
##   Just text with no "Name:" prefix is narration.
##   @wait 1.5        -> pause for 1.5 seconds
##   @speed 20        -> characters per second from here on
##   @clear           -> hide the dialogue box until the next line


static func parse_file(path: String) -> Array[Dictionary]:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open dialogue script '%s': %s" % [path, error_string(FileAccess.get_open_error())])
		return []
	return parse(file.get_as_text())


static func parse(source: String) -> Array[Dictionary]:
	var commands: Array[Dictionary] = []
	for raw_line in source.split("\n"):
		var line := raw_line.strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue

		if line.begins_with("@"):
			var parts := line.substr(1).split(" ", false)
			match parts[0]:
				"wait":
					commands.append({"type": "wait", "seconds": float(parts[1])})
				"speed":
					commands.append({"type": "speed", "cps": float(parts[1])})
				"clear":
					commands.append({"type": "clear"})
				_:
					push_warning("Unknown directive: " + line)
			continue

		var speaker := ""
		var text := line
		var colon := line.find(": ")
		if colon > 0:
			speaker = line.substr(0, colon)
			text = line.substr(colon + 2)
		commands.append({"type": "line", "speaker": speaker, "text": text})
	return commands
