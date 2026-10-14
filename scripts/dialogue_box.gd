class_name DialogueBox
extends PanelContainer
## A dialogue box that reveals its text one character at a time.

signal character_typed(character: String)
signal line_finished

@export var characters_per_second := 40.0
## Extra pause (in seconds) after these characters, for a more natural rhythm.
@export var punctuation_pauses := {".": 0.3, "!": 0.3, "?": 0.3, ",": 0.12, ";": 0.12}

@onready var _name_label: Label = %NameLabel
@onready var _text_label: RichTextLabel = %TextLabel
@onready var _blip: AudioStreamPlayer = %Blip

var _plain_text := ""
var _progress := 0.0
var _pause_left := 0.0
var _typing := false


func _ready() -> void:
	clear()


func show_line(bbcode_text: String) -> void:
	show()
	#_name_label.text = speaker
	#_name_label.visible = not speaker.is_empty()
	_text_label.text = bbcode_text
	_text_label.visible_characters = 0
	# visible_characters counts characters without BBCode tags, so index into the parsed text.
	_plain_text = _text_label.get_parsed_text()
	_progress = 0.0
	_pause_left = 0.0
	_typing = true


func clear() -> void:
	_typing = false
	_name_label.text = ""
	_text_label.text = ""
	hide()


func is_typing() -> bool:
	return _typing


## Reveals the rest of the line immediately.
func skip() -> void:
	if _typing:
		_text_label.visible_characters = -1
		_finish()


func _process(delta: float) -> void:
	if not _typing:
		return
	if _text_label.visible_characters >= _plain_text.length():
		_finish()
		return
	if _pause_left > 0.0:
		_pause_left -= delta
		return

	_progress += delta * characters_per_second
	while _progress >= 1.0 and _typing and _pause_left <= 0.0:
		_progress -= 1.0
		_reveal_next_character()


func _reveal_next_character() -> void:
	var index := _text_label.visible_characters
	_text_label.visible_characters = index + 1
	var character := _plain_text[index]
	character_typed.emit(character)

	if _blip.stream and character.strip_edges() != "":
		_blip.play()

	if character in punctuation_pauses:
		_pause_left = punctuation_pauses[character]
		_progress = 0.0

	if _text_label.visible_characters >= _plain_text.length():
		_finish()


func _finish() -> void:
	_typing = false
	line_finished.emit()
