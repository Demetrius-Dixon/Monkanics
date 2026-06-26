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

var Can_Operate : bool = true
var Player_Ref : Node

# Projectile

@onready var Uninversal_Projectile : PackedScene = preload("uid://bn1b4438pxw3l")
@onready var Projectile_Origin : Node3D
const PROJECTILE_FIRE_RATE : float = 0.10
const MIN_PROJECTILE_SHOOT_DISTANCE : float = 7.5

#------------------------------------------#
# Universal Actions:
#------------------------------------------#

func operate() -> void:
	
	# Update the camera raycast
	Player_Ref.Camera_Raycast.force_raycast_update()
	
	# Create collision variables
	var Camera_Raycast_Collision_Point : Vector3 = Player_Ref.Camera_Raycast.get_collision_point()
	var New_Muzzle_Raycast_Collision_Point : Vector3 = Player_Ref.Global_Muzzle_Raycast.to_local(Camera_Raycast_Collision_Point)
	
	# Update muzzle raycast to go toward camera raycast hit location
	Player_Ref.Global_Muzzle_Raycast.target_position = New_Muzzle_Raycast_Collision_Point
	Player_Ref.Global_Muzzle_Raycast.force_raycast_update()
	
	# Create hit distance variable
	var Muzzle_Raycast_Hit_Distance : Variant
	
	# Get the distance between the start/end of the muzzle raycast
	Muzzle_Raycast_Hit_Distance = Player_Ref.Global_Muzzle_Raycast.global_position.distance_to(Player_Ref.Camera_Raycast.get_collision_point())
	
	# Instantiate projectile
	var Projectile_Instance : Node = Uninversal_Projectile.instantiate()
	
	# Spawn projectile in scene
	add_sibling(Projectile_Instance)
	
	# Check if the player is too close to a wall via the muzzle raycast
	if Muzzle_Raycast_Hit_Distance <= MIN_PROJECTILE_SHOOT_DISTANCE:
		
		# Shoot projectiles to camera direction
		Projectile_Instance.initialize_projectile_when_too_close(Projectile_Origin.global_position, \
		Player_Ref.Camera.global_rotation.x, \
		Player_Ref.Camera.global_rotation.y, \
		Player_Ref.Camera.global_rotation.z)
		
	else:
		
		# Shoot projectiles to crosshair
		Projectile_Instance.initialize_projectile(Projectile_Origin.global_position, \
		Camera_Raycast_Collision_Point)
	
	#--------------------------------------------------------------------------#
	
	# Add fire rate delay
	Can_Operate = false
	
	# Fire rate timer and action re-enabling
	await get_tree().create_timer(PROJECTILE_FIRE_RATE).timeout
	Can_Operate = true
	
	# Check if the operate input is held for auto fire
	if Player_Ref.Is_Operating == true: 
		operate()
