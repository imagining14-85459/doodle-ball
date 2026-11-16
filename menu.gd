extends Control



func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_skins_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/skins.tscn")


func _on_how_to_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/how_to_play.tscn")
