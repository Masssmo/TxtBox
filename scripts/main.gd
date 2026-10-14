extends Control
## Loads a dialogue script and plays it through the dialogue box from start to finish.
##
## Pick a different script from the command line with:
##   godot --path . -- --script=path/to/script.txt

@export_file("*.txt") var script_path := "res://dialogue/example.txt"
## How long a fully typed line stays on screen before the next one starts.
@export var hold_after_line := 1.5
## Quit when the script ends, so a Movie Maker recording stops on its own.
@export var quit_when_done := true

@onready var _box: DialogueBox = %DialogueBox


func _ready() -> void:
	var path := _script_path_from_cmdline()
	var commands := DialogueParser.parse_file(path)
	await _play(commands)
	if quit_when_done:
		get_tree().quit()


func _play(commands: Array[Dictionary]) -> void:
	for command in commands:
		match command.type:
			"line":
				_box.show_line(command.text)
				await _box.line_finished
				await get_tree().create_timer(hold_after_line).timeout
			"wait":
				await get_tree().create_timer(command.seconds).timeout
			"speed":
				_box.characters_per_second = command.cps
			"clear":
				_box.clear()


func _script_path_from_cmdline() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--script="):
			return arg.trim_prefix("--script=")
	return script_path
