extends CharacterBody3D
#------------------------------------------#
"""

This script controls the player's mechanics.

A player is given to a client upon loading the game.

The server is in charge of this script + every other script.

Functions are triggered via client-server communication.
Variables are changed via client-server communication.

"""
#------------------------------------------#

#------------------------------------------#
# Variables/Constants:
#------------------------------------------#

# Mouse

var Mouse_Sensitivity : float = 0.003
var Player_Mouse_Visible : bool = true

# Current Player Status

var Is_Airborne : bool = false
var Is_Moving : bool = false

# Model Rotation

enum PLAYER_BODY_ROTATION_DIRECTION{FOLLOW_MOVEMENT, FOLLOW_CAMERA}
var Current_Player_Body_Rotation_Direction : PLAYER_BODY_ROTATION_DIRECTION = PLAYER_BODY_ROTATION_DIRECTION.FOLLOW_MOVEMENT
var Is_Body_Rotation_Overwritten : bool = false

enum CURRENT_PLAYER_HEAD_Y_ROTATION_DIRECTION{FOLLOW_MOVEMENT, FOLLOW_CAMERA}
var Current_Player_Head_Y_Rotation_Direction : CURRENT_PLAYER_HEAD_Y_ROTATION_DIRECTION = CURRENT_PLAYER_HEAD_Y_ROTATION_DIRECTION.FOLLOW_MOVEMENT
var Is_Head_Y_Rotation_Overwritten : bool = false

var Global_Body_And_Head_Movement_Rotation : float
const BODY_AND_HEAD_ROTATION_INTERPOLATION_WEIGHT : float = 0.95
const CAMERA_ALIGNMENT_ROTATION_INTERPOLATION_WEIGHT : float = 0.6

# Movement

var Is_Movement_Input_Held : bool = false

var Current_Movement_Speed : float = 0.0
var Current_Velocity_X : float = 0.0
var Current_Velocity_Y : float = 0.0
var Current_Velocity_Z : float = 0.0

const MAX_MOVEMENT_SPEED : float = 50.0
const MIN_MOVEMENT_SPEED : float = 0.0

var Current_Movement_Speed_Multiplier : float = 1.0
const MAX_MOVEMENT_SPEED_MULTIPLIER : float = 2.0 # (+200% Movement Speed)
const MIN_MOVEMENT_SPEED_MULTIPLIER : float = 0.6 # (-40% Movement Speed)
const DEFAULT_MOVEMENT_SPEED_MULTIPLIER : float = 1.0
var Active_Speed_Multipliers : Array[String]

const MOVEMENT_ACCELERATION_RATE : float = 15_000.0

const MOVEMENT_DECELERATION_RATE_GROUNDED : float = 5_250.0
const MOVEMENT_DECELERATION_RATE_AIRBORNE : float = 0.0

var Global_Movement_Direction : Vector3 
var Movement_Direction_X : float
var Movement_Direction_Z : float

# Jumping

var Can_Jump : bool = true 
var Is_Jumping : bool = false 

const INITIAL_JUMP_FORCE : float = 20.0
const GRADUAL_JUMP_FORCE : float = 1.0

var Current_Jump_Time : float = 0.0 
const JUMP_TIME_PROGRESSION : float = 0.045 
const JUMP_TIME_AWAIT_DURATION : float = 0.001 
const MIN_JUMP_TIME : float = 0.0
const MAX_JUMP_TIME : float = 0.35

var Is_Jump_Input_Buffered : bool = false
var Current_Jump_Buffer_Duration : float = 0.0
const MAX_JUMP_BUFFER_DURATION : float = 0.10
const MIN_JUMP_BUFFER_DURATION : float = 0.0
const JUMP_BUFFER_PROGRESSION : float = 0.045 
const JUMP_BUFFER_AWAIT_DURATION : float = 0.001 

var Can_Coyote_Jump : bool = false
var Current_Coyote_Time : float = 0.0
const MAX_COYOTE_TIME : float = 0.2
const MIN_COYOTE_TIME : float = 0.0
const COYOTE_TIMER_PROGRESSION : float = 0.045 
const COYOTE_TIMER_AWAIT_DURATION : float = 0.001 

var Is_Newly_Grounded : bool = false

