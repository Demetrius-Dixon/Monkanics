extends CharacterBody3D

var mouse_sensitivity : float = 0.003

var is_airborne : bool = false
var is_moving : bool = false

enum PlayerBodyRotatonDirection{
	FOLLOW_MOVEMENT, 
	FOLLOW_CAMERA
}
var current_player_body_rotation_direction : \
PlayerBodyRotatonDirection = PlayerBodyRotatonDirection.FOLLOW_MOVEMENT
var is_body_rotation_overwritten : bool = false

enum CurrentPlayerHeadRotationDirectionY{
	FOLLOW_MOVEMENT, 
	FOLLOW_CAMERA
}
var current_player_head_y_rotation_direction : \
CurrentPlayerHeadRotationDirectionY = CurrentPlayerHeadRotationDirectionY.FOLLOW_MOVEMENT
var is_head_y_rotation_overwritten : bool = false

var global_body_and_head_movement_rotation : float
const BODY_AND_HEAD_ROTATION_INTERPOLATION_WEIGHT : float = 0.95
const CAMERA_ALIGNMENT_ROTATION_INTERPOLATION_WEIGHT : float = 0.6

var is_movement_input_held : bool = false

var current_movement_speed : float = 0.0
var current_velocity_x : float = 0.0
var current_velocity_y : float = 0.0
var current_velocity_z : float = 0.0

const MAX_MOVEMENT_SPEED : float = 50.0
const MIN_MOVEMENT_SPEED : float = 0.0

var current_movement_speed_multiplier : float = 1.0
var active_speed_multipliers : Array[String]
const MAX_MOVEMENT_SPEED_MULTIPLIER : float = 2.0 # (+200% Movement Speed)
const MIN_MOVEMENT_SPEED_MULTIPLIER : float = 0.6 # (-40% Movement Speed)
const DEFAULT_MOVEMENT_SPEED_MULTIPLIER : float = 1.0

const MOVEMENT_ACCELERATION_RATE : float = 15_000.0

const MOVEMENT_DECELERATION_RATE_GROUNDED : float = 5_250.0
const MOVEMENT_DECELERATION_RATE_AIRBORNE : float = 0.0

var global_movement_direction : Vector3 
var movement_direction_x : float
var movement_direction_z : float

var can_jump : bool = true 
var is_jumping : bool = false 

const INITIAL_JUMP_FORCE : float = 20.0
const GRADUAL_JUMP_FORCE : float = 1.0

var current_jump_time : float = 0.0 
const JUMP_TIME_PROGRESSION : float = 0.045 
const JUMP_TIME_AWAIT_DURATION : float = 0.001 
const MIN_JUMP_TIME : float = 0.0
const MAX_JUMP_TIME : float = 0.35

var is_jump_input_buffered : bool = false
var current_jump_buffer_duration : float = 0.0
const MAX_JUMP_BUFFER_DURATION : float = 0.10
const MIN_JUMP_BUFFER_DURATION : float = 0.0
const JUMP_BUFFER_PROGRESSION : float = 0.045 
const JUMP_BUFFER_AWAIT_DURATION : float = 0.001 

var can_coyote_jump : bool = false
var current_coyote_time : float = 0.0
const MAX_COYOTE_TIME : float = 0.2
const MIN_COYOTE_TIME : float = 0.0
const COYOTE_TIMER_PROGRESSION : float = 0.045 
const COYOTE_TIMER_AWAIT_DURATION : float = 0.001 

var is_newly_grounded : bool = false

var can_spply_gravity : bool = true
var current_gravity_force : float = 115.0
const DEFUALT_GRAVITY_FORCE : float = 115.0
const MIN_GRAVITY_FORCE : float = 0.0

var current_health : int = 100
var current_max_health : int = 100
const DEFAULT_MAX_HEALTH : int = 100
const MIN_HEALTH : int = 0

var can_operate : bool = true
var is_operating : bool = false
var is_operate_input_held : bool = false

@onready var camera : Node = $CameraHorizonalRotation/CameraVerticalRotation/CameraSpringArm/camera
@onready var camera_horizonal_rotation : Node = $CameraHorizonalRotation
@onready var camera_vertical_rotation : Node = $CameraHorizonalRotation/CameraVerticalRotation
const MAX_LOOK_DEGREES : int = 75
const MIN_LOOK_DEGREES : int = -75

