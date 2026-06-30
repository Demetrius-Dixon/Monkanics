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

var Assigned_Owning_Client : String

var Assigned_Spawn_Position : Vector3
var Assigned_Target_Position : Vector3
var Assigned_Target_Rotation : Vector3

var Assigned_Projectile_Speed : float
const MAX_PROJECTILE_SPEED : float = 1_000.0
const MIN_PROJECTILE_SPEED : float = 1.0

var Assigned_Projectile_Damage : float = 10.0

var Current_Projectile_Lifetime : float = 0.0
const MAX_PROJECTILE_LIFETIME : float = 45.0

# Projectile State

var Ready_For_Deletion : bool = false
var Spawned_Too_Close : bool = false
var Can_Act_By_Itself : bool = false

# Projectile Nodes



# Projectile Notifiers

signal notify_Collision_For_Server

#------------------------------------------#
# Projectile Functions:
#------------------------------------------#

func _physics_process(delta: float) -> void:
	
	if Spawned_Too_Close == true:
		
		Ready_For_Deletion = true
	
	# Allow the client predicted projectile to move
	if Can_Act_By_Itself == true:
		
		move_projectile()
	
	# Allow the client predicted projectile to tick it's lifetime
	if Can_Act_By_Itself == true:
		
		Current_Projectile_Lifetime = \
		Current_Projectile_Lifetime + delta
		
		if Current_Projectile_Lifetime >= MAX_PROJECTILE_LIFETIME:
			
			Ready_For_Deletion = true
	
	# Allow the client predicted projectile to delete itself
	if Can_Act_By_Itself == true \
	and Ready_For_Deletion == true:
		
		delete_projectile()

func initialize_projectile() -> void:
	
	# Set the projectile's position to the muzzle of the player's weapon
	global_position = Assigned_Spawn_Position
	
	# Rotate the projectile toward the camera raycast's target position
	look_at(Assigned_Target_Position)

func initialize_projectile_when_too_close() -> void:
	
	# Spawn the projectile from the player's muzzle when-
	# -the player model is too close to an object
	
	global_position = Assigned_Spawn_Position
	
	global_rotation = Assigned_Target_Rotation

func move_projectile() -> void:
	
	linear_velocity = -global_transform.basis.z * Assigned_Projectile_Speed

func _on_body_entered(body:Node) -> void:
	
	if multiplayer.is_server(): 
		
		process_true_server_collision(body)
	
	if not multiplayer.is_server():
		
		process_client_predicted_collision(body)

@warning_ignore("unused_parameter")
func process_client_predicted_collision(body:Node) -> void:
	
	Ready_For_Deletion = true

func process_true_server_collision(body:Node) -> void:
	
	notify_Collision_For_Server.emit(body, \
	Assigned_Projectile_Damage, \
	Assigned_Owning_Client,
	get_path())

func delete_projectile() -> void:
	
	queue_free()
