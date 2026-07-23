extends RigidBody3D

#------------------------------------------#
"""

This script controls: 
	
	- TBD
	
"""
#------------------------------------------#

#------------------------------------------#
# Variables:
#------------------------------------------#

# Projectile Stats

var assigned_owning_client : String

var assigned_spawn_position : Vector3
var assigned_target_position : Vector3
var assigned_target_rotation : Vector3

var assigned_projectile_speed : float
const MAX_PROJECTILE_SPEED : float = 1_000.0
const MIN_PROJECTILE_SPEED : float = 1.0

var assigned_projectile_damage : float = 10.0

var current_projectile_lifetime : float = 0.0
const MAX_PROJECTILE_LIFETIME : float = 45.0

# Projectile State

var ready_for_deletion : bool = false
var spawned_too_close : bool = false
var can_act_by_itself : bool = false

# Projectile Nodes



# Projectile Notifiers

signal notify_collision_for_server

#------------------------------------------#
# Projectile Functions:
#------------------------------------------#

func _physics_process(delta: float) -> void:
	
	if spawned_too_close == true:
		
		ready_for_deletion = true
	
	# Allow the client predicted projectile to move
	if can_act_by_itself == true:
		
		move_projectile()
	
	# Allow the client predicted projectile to tick it's lifetime
	if can_act_by_itself == true:
		
		current_projectile_lifetime = \
		current_projectile_lifetime + delta
		
		if current_projectile_lifetime >= MAX_PROJECTILE_LIFETIME:
			
			ready_for_deletion = true
	
	# Allow the client predicted projectile to delete itself
	if can_act_by_itself == true \
	and ready_for_deletion == true:
		
		delete_projectile()

func initialize_projectile() -> void:
	
	# Set the projectile's position to the muzzle of the player's weapon
	global_position = assigned_spawn_position
	
	# Rotate the projectile toward the camera raycast's target position
	look_at(assigned_target_position)

func initialize_projectile_when_too_close() -> void:
	
	# Spawn the projectile from the player's muzzle when-
	# -the player model is too close to an object
	
	global_position = assigned_spawn_position
	
	global_rotation = assigned_target_rotation

func move_projectile() -> void:
	
	linear_velocity = -global_transform.basis.z * assigned_projectile_speed

func _on_body_entered(body:Node) -> void:
	
	if multiplayer.is_server(): 
		
		process_true_server_collision(body)
	
	if not multiplayer.is_server():
		
		process_client_predicted_collision(body)

@warning_ignore("unused_parameter")
func process_client_predicted_collision(body:Node) -> void:
	
	ready_for_deletion = true

func process_true_server_collision(body:Node) -> void:
	
	notify_collision_for_server.emit(body, \
	assigned_projectile_damage, \
	assigned_owning_client,
	get_path())

func delete_projectile() -> void:
	
	queue_free()