@onready var body_parts : Node = $BodyParts
@onready var head_parts : Node = $HeadParts

@onready var player_hitbox : Node = $PlayerDamageTaker
@onready var global_los_checker : Node = $CameraHorizonalRotation/CameraVerticalRotation/GlobalLOSChecker
@onready var los_reference : Node = $LOSReference

@onready var camera_raycast : Node = $CameraHorizonalRotation/CameraVerticalRotation/CameraSpringArm/camera/CameraRaycast
@onready var global_muzzle_raycast : Node = $GlobalMuzzleRaycast

const MIN_PROJECTILE_SHOOT_DISTANCE : float = 9.5
const END_PROJECTILE_SHOOT_DISTANCE : float = 3.0

@onready var global_projectile_origin : Node = $CameraHorizonalRotation/CameraVerticalRotation/GlobalProjectileOrigin

@onready var health_bar : Node = $PlayerHUD/PlayerHealthBar

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
	
	move_and_slide()

func update_current_cam() -> void:
	camera.current = true

func delete_unnecessary_player_nodes_for_self() -> void:
	
	$PlayerDamageTaker.queue_free()

func delete_unnecessary_player_nodes_for_others() -> void:
	
	$PlayerWorldCollision.queue_free()
	$LOSReference.queue_free()
	$GlobalMuzzleRaycast.queue_free()
	$CameraHorizonalRotation.queue_free()
	$PlayerHUD.queue_free()

func start_moving(input:Vector2, delta:float) -> void:
	
	# Set moving to true
	is_moving = true
	
	# Set the current movement direction
	global_movement_direction = camera_horizonal_rotation.basis \
	* Vector3(input.x, 0, input.y)
	
	# Set the player model's rotation direction to movement direction
	if global_movement_direction != Vector3(0.0, 0.0, 0.0):
		
		global_body_and_head_movement_rotation = \
		atan2(global_movement_direction.x, global_movement_direction.z)
	
	# ---------------------------
	
	# Walking movement acceleration (Advances every physics tick in the client script)
	if current_movement_speed < MAX_MOVEMENT_SPEED * current_movement_speed_multiplier:
		
		current_movement_speed = \
		clampf(current_movement_speed + \
		(delta * MOVEMENT_ACCELERATION_RATE), \
		MIN_MOVEMENT_SPEED, MAX_MOVEMENT_SPEED * current_movement_speed_multiplier)
	
	# Movement force
	velocity.x = global_movement_direction.x * current_movement_speed
	velocity.z = global_movement_direction.z * current_movement_speed
	
	# ---------------------------
	
	# Rotate the model with player movement if not operating
	if current_player_body_rotation_direction == PlayerBodyRotatonDirection.FOLLOW_MOVEMENT:
		
		# Rotate the body
		body_parts.rotation.y = lerp(body_parts.rotation.y, global_body_and_head_movement_rotation, \
		BODY_AND_HEAD_ROTATION_INTERPOLATION_WEIGHT)
		
		# Rotate the head
		head_parts.rotation.y = lerp(head_parts.rotation.y, global_body_and_head_movement_rotation, \
		BODY_AND_HEAD_ROTATION_INTERPOLATION_WEIGHT)
	
	# ---------------------------
	
	# Prevents saving a 0.0 input and killing the player's momentum
	if input != Vector2(0,0):
		movement_direction_x = global_movement_direction.x
		movement_direction_z = global_movement_direction.z

func stop_moving(delta:float) -> void:
	
	# This triggers when the player stops moving.
	
	# Set is_moving to false
	is_moving = false
	
	# Add remaining velocity to movement
	velocity.x = movement_direction_x * current_movement_speed
	velocity.z = movement_direction_z * current_movement_speed
	
	# Movement Deceleration
	if current_movement_speed > MIN_MOVEMENT_SPEED:
		
		# If grounded
		if is_airborne == false:
			
			current_movement_speed = \
			clampf(current_movement_speed - \
			(delta * MOVEMENT_DECELERATION_RATE_GROUNDED), \
			MIN_MOVEMENT_SPEED, MAX_MOVEMENT_SPEED * current_movement_speed_multiplier)
			
		# If airborne
		elif is_airborne == true:
			
			current_movement_speed = \
			clampf(current_movement_speed - \
			(delta * MOVEMENT_DECELERATION_RATE_AIRBORNE), \
			MIN_MOVEMENT_SPEED, MAX_MOVEMENT_SPEED * current_movement_speed_multiplier)