var Can_Apply_Gravity : bool = true
var Current_Gravity_Force : float = 115.0
const DEFUALT_GRAVITY_FORCE : float = 115.0
const MIN_GRAVITY_FORCE : float = 0.0

# Health

var Current_Health : int = 100
var Current_Max_Health : int = 100
const DEFAULT_MAX_HEALTH : int = 100
const MIN_HEALTH : int = 0

# Gunplay

var Can_Operate : bool = true
var Is_Operating : bool = false
var Is_Operate_Input_Held : bool = false

# Multiplayer

var Client_ID : String
var Client_Ping : float = -1.0
var Client_Packet_Loss_Percentage : float = -1.0

# Camera

@onready var Camera : Node = $CameraHorizonalRotation/CameraVerticalRotation/CameraSpringArm/Camera
@onready var Camera_Horizonal_Rotation : Node = $CameraHorizonalRotation
@onready var Camera_Vertical_Rotation : Node = $CameraHorizonalRotation/CameraVerticalRotation
const MAX_LOOK_DEGREES : int = 75
const MIN_LOOK_DEGREES : int = -75

# Player Model

@onready var Body_Parts : Node = $BodyParts
@onready var Head_Parts : Node = $HeadParts

# Univeral Gunplay Nodes

@onready var Player_Hitbox : Node = $PlayerDamageTaker
@onready var Global_LOS_Checker : Node = $CameraHorizonalRotation/CameraVerticalRotation/GlobalLOSChecker
@onready var LOS_Reference : Node = $LOSReference

@onready var Camera_Raycast : Node = $CameraHorizonalRotation/CameraVerticalRotation/CameraSpringArm/Camera/CameraRaycast
@onready var Global_Muzzle_Raycast : Node = $GlobalMuzzleRaycast

const MIN_PROJECTILE_SHOOT_DISTANCE : float = 9.5
const END_PROJECTILE_SHOOT_DISTANCE : float = 3.0

@onready var Global_Projectile_Origin : Node = $CameraHorizonalRotation/CameraVerticalRotation/GlobalProjectileOrigin

# HUD

@onready var Health_Bar : Node = $PlayerHUD/PlayerHealthBar

#------------------------------------------#
# Virtual Functions:
#------------------------------------------#

func _physics_process(delta: float) -> void:
	
	# Apply gravity
	apply_gravity(delta)
	
	# Checks if the player is airboune
	check_if_player_is_airborne()
	
	# Tracks current velocity to trigger events when the player stops moving
	check_velocity() #INFO Add an "upon_stoping" function later
	
	# Update alt crosshair status every tick
	#check_raycast_alignment_for_alt_crosshair()
	
	# Check if the player is operating or not every frame
	check_and_change_player_model_rotation_direction()

#------------------------------------------#
# Network Sync and General Setup Functions:
#------------------------------------------#

func update_player_id(id:String) -> void:
	
	# Sets the player's id variable to the sent client id
	Client_ID = id

func update_current_cam(id:String) -> void:
	
	# Checks if the client's id is the same as the player's id
	if id == Client_ID:
		
		# Makes the client's camera current
		Camera.current = true
		
	else: return

func delete_unnecessary_player_nodes_for_self() -> void:
	
	# Delete all unnecessary self player nodes to predict collision
	$PlayerDamageTaker.queue_free()

func delete_unnecessary_player_nodes_for_others() -> void:
	
	# Delete all unnecessary player nodes to save memory
	$PlayerWorldCollision.queue_free()
	$LOSReference.queue_free()
	$GlobalMuzzleRaycast.queue_free()
	$CameraHorizonalRotation.queue_free()
	$PlayerHUD.queue_free()

#------------------------------------------#
# Movement Controls:
#------------------------------------------#

