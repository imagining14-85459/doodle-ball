extends Node

const SKINS := ["blue", "red", "green", "purple", "orange", "pink", "black", "gold"]

var p1_skin := "blue"
var p2_skin := "red"

var music := AudioStreamPlayer.new()


func _ready() -> void:
	music.stream = load("res://music/calm_loop.ogg")
	music.volume_db = -10.0        
	add_child(music)
	music.finished.connect(music.play) 
	music.play()

	add_default_key("p1_power", KEY_E)
	add_default_key("p2_power", KEY_PERIOD)


func add_default_key(action_name: String, key: Key) -> void:
	if InputMap.has_action(action_name):
		return 
	InputMap.add_action(action_name)
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action_name, event)



func skin_path(skin: String, pose: String) -> String:
	return "res://art/skins/%s/%s.png" % [skin, pose]


func next_skin(current: String, step: int) -> String:
	var i := SKINS.find(current)
	i = wrapi(i + step, 0, SKINS.size()) 
	return SKINS[i]