func start_jumping() -> void:
	
	# Checks if the player can jump
	if can_jump == false: return
	
	# Checks if the player is already jumping
	if is_jumping == true: return
	
	# Checks if the player is in the air
	if is_airborne == true \
	and can_coyote_jump == false: return
	
	# Sets is_jumping to true
	is_jumping = true
	
	# Ininitial jump velocity
	velocity.y = velocity.y + INITIAL_JUMP_FORCE
	
	# Jump function via a while loop
	while current_jump_time < MAX_JUMP_TIME \
	and is_jumping == true:
		
		# Sets the current jump time
		current_jump_time = clampf(current_jump_time + JUMP_TIME_PROGRESSION, \
		MIN_JUMP_TIME, MAX_JUMP_TIME)
		
		# Adds upward velocity
		velocity.y = velocity.y + GRADUAL_JUMP_FORCE
		
		# Small deley before next loop
		await get_tree().create_timer(JUMP_TIME_AWAIT_DURATION).timeout
		
		# Automatically stop jumping when max jump time is reached
		if current_jump_time == MAX_JUMP_TIME:
			stop_jumping()
	
	# End the jump buffer after the jump
	is_jump_input_buffered = false
	
	# Reset the current buffer timer after the jump
	current_jump_buffer_duration = MIN_JUMP_BUFFER_DURATION

func stop_jumping() -> void:
	
	# Checks if the player is actually jumping
	if is_jumping == false: 
		
		# End coyote time even if `stop_jumping` doesn't go through
		stop_coyote_timer()
		
		return
	
	# Sets Is_jumping to false
	is_jumping = false
	
	# Sets the current jump time to 0
	if current_jump_time != MIN_JUMP_TIME:
		current_jump_time = MIN_JUMP_TIME
	
	# End coyote time upon the jump ending regardless
	stop_coyote_timer()

func trigger_move_and_slide() -> void:
	
	# Used to trigger move_and_slide on-
	# -the client and server independently (This is required)
	move_and_slide()

func apply_gravity(delta: float) -> void:
	
	# Applies gravity when all conditions are met.
	if can_spply_gravity == true \
	and is_airborne == true \
	and is_jumping == false:
		
		# Apply current gravity force every frame
		velocity.y -= current_gravity_force * delta

func check_if_player_is_airborne() -> void:
	
	# Checks if the player is NOT on the floor
	if not is_on_floor():
		
		# Update airborne status to true
		is_airborne = true
		
		if is_jumping == false \
		and is_newly_grounded == false:
			start_coyote_timer()
		
		# Reset grounded status
		is_newly_grounded = true
	
	# Checks if the player IS on the floor
	if is_on_floor():
		
		# Update airborne status to false
		is_airborne = false
		
		# Trigger ground touching functions
		upon_touching_ground()

func upon_touching_ground() -> void:
	
	# Trigger buffered jump
	if is_jump_input_buffered == true:
		start_jumping()
	
	# End coyote time after touching the ground
	stop_coyote_timer()
	
	# Set grounded status
	is_newly_grounded = false

func start_jump_buffer_timer() -> void:
	
	# Reset the current jump buffer duration to 0.0
	current_jump_buffer_duration = MIN_JUMP_BUFFER_DURATION
	
	# Jump buffer time via `while` loop
	while current_jump_buffer_duration < MAX_JUMP_BUFFER_DURATION \
	and is_jump_input_buffered == true:
		
		# Sets the current jump time
		current_jump_buffer_duration = clampf(current_jump_buffer_duration + JUMP_BUFFER_PROGRESSION, \
		MIN_JUMP_BUFFER_DURATION, MAX_JUMP_BUFFER_DURATION)
		
		# Small deley before next loop
		await get_tree().create_timer(JUMP_BUFFER_AWAIT_DURATION).timeout
		
		# Automatically stop jumping when max jump time is reached
		if current_jump_buffer_duration == MAX_JUMP_BUFFER_DURATION:
			
			# Set the buffer to false after timer elapesed
			is_jump_input_buffered = false
			
			# Reset the current buffer timer once fully elapesed
			current_jump_buffer_duration = MIN_JUMP_BUFFER_DURATION