func start_moving(input:Vector2, delta:float) -> void:
	
	# Set moving to true
	Is_Moving = true
	
	# Set the current movement direction
	Global_Movement_Direction = Camera_Horizonal_Rotation.basis \
	* Vector3(input.x, 0, input.y)
	
	# Set the player model's rotation direction to movement direction
	if Global_Movement_Direction != Vector3(0.0, 0.0, 0.0):
		
		Global_Body_And_Head_Movement_Rotation = \
		atan2(Global_Movement_Direction.x, Global_Movement_Direction.z)
	
	# ---------------------------
	
	# Walking movement acceleration (Advances every physics tick in the client script)
	if Current_Movement_Speed < MAX_MOVEMENT_SPEED * Current_Movement_Speed_Multiplier:
		
		Current_Movement_Speed = \
		clampf(Current_Movement_Speed + \
		(delta * MOVEMENT_ACCELERATION_RATE), \
		MIN_MOVEMENT_SPEED, MAX_MOVEMENT_SPEED * Current_Movement_Speed_Multiplier)
	
	# Movement force
	velocity.x = Global_Movement_Direction.x * Current_Movement_Speed
	velocity.z = Global_Movement_Direction.z * Current_Movement_Speed
	
	# ---------------------------
	
	# Rotate the model with player movement if not operating
	if Current_Player_Body_Rotation_Direction == PLAYER_BODY_ROTATION_DIRECTION.FOLLOW_MOVEMENT:
		
		# Rotate the body
		Body_Parts.rotation.y = lerp(Body_Parts.rotation.y, Global_Body_And_Head_Movement_Rotation, \
		BODY_AND_HEAD_ROTATION_INTERPOLATION_WEIGHT)
		
		# Rotate the head
		Head_Parts.rotation.y = lerp(Head_Parts.rotation.y, Global_Body_And_Head_Movement_Rotation, \
		BODY_AND_HEAD_ROTATION_INTERPOLATION_WEIGHT)
	
	# ---------------------------
	
	# Prevents saving a 0.0 input and killing the player's momentum
	if input != Vector2(0,0):
		Movement_Direction_X = Global_Movement_Direction.x
		Movement_Direction_Z = Global_Movement_Direction.z

func stop_moving(delta:float) -> void:
	
	# This triggers when the player stops moving.
	
	# Set Is_Moving to false
	Is_Moving = false
	
	# Add remaining velocity to movement
	velocity.x = Movement_Direction_X * Current_Movement_Speed
	velocity.z = Movement_Direction_Z * Current_Movement_Speed
	
	# Movement Deceleration
	if Current_Movement_Speed > MIN_MOVEMENT_SPEED:
		
		# If grounded
		if Is_Airborne == false:
			
			Current_Movement_Speed = \
			clampf(Current_Movement_Speed - \
			(delta * MOVEMENT_DECELERATION_RATE_GROUNDED), \
			MIN_MOVEMENT_SPEED, MAX_MOVEMENT_SPEED * Current_Movement_Speed_Multiplier)
			
		# If airborne
		elif Is_Airborne == true:
			
			Current_Movement_Speed = \
			clampf(Current_Movement_Speed - \
			(delta * MOVEMENT_DECELERATION_RATE_AIRBORNE), \
			MIN_MOVEMENT_SPEED, MAX_MOVEMENT_SPEED * Current_Movement_Speed_Multiplier)

func start_jumping() -> void:
	
	# Checks if the player can jump
	if Can_Jump == false: return
	
	# Checks if the player is already jumping
	if Is_Jumping == true: return
	
	# Checks if the player is in the air
	if Is_Airborne == true \
	and Can_Coyote_Jump == false: return
	
	# Sets Is_Jumping to true
	Is_Jumping = true
	
	# Ininitial jump velocity
	velocity.y = velocity.y + INITIAL_JUMP_FORCE
	
	# Jump function via a while loop
	while Current_Jump_Time < MAX_JUMP_TIME \
	and Is_Jumping == true:
		
		# Sets the current jump time
		Current_Jump_Time = clampf(Current_Jump_Time + JUMP_TIME_PROGRESSION, \
		MIN_JUMP_TIME, MAX_JUMP_TIME)
		
		# Adds upward velocity
		velocity.y = velocity.y + GRADUAL_JUMP_FORCE
		
		# Small deley before next loop
		await get_tree().create_timer(JUMP_TIME_AWAIT_DURATION).timeout
		
		# Automatically stop jumping when max jump time is reached
		if Current_Jump_Time == MAX_JUMP_TIME:
			stop_jumping()
	
	# End the jump buffer after the jump
	Is_Jump_Input_Buffered = false
	
	# Reset the current buffer timer after the jump
	Current_Jump_Buffer_Duration = MIN_JUMP_BUFFER_DURATION

