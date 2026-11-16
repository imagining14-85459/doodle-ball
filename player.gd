class_name Player
extends CharacterBody2D

signal shoot(player, charge)  
signal steal(player)        
signal power(player)   
@export var player_number := 1  
@export var attack_dir := 1   
@export var speed := 330.0
@export var jump_velocity := -800.0  
@export var gravity := 1900.0

const CHARGE_TIME := 0.6    
const SWEET_MIN := 0.72      
const SWEET_MAX := 0.90    
const SPIN_TIME := 0.45      
const SPIN_SPEED := 520.0
const SPIN_COOLDOWN := 2.0   
const STEAL_ANIM_TIME := 0.25  
const STEAL_LUNGE_SPEED := 420.0

var has_ball := false
var facing := 1             
var charging := false        
var charge := 0.0           
var charge_dir := 1.0       
var stun_time := 0.0        
var spin_time := 0.0        
var spin_cooldown := 0.0
var spin_dir := 1
var steal_cooldown := 0.0
var steal_anim := 0.0       
var anim_time := 0.0
var speed_boost := 1.0      
var bounce_active := false  

var idle_texture: Texture2D
var walk_texture: Texture2D
var reach_texture: Texture2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var meter: Node2D = $Meter
@onready var meter_fill: ColorRect = $Meter/Fill
@onready var name_label: Label = $NameLabel
@onready var dizzy_label: Label = $DizzyLabel


func _ready() -> void:
	name_label.text = "P%d" % player_number
	facing = attack_dir

func set_skin(skin: String) -> void:
	idle_texture = load(Global.skin_path(skin, "idle"))
	walk_texture = load(Global.skin_path(skin, "walk"))
	reach_texture = load(Global.skin_path(skin, "reach"))


func action(action_name: String) -> String:
	return "p%d_%s" % [player_number, action_name]


func _physics_process(delta: float) -> void:
	anim_time += delta
	spin_cooldown -= delta
	steal_cooldown -= delta
	steal_anim -= delta

	if stun_time > 0.0:
		stun_time -= delta
		velocity.x = 0.0
	elif spin_time > 0.0:
		spin_time -= delta
		velocity.x = spin_dir * SPIN_SPEED
		if spin_time <= 0.0:
			end_spin()
	else:
		read_controls(delta)

	if not is_on_floor():
		velocity.y += gravity * delta
	move_and_slide()
	update_look()


func read_controls(delta: float) -> void:
	var direction := Input.get_axis(action("left"), action("right"))
	var top_speed := speed * speed_boost
	if has_ball:
		top_speed *= 0.8
	velocity.x = direction * top_speed
	if direction != 0 and not charging:
		facing = 1 if direction > 0 else -1
	if steal_anim > 0.0:
		velocity.x = facing * STEAL_LUNGE_SPEED  

	if Input.is_action_just_pressed(action("jump")) and is_on_floor():
		velocity.y = jump_velocity

	if Input.is_action_just_pressed(action("spin")) and has_ball and is_on_floor() and not charging and spin_cooldown <= 0.0:
		start_spin(direction)
	if has_ball:
		if Input.is_action_pressed(action("shoot")) and not charging:
			charging = true
			charge = 0.0
			charge_dir = 1.0
			facing = attack_dir
		if charging:
			charge += charge_dir * delta / CHARGE_TIME
			if charge >= 1.0:
				charge = 1.0
				charge_dir = -1.0   
			elif charge <= 0.0:
				charge = 0.0
				charge_dir = 1.0
			if Input.is_action_just_released(action("shoot")):
				charging = false
				shoot.emit(self, charge)

	if Input.is_action_just_pressed(action("power")):
		power.emit(self)

	if Input.is_action_just_pressed(action("steal")) and not has_ball and steal_cooldown <= 0.0:
		steal_cooldown = 0.5
		steal_anim = STEAL_ANIM_TIME
		steal.emit(self)


func start_spin(direction: float) -> void:
	spin_time = SPIN_TIME
	spin_cooldown = SPIN_COOLDOWN
	spin_dir = facing if direction == 0 else int(signf(direction))
	set_collision_layer_value(2, false)
	set_collision_mask_value(2, false)


func end_spin() -> void:
	spin_time = 0.0
	set_collision_layer_value(2, true)
	set_collision_mask_value(2, true)



func punch_animation() -> void:
	steal_anim = STEAL_ANIM_TIME


func stun(seconds: float) -> void:
	stun_time = seconds
	charging = false
	steal_anim = 0.0
	if spin_time > 0.0:
		end_spin()

func hand_position() -> Vector2:
	if spin_time > 0.0:
		var angle := spin_time * 28.0
		return global_position + Vector2(cos(angle) * 45.0, 10.0)  
	if charging:
		return global_position + Vector2(0, -105)                   
	if not is_on_floor():
		return global_position + Vector2(facing * 45, 0)            
	var bounce := absf(sin(anim_time * 9.0))                        
	return global_position + Vector2(facing * 48, lerpf(68.0, 0.0, bounce))

func update_look() -> void:
	meter.visible = charging
	meter_fill.size.x = 64.0 * charge
	dizzy_label.visible = stun_time > 0.0
	sprite.rotation_degrees = 0.0
	sprite.position = Vector2.ZERO


	if bounce_active:
		sprite.scale = Vector2(0.31, 0.31)
		name_label.text = "P%d  BOUNCE!" % player_number
	else:
		sprite.scale = Vector2(0.28, 0.28)
		name_label.text = "P%d" % player_number

	if stun_time > 0.0:
		sprite.texture = idle_texture
		sprite.rotation_degrees = -90.0 * facing
		sprite.position.y = 37.0
		return
	if spin_time > 0.0:
		sprite.texture = reach_texture
		sprite.flip_h = int(spin_time * 28.0) % 2 == 0  
		return
	if steal_anim > 0.0:
		sprite.texture = reach_texture
		sprite.flip_h = facing < 0
		sprite.rotation_degrees = 15.0 * facing
		sprite.position.x = 10.0 * facing
		return

	sprite.flip_h = facing < 0
	if has_ball:
		sprite.texture = reach_texture
	elif not is_on_floor():
		sprite.texture = walk_texture
	elif absf(velocity.x) > 10.0:
		sprite.texture = walk_texture if int(anim_time * 7.0) % 2 == 0 else idle_texture
	else:
		sprite.texture = idle_texture
