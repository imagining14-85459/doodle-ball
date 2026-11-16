extends RigidBody2D

var holder = null       
var in_flight := false
var shooter = null
var shot_distance := 0.0
var launch_velocity = null


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if holder != null:
		state.transform.origin = holder.hand_position()
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0.0
	elif launch_velocity != null:
		state.linear_velocity = launch_velocity
		launch_velocity = null


func hold(player) -> void:
	holder = player
	in_flight = false


func throw(shot_velocity: Vector2) -> void:
	holder = null
	launch_velocity = shot_velocity
	in_flight = true


func _on_body_entered(_body: Node) -> void:
	if holder == null and launch_velocity == null:
		in_flight = false