func stop_jumping() -> void:
	
	# Checks if the player is actually jumping
	if Is_Jumping == false: 
		
		# End coyote time even if `stop_jumping` doesn't go through
		stop_coyote_timer()
		
		return
	
	# Sets Is_jumping to false
	Is_Jumping = false
	
	# Sets the current jump time to 0
	if Current_Jump_Time != MIN_JUMP_TIME:
		Current_Jump_Time = MIN_JUMP_TIME
	
	# End coyote time upon the jump ending regardless
	stop_coyote_timer()

func trigger_move_and_slide() -> void:
	
	# Used to trigger move_and_slide on-
	# -the client and server independently (This is required)
	move_and_slide()

func apply_gravity(delta: float) -> void:
	
	# Applies gravity when all conditions are met.
	if Can_Apply_Gravity == true \
	and Is_Airborne == true \
	and Is_Jumping == false:
		
		# Apply current gravity force every frame
		velocity.y -= Current_Gravity_Force * delta

func check_if_player_is_airborne() -> void:
	
	# Checks if the player is NOT on the floor
	if not is_on_floor():
		
		# Update airborne status to true
		Is_Airborne = true
		
		if Is_Jumping == false \
		and Is_Newly_Grounded == false:
			start_coyote_timer()
		
		# Reset grounded status
		Is_Newly_Grounded = true
	
	# Checks if the player IS on the floor
	if is_on_floor():
		
		# Update airborne status to false
		Is_Airborne = false
		
		# Trigger ground touching functions
		upon_touching_ground()

func upon_touching_ground() -> void:
	
	# Trigger buffered jump
	if Is_Jump_Input_Buffered == true:
		start_jumping()
	
	# End coyote time after touching the ground
	stop_coyote_timer()
	
	# Set grounded status
	Is_Newly_Grounded = false

func start_jump_buffer_timer() -> void:
	
	# Reset the current jump buffer duration to 0.0
	Current_Jump_Buffer_Duration = MIN_JUMP_BUFFER_DURATION
	
	# Jump buffer time via `while` loop
	while Current_Jump_Buffer_Duration < MAX_JUMP_BUFFER_DURATION \
	and Is_Jump_Input_Buffered == true:
		
		# Sets the current jump time
		Current_Jump_Buffer_Duration = clampf(Current_Jump_Buffer_Duration + JUMP_BUFFER_PROGRESSION, \
		MIN_JUMP_BUFFER_DURATION, MAX_JUMP_BUFFER_DURATION)
		
		# Small deley before next loop
		await get_tree().create_timer(JUMP_BUFFER_AWAIT_DURATION).timeout
		
		# Automatically stop jumping when max jump time is reached
		if Current_Jump_Buffer_Duration == MAX_JUMP_BUFFER_DURATION:
			
			# Set the buffer to false after timer elapesed
			Is_Jump_Input_Buffered = false
			
			# Reset the current buffer timer once fully elapesed
			Current_Jump_Buffer_Duration = MIN_JUMP_BUFFER_DURATION

func start_coyote_timer() -> void:
	
	# Prevents repeat start triggers
	if Can_Coyote_Jump == true: return
	
	# Prevents coyote time from triggering while jumping
	if Is_Jumping == true: 
		stop_coyote_timer()
		return
	
	# Allow the player to coyote jump
	Can_Coyote_Jump = true
	
	# Set gravity force to 0.0
	if Current_Gravity_Force != MIN_GRAVITY_FORCE:
		Current_Gravity_Force = MIN_GRAVITY_FORCE
	
	# Reset the current coyote timer duration to 0.0
	Current_Coyote_Time = MIN_COYOTE_TIME
	
	# Coyote timer via `while` loop
	while Current_Coyote_Time < MAX_COYOTE_TIME \
	and Can_Coyote_Jump == true:
		
		# Sets the current coyote time
		Current_Coyote_Time = clampf(Current_Coyote_Time + COYOTE_TIMER_PROGRESSION, \
		MIN_COYOTE_TIME, MAX_COYOTE_TIME)
		
		# Small deley before next loop
		await get_tree().create_timer(COYOTE_TIMER_AWAIT_DURATION).timeout
		
		# Automatically stop coyote time when max jump time is reached
		if Current_Coyote_Time == MAX_COYOTE_TIME:
			
			# Set the coyote jump to false after timer elapesed
			Can_Coyote_Jump = false
			
			# End coyote time
			stop_coyote_timer()
			
			# Reset the current coyote timer once fully elapesed
			Current_Coyote_Time = MIN_COYOTE_TIME

