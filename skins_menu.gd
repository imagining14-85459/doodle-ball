extends Control
@onready var p1_preview: TextureRect = $Player1/Preview
@onready var p1_name: Label = $Player1/SkinName
@onready var p2_preview: TextureRect = $Player2/Preview
@onready var p2_name: Label = $Player2/SkinName


func _ready() -> void:
	update_previews()


func update_previews() -> void:
	p1_preview.texture = load(Global.skin_path(Global.p1_skin, "reach"))
	p1_name.text = Global.p1_skin.capitalize()
	p2_preview.texture = load(Global.skin_path(Global.p2_skin, "reach"))
	p2_name.text = Global.p2_skin.capitalize()


func _on_p1_left_button_pressed() -> void:
	Global.p1_skin = Global.next_skin(Global.p1_skin, -1)
	update_previews()


func _on_p1_right_button_pressed() -> void:
	Global.p1_skin = Global.next_skin(Global.p1_skin, 1)
	update_previews()


func _on_p2_left_button_pressed() -> void:
	Global.p2_skin = Global.next_skin(Global.p2_skin, -1)
	update_previews()


func _on_p2_right_button_pressed() -> void:
	Global.p2_skin = Global.next_skin(Global.p2_skin, 1)
	update_previews()


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
