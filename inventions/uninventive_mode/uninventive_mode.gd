extends Node3D

#------------------------------------------#
"""
This script controls: 
	
	- The uninventive mode melee and projectile attacks
	- This counts as it's own 'invention' slot
	- Unlike all other inventions, this one is always with the player
	
Remember to always:
	
	- CALL DOWN (To uninventive mode script) (You are here)
	- SIGNAL UP (To the player script)
	
"""
#------------------------------------------#

#------------------------------------------#
# Variables:
#------------------------------------------#

# Univeral

var can_operate : bool = true
@onready var player_ref : Node

# Uninventive Melee

@onready var uninventive_melee_hitbox : Node
const UNINVENTIVE_MELEE_DAMAGE : int = 30

# Uninventive Projectile

@onready var universal_projectile := preload("uid://bn1b4438pxw3l")
@onready var universal_projectile_origin : Node
const UNINVENTIVE_PROJECTILE_FIRE_RATE : float = 0.10
const MIN_PROJECTILE_SHOOT_DISTANCE : float = 7.5

#------------------------------------------#
# Uninventive Attacks:
#------------------------------------------#

func setup_node_references(player_ref_node:Node,
universal_projectile_origin_node:Node) -> void:
	
	player_ref = player_ref_node
	
	universal_projectile_origin = universal_projectile_origin_node

func uninventive_projectile_attack() -> void:
	
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
	var projectile_instance : Node = universal_projectile.instantiate()
	
	# Spawn projectile in scene
	add_sibling(projectile_instance)
	
	# Check if the player is too close to a wall via the muzzle raycast
	if muzzle_raycast_hit_distance <= MIN_PROJECTILE_SHOOT_DISTANCE:
		
		# Shoot projectiles to camera direction
		projectile_instance.initialize_projectile_when_too_close(universal_projectile_origin.global_position, \
		player_ref.camera.global_rotation.x, \
		player_ref.camera.global_rotation.y, \
		player_ref.camera.global_rotation.z)
		
	else:
		
		# Shoot projectiles to crosshair
		projectile_instance.initialize_projectile(universal_projectile_origin.global_position, \
		camera_raycast_collision_point, UNINVENTIVE_PROJECTILE_FIRE_RATE)
	
	#--------------------------------------------------------------------------#
	
	# Add fire rate delay
	can_operate = false
	
	# Fire rate timer and action re-enabling
	await get_tree().create_timer(UNINVENTIVE_PROJECTILE_FIRE_RATE).timeout
	can_operate = true
	
	# Check if the operate input is held for auto fire
	#if player_ref.is_operating == true: 
		#uninventive_projectile_attack()

#func uninventive_melee_attack() -> void:
	#
	## Get all Area3Ds upon performing a wrench attack
	#var Hitboxes:Variant = uninventive_melee_hitbox.get_overlapping_areas()
	#
	## Loop through all area3Ds
	#for Box:Area3D in Hitboxes:
		#
		## Get the Area3D's parent node and parent name (This works)
		#var Hitbox : Node = Box.get_parent()
		#var Hitbox_Name : String = Box.get_parent().name
		#
		## Loops through the collided hitboxes for-
		## - players to hit. (And ignore self)
		#if Hitbox.has_node("PlayerDamageCollision") \
		#and Hitbox_Name != player_ref.Client_ID:
			#
			## Get the enemy's LOS reference node and local hitbox position
			#var Hit_Player_LOS_Position : Vector3 = Hitbox.get_node("GlobalLineOfSightReference").global_position
			#var Raycast_Target_Location : Vector3 = player_ref.global_los_checker.to_local(Hit_Player_LOS_Position)
			#
			## Send the LOS raycast to the enemy's location and force and update
			#player_ref.global_los_checker.target_position = Raycast_Target_Location
			#player_ref.global_los_checker.force_raycast_update()
			#
			## Checks if the LOS raycast hits a surface (body)
			#if player_ref.global_los_checker.is_colliding() == false:
				#
				## Damages the enemy hit
				#Hitbox.get_node("PlayerDamageCollision").take_damage(UNINVENTIVE_MELEE_DAMAGE)
			#
			## Continue if the LOS raycast fails
			#else: continue
		#
		## Ignore everything that isn't an enemy player hitbox
		#else: pass