func stop_coyote_timer() -> void:
	
	# End coyote time
	Can_Coyote_Jump = false
	
	# Set gravity force back to normal
	Current_Gravity_Force = DEFUALT_GRAVITY_FORCE

func check_velocity() -> void:
	
	# Track velocity X
	Current_Velocity_X = velocity.x
	
	# Track velocity Y
	Current_Velocity_Y = velocity.y
	
	# Track velocity Z
	Current_Velocity_Z = velocity.z
	
	# Print velocity X,Y,Z (Testing only)
	#print("X: ", Current_Velocity_X, " Y: ", Current_Velocity_Y, " Z: ", Current_Velocity_Z)

#------------------------------------------#
# Camera Controls:
#------------------------------------------#

func _unhandled_input(event:InputEvent) -> void: # Camera Controls
	
	# Checks if the client is correct
	if Client_ID != name: return
	
	# Checks if the mouse is invisible/captured
	if Player_Mouse_Visible == true: return
	
	# ---------------------------
	
	# Mouse movement variables
	var Camera_Horizontal_Input : float = 0.0
	var Camera_Vertical_Input : float = -0.0
	const End_Camera_Input : float = 0.0
	
	# ---------------------------
	
	# Tracks mouse movement and calculates sensitivity
	if event is InputEventMouseMotion and Input.MOUSE_MODE_CAPTURED:
		Camera_Horizontal_Input = - event.relative.x * Mouse_Sensitivity
		Camera_Vertical_Input = event.relative.y * Mouse_Sensitivity
	
	# ---------------------------
	
	# Rotates the camera on the Y axis based on tracked mouse movement
	Camera_Horizonal_Rotation.rotate_y(Camera_Horizontal_Input)
	
	# ---------------------------
	
	# Make the player's body rotate with side-to-side movement if the player is operating
	if Current_Player_Body_Rotation_Direction == PLAYER_BODY_ROTATION_DIRECTION.FOLLOW_CAMERA:
		
		# Reset the body side-to-side rotation
		Body_Parts.rotation.y = lerp(Body_Parts.rotation.y, Camera_Horizonal_Rotation.rotation.y, \
		CAMERA_ALIGNMENT_ROTATION_INTERPOLATION_WEIGHT)
		
		# Move the body with the camera
		Body_Parts.rotate_y(Camera_Horizontal_Input)
	
	# ---------------------------
	
	# Rotates the camera on the X axis based on tracked mouse movement
	Camera_Vertical_Rotation.rotate_x(Camera_Vertical_Input)
	
	# Clamps upward/downward (X axis) mouse movement
	Camera_Vertical_Rotation.rotation.x = clamp \
	(
		Camera_Vertical_Rotation.rotation.x, 
		deg_to_rad(MIN_LOOK_DEGREES), 
		deg_to_rad(MAX_LOOK_DEGREES)
	)
	
	# ---------------------------
	
	# Make the player's head rotate with pitch movement
	#Head_Parts.rotation.x = Camera_Vertical_Rotation.rotation.x
	#TODO Rework head movement to have a clamp for side-to-side movement-
	# -and only have the head tilt up/down when at the right angle
	
	# Rotate head parts with the body when operating
	if Current_Player_Head_Y_Rotation_Direction == CURRENT_PLAYER_HEAD_Y_ROTATION_DIRECTION.FOLLOW_CAMERA:
		
		# Reset the head side-to-side rotation
		Head_Parts.rotation.y = lerp(Head_Parts.rotation.y, Camera_Horizonal_Rotation.rotation.y, \
		CAMERA_ALIGNMENT_ROTATION_INTERPOLATION_WEIGHT)
		
		# Move the head with the camera
		Head_Parts.rotate_y(Camera_Horizontal_Input)
	
	# ---------------------------
	
	# Prevents the mouse from moving when the mouse stops moving
	Camera_Horizontal_Input = End_Camera_Input
	Camera_Vertical_Input = End_Camera_Input