func start_coyote_timer() -> void:
	
	# Prevents repeat start triggers
	if can_coyote_jump == true: return
	
	# Prevents coyote time from triggering while jumping
	if is_jumping == true: 
		stop_coyote_timer()
		return
	
	# Allow the player to coyote jump
	can_coyote_jump = true
	
	# Set gravity force to 0.0
	if current_gravity_force != MIN_GRAVITY_FORCE:
		current_gravity_force = MIN_GRAVITY_FORCE
	
	# Reset the current coyote timer duration to 0.0
	current_coyote_time = MIN_COYOTE_TIME
	
	# Coyote timer via `while` loop
	while current_coyote_time < MAX_COYOTE_TIME \
	and can_coyote_jump == true:
		
		# Sets the current coyote time
		current_coyote_time = clampf(current_coyote_time + COYOTE_TIMER_PROGRESSION, \
		MIN_COYOTE_TIME, MAX_COYOTE_TIME)
		
		# Small deley before next loop
		await get_tree().create_timer(COYOTE_TIMER_AWAIT_DURATION).timeout
		
		# Automatically stop coyote time when max jump time is reached
		if current_coyote_time == MAX_COYOTE_TIME:
			
			# Set the coyote jump to false after timer elapesed
			can_coyote_jump = false
			
			# End coyote time
			stop_coyote_timer()
			
			# Reset the current coyote timer once fully elapesed
			current_coyote_time = MIN_COYOTE_TIME

func stop_coyote_timer() -> void:
	
	# End coyote time
	can_coyote_jump = false
	
	# Set gravity force back to normal
	current_gravity_force = DEFUALT_GRAVITY_FORCE

func check_velocity() -> void:
	
	# Track velocity X
	current_velocity_x = velocity.x
	
	# Track velocity Y
	current_velocity_y = velocity.y
	
	# Track velocity Z
	current_velocity_z = velocity.z
	
	# Print velocity X,Y,Z (Testing only)
	#print("X: ", current_velocity_x, " Y: ", current_velocity_y, " Z: ", current_velocity_z)

func _unhandled_input(event:InputEvent) -> void: #INFO camera Controls
	
	# Checks if the mouse is invisible/captured
	if MouseManager.Is_Mouse_Visible == true: return
	
	# ---------------------------
	
	# Mouse movement variables
	var camera_horizontal_input : float = 0.0
	var camera_vertical_input : float = -0.0
	const nil_camera_input : float = 0.0
	
	# ---------------------------
	
	# Tracks mouse movement and calculates sensitivity
	if event is InputEventMouseMotion and Input.MOUSE_MODE_CAPTURED:
		camera_horizontal_input = - event.relative.x * mouse_sensitivity
		camera_vertical_input = event.relative.y * mouse_sensitivity
	
	# ---------------------------
	
	# Rotates the camera on the Y axis based on tracked mouse movement
	camera_horizonal_rotation.rotate_y(camera_horizontal_input)
	
	# ---------------------------
	
	# Make the player's body rotate with side-to-side movement if the player is operating
	if current_player_body_rotation_direction == PlayerBodyRotatonDirection.FOLLOW_CAMERA:
		
		# Reset the body side-to-side rotation
		body_parts.rotation.y = lerp(body_parts.rotation.y, camera_horizonal_rotation.rotation.y, \
		CAMERA_ALIGNMENT_ROTATION_INTERPOLATION_WEIGHT)
		
		# Move the body with the camera
		body_parts.rotate_y(camera_horizontal_input)
	
	# ---------------------------
	
	# Rotates the camera on the X axis based on tracked mouse movement
	camera_vertical_rotation.rotate_x(camera_vertical_input)
	
	# Clamps upward/downward (X axis) mouse movement
	camera_vertical_rotation.rotation.x = clamp \
	(
		camera_vertical_rotation.rotation.x, 
		deg_to_rad(MIN_LOOK_DEGREES), 
		deg_to_rad(MAX_LOOK_DEGREES)
	)
	
	# ---------------------------
	
	# Make the player's head rotate with pitch movement
	#head_parts.rotation.x = camera_vertical_rotation.rotation.x
	#TODO Rework head movement to have a clamp for side-to-side movement-
	# -and only have the head tilt up/down when at the right angle
	
	# Rotate head parts with the body when operating
	if current_player_head_y_rotation_direction == CurrentPlayerHeadRotationDirectionY.FOLLOW_CAMERA:
		
		# Reset the head side-to-side rotation
		head_parts.rotation.y = lerp(head_parts.rotation.y, camera_horizonal_rotation.rotation.y, \
		CAMERA_ALIGNMENT_ROTATION_INTERPOLATION_WEIGHT)
		
		# Move the head with the camera
		head_parts.rotate_y(camera_horizontal_input)
	
	# ---------------------------
	
	# Prevents the mouse from moving when the mouse stops moving
	camera_horizontal_input = nil_camera_input
	camera_vertical_input = nil_camera_input

