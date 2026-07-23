extends Node3D

#------------------------------------------#
"""
This script controls: 
	
	- TBD
	
"""
#------------------------------------------#

#------------------------------------------#
# Variables:
#------------------------------------------#

# References

var can_operate : bool = true
var player_ref : Node

# Projectile

@onready var uninversal_projectile : PackedScene = preload("uid://bn1b4438pxw3l")
@onready var projectile_origin : Node3D
const PROJECTILE_FIRE_RATE : float = 0.10
const MIN_PROJECTILE_SHOOT_DISTANCE : float = 7.5

#------------------------------------------#
# Universal Actions:
#------------------------------------------#

func operate() -> void:
	
	# Update the camera raycast
	player_ref.camera_raycast.force_raycast_update()
	
	# Create collision variables
	var camera_raycast_collision_point : Vector3 = player_ref.camera_raycast.get_collision_point()
	var new_muzzle_raycast_collision_point : Vector3 = player_ref.global_muzzle_raycast.to_local(camera_raycast_collision_point)
	
	# Update muzzle raycast to go toward camera raycast hit location
	player_ref.global_muzzle_raycast.target_position = new_muzzle_raycast_collision_point
	player_ref.global_muzzle_raycast.force_raycast_update()
	
	# Create hit distance variable
	var muzzle_raycast_hit_distance : Variant
	
	# Get the distance between the start/end of the muzzle raycast
	muzzle_raycast_hit_distance = player_ref.global_muzzle_raycast.global_position.distance_to(player_ref.camera_raycast.get_collision_point())
	
	# Instantiate projectile
	var projectile_instance : Node = uninversal_projectile.instantiate()
	
	# Spawn projectile in scene
	add_sibling(projectile_instance)
	
	# Check if the player is too close to a wall via the muzzle raycast
	if muzzle_raycast_hit_distance <= MIN_PROJECTILE_SHOOT_DISTANCE:
		
		# Shoot projectiles to camera direction
		projectile_instance.initialize_projectile_when_too_close(projectile_origin.global_position, \
		player_ref.camera.global_rotation.x, \
		player_ref.camera.global_rotation.y, \
		player_ref.camera.global_rotation.z)
		
	else:
		
		# Shoot projectiles to crosshair
		projectile_instance.initialize_projectile(projectile_origin.global_position, \
		camera_raycast_collision_point)
	
	#--------------------------------------------------------------------------#
	
	# Add fire rate delay
	can_operate = false
	
	# Fire rate timer and action re-enabling
	await get_tree().create_timer(PROJECTILE_FIRE_RATE).timeout
	can_operate = true
	
	# Check if the operate input is held for auto fire
	if player_ref.is_operating == true: 
		operate()