func change_player_rotation_for_server(New_Player_Body_Rotation:Vector3, New_Player_Head_Rotation:Vector3,
New_Camera_Horizontal_Rotation:float, New_Camera_Vertical_Rotation:float) -> void:
	
	# Update server's player body rotation
	Body_Parts.rotation = New_Player_Body_Rotation
	
	# Update server's head up/down rotation
	Head_Parts.rotation.x = New_Player_Head_Rotation.x
	
	# Update server's head side-to-side rotation with the body
	Head_Parts.rotation.y = New_Player_Body_Rotation.y
	
	# Update the server's camera horizontal rotation
	Camera_Horizonal_Rotation.rotation.y = New_Camera_Horizontal_Rotation
	
	# Update the server's camera horizontal rotation
	Camera_Vertical_Rotation.rotation.x = New_Camera_Vertical_Rotation

#------------------------------------------#
# Gunplay Controls:
#------------------------------------------#

func player_take_damage(Damage:int) -> void:
	
	# Checks if health is greater than 0
	if Current_Health >= MIN_HEALTH:
		
		# Deals damage to the player
		Current_Health = clampi(Current_Health - Damage, \
		MIN_HEALTH, DEFAULT_MAX_HEALTH)
	
	else: return

func kill_player() -> void:
	
	print("Player Died")
	
	visible = false

func respawn_player(New_Spawn_Point:Vector3) -> void:
	
	global_position = New_Spawn_Point
	
	Current_Health = Current_Max_Health
	
	visible = true

func check_and_change_player_model_rotation_direction() -> void:
	
	# Checks if the player rotates with player movement or camera movement
	if Is_Operating == true \
	and Is_Body_Rotation_Overwritten == false:
		
		Current_Player_Body_Rotation_Direction = PLAYER_BODY_ROTATION_DIRECTION.FOLLOW_CAMERA
		Current_Player_Head_Y_Rotation_Direction = CURRENT_PLAYER_HEAD_Y_ROTATION_DIRECTION.FOLLOW_CAMERA
		
		# Reset the body side-to-side rotation
		Body_Parts.rotation.y = lerp(Body_Parts.rotation.y, Camera_Horizonal_Rotation.rotation.y, \
		CAMERA_ALIGNMENT_ROTATION_INTERPOLATION_WEIGHT)
		
		# Reset the head side-to-side rotation
		Head_Parts.rotation.y = lerp(Head_Parts.rotation.y, Camera_Horizonal_Rotation.rotation.y, \
		CAMERA_ALIGNMENT_ROTATION_INTERPOLATION_WEIGHT)
		
	else:
		
		Current_Player_Body_Rotation_Direction = PLAYER_BODY_ROTATION_DIRECTION.FOLLOW_MOVEMENT
		Current_Player_Head_Y_Rotation_Direction = CURRENT_PLAYER_HEAD_Y_ROTATION_DIRECTION.FOLLOW_MOVEMENT

#func check_raycast_alignment_for_alt_crosshair() -> void:
	#
	## Update the camera raycast
	#Camera_Raycast.force_raycast_update()
	#
	## Create collision variables
	#var Camera_Raycast_Collision_Point : Vector3 = Camera_Raycast.get_collision_point()
	#var New_Muzzle_Raycast_Target_Location : Vector3 = Global_Muzzle_Raycast.to_local(Camera_Raycast_Collision_Point)
	#
	## Update muzzle raycast to go toward camera raycast hit location
	#Global_Muzzle_Raycast.target_position = New_Muzzle_Raycast_Target_Location
	#Global_Muzzle_Raycast.force_raycast_update()
	#
	## Create hit distance variable
	#var Muzzle_Raycast_Hit_Distance : Variant
	#
	## Get the distance between the start/end of the muzzle raycast
	#Muzzle_Raycast_Hit_Distance = Global_Muzzle_Raycast.global_position.distance_to(Camera_Raycast.get_collision_point())
	#
	## Check if the player is too close to a wall via the muzzle raycast
	#if Muzzle_Raycast_Hit_Distance <= MIN_PROJECTILE_SHOOT_DISTANCE:
		#
		#Alt_Crosshair.show()
		#
		##TODO Doesn't project to the correct position
		#Alt_Crosshair.position = get_viewport().get_camera_3d().\
		#unproject_position(Global_Muzzle_Raycast.get_collision_point())
		#
	#else:
		#
		#Alt_Crosshair.hide()

#------------------------------------------#
#------------------------------------------#
