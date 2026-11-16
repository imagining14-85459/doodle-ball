extends Node2D


const WIN_SCORE := 11
const THREE_POINT_DISTANCE := 380.0  
const STEAL_CHANCE := 0.4           
const BLOCK_STUN := 0.5           
const ANKLE_STUN := 1.0             


const BOUNCE_UNLOCK_SCORE := 9  
const BOUNCE_FILL_TIME := 6.0
const BOUNCE_DURATION := 8.0     
const BOUNCE_SPEED := 1.35       
const PUNCH_RANGE := 90.0
const PUNCH_STUN := 1.5

var BounceMeterScene := preload("res://scenes/bounce_meter.tscn")

@onready var p1: Player = $Player1
@onready var p2: Player = $Player2
@onready var ball = $Ball
@onready var left_rim: Marker2D = $LeftHoop/RimCenter
@onready var right_rim: Marker2D = $RightHoop/RimCenter
@onready var score_label: Label = $UI/ScoreLabel
@onready var message_label: Label = $UI/MessageLabel
@onready var win_panel: Panel = $UI/WinPanel
@onready var win_label: Label = $UI/WinPanel/WinLabel

var score1 := 0
var score2 := 0
var waiting := false   
var wait_time := 0.0
var next_player: Player
var message_time := 0.0

var bounce_charge := [0.0, 0.0]  
var bounce_time := [0.0, 0.0] 
var punch_used := [false, false] 
var meters := [] 


func _ready() -> void:
	p1.set_skin(Global.p1_skin)
	p2.set_skin(Global.p2_skin)
	win_panel.hide()
	update_score()
	start_possession(p1)

	
	for i in 2:
		var meter = BounceMeterScene.instantiate()
		$UI.add_child(meter)
		meters.append(meter)
	meters[0].position = Vector2(14, 44)       
	meters[1].position = Vector2(1280 - 14 - 270, 44)  
	meters[1].align_right()

	p1.power.connect(_on_player_power)
	p2.power.connect(_on_player_power)


func _process(delta: float) -> void:
	message_time -= delta
	message_label.visible = message_time > 0.0
	update_bounce_back(delta)

	if waiting and wait_time > 0.0:
		wait_time -= delta
		if wait_time <= 0.0:
			start_possession(next_player)


func _physics_process(_delta: float) -> void:
	if waiting or ball.holder != null:
		return
	if ball.in_flight:
		check_blocks()
	else:
		check_pickups()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  
		get_tree().change_scene_to_file("res://scenes/menu.tscn")



func start_possession(player: Player) -> void:
	var other := p2 if player == p1 else p1
	player.global_position = Vector2(640 - player.attack_dir * 120, 520)
	other.global_position = Vector2(640 + player.attack_dir * 90, 520)
	for p in [p1, p2]:
		p.velocity = Vector2.ZERO
		p.stun_time = 0.0
		p.end_spin()
		p.facing = p.attack_dir
	give_ball(player)
	waiting = false


func give_ball(player: Player) -> void:
	var other := p2 if player == p1 else p1
	other.has_ball = false
	other.charging = false
	player.has_ball = true
	ball.hold(player)


func near_ball(player: Player) -> bool:
	var d: Vector2 = ball.global_position - player.global_position
	return absf(d.x) < 50.0 and d.y > -110.0 and d.y < 95.0


func check_pickups() -> void:
	for player in [p1, p2]:
		if player.stun_time <= 0.0 and near_ball(player):
			give_ball(player)
			return


func check_blocks() -> void:
	if ball.linear_velocity.y >= 0.0:
		return 
	for player in [p1, p2]:
		if player != ball.shooter and not player.is_on_floor() and near_ball(player):
			ball.linear_velocity = Vector2(-ball.shooter.attack_dir * 300.0, 100.0)
			ball.in_flight = false
			ball.shooter.stun(BLOCK_STUN)
			show_message("BLOCKED!")
			return


func _on_player_shoot(player: Player, charge: float) -> void:
	if ball.holder != player:
		return
	var rim := right_rim if player.attack_dir == 1 else left_rim
	var target := rim.global_position + Vector2(0, -8)
	var diff: Vector2 = target - ball.global_position

	var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity") * ball.gravity_scale
	var time := clampf(0.7 + absf(diff.x) / 1500.0, 0.75, 1.35)
	var shot_velocity := Vector2(diff.x / time, (diff.y - 0.5 * gravity * time * time) / time)

	if charge < Player.SWEET_MIN or charge > Player.SWEET_MAX:
		shot_velocity *= 1.0 + (charge - 0.81) * 0.3

	player.has_ball = false
	ball.shooter = player
	ball.shot_distance = absf(player.global_position.x - rim.global_position.x)
	ball.throw(shot_velocity)