func change_player_rotation_for_server(new_player_body_rotation:Vector3, new_player_head_rotation:Vector3,
new_camera_horizontal_rotation:float, new_camera_vertical_rotation:float) -> void:
	
	# Update server's player body rotation
	body_parts.rotation = new_player_body_rotation
	
	# Update server's head up/down rotation
	head_parts.rotation.x = new_player_head_rotation.x
	
	# Update server's head side-to-side rotation with the body
	head_parts.rotation.y = new_player_body_rotation.y
	
	# Update the server's camera horizontal rotation
	camera_horizonal_rotation.rotation.y = new_camera_horizontal_rotation
	
	# Update the server's camera horizontal rotation
	camera_vertical_rotation.rotation.x = new_camera_vertical_rotation

func player_take_damage(damage:int) -> void:
	
	# Checks if health is greater than 0
	if current_health >= MIN_HEALTH:
		
		# Deals damage to the player
		current_health = clampi(current_health - damage, \
		MIN_HEALTH, DEFAULT_MAX_HEALTH)
	
	else: return

func kill_player() -> void:
	
	print("Player Died")
	
	visible = false

func respawn_player(new_spawn_point:Vector3) -> void:
	
	global_position = new_spawn_point
	
	current_health = current_max_health
	
	visible = true

func check_and_change_player_model_rotation_direction() -> void:
	
	# Checks if the player rotates with player movement or camera movement
	if is_operating == true \
	and is_body_rotation_overwritten == false:
		
		current_player_body_rotation_direction = PlayerBodyRotatonDirection.FOLLOW_CAMERA
		current_player_head_y_rotation_direction = CurrentPlayerHeadRotationDirectionY.FOLLOW_CAMERA
		
		# Reset the body side-to-side rotation
		body_parts.rotation.y = lerp(body_parts.rotation.y, camera_horizonal_rotation.rotation.y, \
		CAMERA_ALIGNMENT_ROTATION_INTERPOLATION_WEIGHT)
		
		# Reset the head side-to-side rotation
		head_parts.rotation.y = lerp(head_parts.rotation.y, camera_horizonal_rotation.rotation.y, \
		CAMERA_ALIGNMENT_ROTATION_INTERPOLATION_WEIGHT)
		
	else:
		
		current_player_body_rotation_direction = PlayerBodyRotatonDirection.FOLLOW_MOVEMENT
		current_player_head_y_rotation_direction = CurrentPlayerHeadRotationDirectionY.FOLLOW_MOVEMENT

#func check_raycast_alignment_for_alt_crosshair() -> void:
	#
	## Update the camera raycast
	#camera_raycast.force_raycast_update()
	#
	## Create collision variables
	#var camera_raycast_collision_point : Vector3 = camera_raycast.get_collision_point()
	#var New_Muzzle_Raycast_Target_Location : Vector3 = global_muzzle_raycast.to_local(camera_raycast_collision_point)
	#
	## Update muzzle raycast to go toward camera raycast hit location
	#global_muzzle_raycast.target_position = New_Muzzle_Raycast_Target_Location
	#global_muzzle_raycast.force_raycast_update()
	#
	## Create hit distance variable
	#var muzzle_raycast_hit_distance : Variant
	#
	## Get the distance between the start/end of the muzzle raycast
	#muzzle_raycast_hit_distance = global_muzzle_raycast.global_position.distance_to(camera_raycast.get_collision_point())
	#
	## Check if the player is too close to a wall via the muzzle raycast
	#if muzzle_raycast_hit_distance <= MIN_PROJECTILE_SHOOT_DISTANCE:
		#
		#Alt_Crosshair.show()
		#
		##TODO Doesn't project to the correct position
		#Alt_Crosshair.position = get_viewport().get_camera_3d().\
		#unproject_position(global_muzzle_raycast.get_collision_point())
		#
	#else:
		#
		#Alt_Crosshair.hide()
