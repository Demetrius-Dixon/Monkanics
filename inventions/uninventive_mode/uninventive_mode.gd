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

var Can_Operate : bool = true
@onready var Player_Ref : Node

# Uninventive Melee

@onready var Uninventive_Melee_Hitbox : Node
const UNINVENTIVE_MELEE_DAMAGE : int = 30

# Uninventive Projectile

@onready var Universal_Projectile := preload("uid://bn1b4438pxw3l")
@onready var Universal_Projectile_Origin : Node
const UNINVENTIVE_PROJECTILE_FIRE_RATE : float = 0.10
const MIN_PROJECTILE_SHOOT_DISTANCE : float = 7.5

#------------------------------------------#
# Uninventive Attacks:
#------------------------------------------#

func setup_node_references(Player_Ref_Node:Node,
Universal_Projectile_Origin_Node:Node) -> void:
	
	Player_Ref = Player_Ref_Node
	
	Universal_Projectile_Origin = Universal_Projectile_Origin_Node

func uninventive_projectile_attack() -> void:
	
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
	var Projectile_Instance : Node = Universal_Projectile.instantiate()
	
	# Spawn projectile in scene
	add_sibling(Projectile_Instance)
	
	# Check if the player is too close to a wall via the muzzle raycast
	if Muzzle_Raycast_Hit_Distance <= MIN_PROJECTILE_SHOOT_DISTANCE:
		
		# Shoot projectiles to camera direction
		Projectile_Instance.initialize_projectile_when_too_close(Universal_Projectile_Origin.global_position, \
		Player_Ref.Camera.global_rotation.x, \
		Player_Ref.Camera.global_rotation.y, \
		Player_Ref.Camera.global_rotation.z)
		
	else:
		
		# Shoot projectiles to crosshair
		Projectile_Instance.initialize_projectile(Universal_Projectile_Origin.global_position, \
		Camera_Raycast_Collision_Point, UNINVENTIVE_PROJECTILE_FIRE_RATE)
	
	#--------------------------------------------------------------------------#
	
	# Add fire rate delay
	Can_Operate = false
	
	# Fire rate timer and action re-enabling
	await get_tree().create_timer(UNINVENTIVE_PROJECTILE_FIRE_RATE).timeout
	Can_Operate = true
	
	# Check if the operate input is held for auto fire
	#if Player_Ref.Is_Operating == true: 
		#uninventive_projectile_attack()

#func uninventive_melee_attack() -> void:
	#
	## Get all Area3Ds upon performing a wrench attack
	#var Hitboxes:Variant = Uninventive_Melee_Hitbox.get_overlapping_areas()
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
		#and Hitbox_Name != Player_Ref.Client_ID:
			#
			## Get the enemy's LOS reference node and local hitbox position
			#var Hit_Player_LOS_Position : Vector3 = Hitbox.get_node("GlobalLineOfSightReference").global_position
			#var Raycast_Target_Location : Vector3 = Player_Ref.Global_LOS_Checker.to_local(Hit_Player_LOS_Position)
			#
			## Send the LOS raycast to the enemy's location and force and update
			#Player_Ref.Global_LOS_Checker.target_position = Raycast_Target_Location
			#Player_Ref.Global_LOS_Checker.force_raycast_update()
			#
			## Checks if the LOS raycast hits a surface (body)
			#if Player_Ref.Global_LOS_Checker.is_colliding() == false:
				#
				## Damages the enemy hit
				#Hitbox.get_node("PlayerDamageCollision").take_damage(UNINVENTIVE_MELEE_DAMAGE)
			#
			## Continue if the LOS raycast fails
			#else: continue
		#
		## Ignore everything that isn't an enemy player hitbox
		#else: pass