func _on_player_steal(player: Player) -> void:
	var other := p2 if player == p1 else p1

	player.facing = 1 if other.global_position.x > player.global_position.x else -1
	if ball.holder != other or player.stun_time > 0.0 or waiting:
		return
	if player.global_position.distance_to(other.global_position) > 80.0:
		return
	if other.spin_time > 0.0:
		player.stun(ANKLE_STUN)
		show_message("ANKLES BROKEN!")
		return
	if randf() < STEAL_CHANCE:
		give_ball(player)
		show_message("STOLEN!")


func index_of(player: Player) -> int:
	return 0 if player == p1 else 1

func can_bounce_back(i: int) -> bool:
	var mine: int = score1 if i == 0 else score2
	var theirs: int = score2 if i == 0 else score1
	return mine < theirs and theirs >= BOUNCE_UNLOCK_SCORE


func update_bounce_back(delta: float) -> void:
	var players := [p1, p2]
	var power_keys := ["E", "."]  
	for i in 2:
		var player: Player = players[i]
		if bounce_time[i] > 0.0:
			bounce_time[i] -= delta
			player.speed_boost = BOUNCE_SPEED
			player.bounce_active = true
			var punch_text := "  punch used" if punch_used[i] else "  press %s to PUNCH" % power_keys[i]
			meters[i].show_state(bounce_time[i] / BOUNCE_DURATION, "BOUNCE BACK ON!" + punch_text, true)
		else:
			player.speed_boost = 1.0
			player.bounce_active = false
			if can_bounce_back(i) and not waiting:
				bounce_charge[i] = minf(bounce_charge[i] + delta / BOUNCE_FILL_TIME, 1.0)
			if bounce_charge[i] >= 1.0 and can_bounce_back(i):
				meters[i].show_state(1.0, "READY! press %s" % power_keys[i], true)
			elif can_bounce_back(i):
				meters[i].show_state(bounce_charge[i], "BOUNCE BACK charging...", true)
			else:
				meters[i].show_state(bounce_charge[i], "BOUNCE BACK (locked)", false)

func _on_player_power(player: Player) -> void:
	var i := index_of(player)
	if waiting or player.stun_time > 0.0:
		return
	if bounce_time[i] <= 0.0:
		if bounce_charge[i] >= 1.0 and can_bounce_back(i):
			bounce_charge[i] = 0.0
			bounce_time[i] = BOUNCE_DURATION
			punch_used[i] = false
			show_message("P%d BOUNCE BACK!" % player.player_number)
		return
	if punch_used[i]:
		return
	var other := p2 if player == p1 else p1
	player.facing = 1 if other.global_position.x > player.global_position.x else -1
	player.punch_animation()
	if player.global_position.distance_to(other.global_position) > PUNCH_RANGE:
		return 
	punch_used[i] = true
	other.stun(PUNCH_STUN)
	if ball.holder == other:
		give_ball(player)
	show_message("FOUL! POW!")





func _on_left_score_zone_body_entered(body: Node) -> void:
	if body == ball:
		try_score(p2)



func _on_right_score_zone_body_entered(body: Node) -> void:
	if body == ball:
		try_score(p1)


func try_score(scorer: Player) -> void:
	if waiting or ball.linear_velocity.y <= 0.0:
		return   
	var points := 2
	if ball.shooter == scorer and ball.shot_distance > THREE_POINT_DISTANCE:
		points = 3
	if scorer == p1:
		score1 += points
	else:
		score2 += points
	update_score()
	show_message("+%d!" % points)
	waiting = true

	if score1 >= WIN_SCORE or score2 >= WIN_SCORE:
		win_label.text = "PLAYER %d WINS!" % scorer.player_number
		win_panel.show()
	else:
		next_player = p2 if scorer == p1 else p1
		wait_time = 1.2


func update_score() -> void:
	score_label.text = "P1    %d  -  %d    P2" % [score1, score2]


func show_message(text: String) -> void:
	message_label.text = text
	message_time = 1.2


func _on_play_again_button_pressed() -> void:
	get_tree().reload_current_scene()


func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
