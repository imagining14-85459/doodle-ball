extends Control

@onready var label: Label = $Label
@onready var bar: ProgressBar = $Bar


func show_state(value: float, text: String, lit: bool) -> void:
	bar.value = value
	label.text = text
	modulate = Color(1, 1, 1, 1) if lit else Color(1, 1, 1, 0.4)


func align_right() -> void:
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	bar.fill_mode = ProgressBar.FILL_END_TO_BEGIN
