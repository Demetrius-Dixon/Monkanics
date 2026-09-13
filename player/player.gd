extends CharacterBody3D

var is_walking : bool = false
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

var is_airborne : bool = false
var is_jump_input_new : bool = true
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

var can_apply_gravity : bool = true
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

@onready var camera : Node = $CameraHorizonalRotation/CameraVerticalRotation/CameraSpringArm/Camera
@onready var camera_horizonal_rotation : Node = $CameraHorizonalRotation
@onready var camera_vertical_rotation : Node = $CameraHorizonalRotation/CameraVerticalRotation
const MAX_LOOK_DEGREES : int = 75
const MIN_LOOK_DEGREES : int = -75

@onready var body_parts : Node = $BodyParts
@onready var head_parts : Node = $HeadParts

@onready var player_hitbox : Node = $PlayerDamageTaker
@onready var global_los_checker : Node = $CameraHorizonalRotation/CameraVerticalRotation/GlobalLOSChecker
@onready var los_reference : Node = $LOSReference

@onready var camera_raycast : Node = $CameraHorizonalRotation/CameraVerticalRotation/CameraSpringArm/Camera/CameraRaycast
@onready var global_muzzle_raycast : Node = $GlobalMuzzleRaycast

const MIN_PROJECTILE_SHOOT_DISTANCE : float = 9.5
const END_PROJECTILE_SHOOT_DISTANCE : float = 3.0

@onready var global_projectile_origin : Node = $CameraHorizonalRotation/CameraVerticalRotation/GlobalProjectileOrigin

#@onready var health_bar : Node = $PlayerHUD/PlayerHealthBar

func _ready() -> void:
	
	camera.current = true

func _physics_process(delta: float) -> void:
	
	apply_gravity(delta)
	
	check_if_player_is_airborne()
	
	check_velocity() #INFO Add an "upon_stoping" function later
	
	apply_movement_input(delta)
	
	move_and_slide()

func _process(_delta: float) -> void:
	
	apply_jump_input()

func apply_movement_input(delta:float) -> void:
	
	if InputManager.is_holding_walk_forward_input == true \
	or InputManager.is_holding_walk_backward_input == true \
	or InputManager.is_holding_walk_left_input == true \
	or InputManager.is_holding_walk_right_input == true:
		
		is_movement_input_held = true
		
		var input:Vector2 = Input.get_vector(
		"walk_right", "walk_left", "walk_backward", "walk_forward")
		
		start_walking(input, delta)
	
	if InputManager.is_holding_walk_forward_input == false \
	and InputManager.is_holding_walk_backward_input == false \
	and InputManager.is_holding_walk_left_input == false \
	and InputManager.is_holding_walk_right_input == false:
		
		is_movement_input_held = false
		
		stop_walking(delta)

func start_walking(input:Vector2, delta:float) -> void:
	
	is_walking = true
	
	global_movement_direction = camera_horizonal_rotation.basis \
	* Vector3(input.x, 0, input.y)
	
	if current_movement_speed < MAX_MOVEMENT_SPEED * current_movement_speed_multiplier:
		
		current_movement_speed = \
		clampf(current_movement_speed + \
		(delta * MOVEMENT_ACCELERATION_RATE), \
		MIN_MOVEMENT_SPEED, MAX_MOVEMENT_SPEED * current_movement_speed_multiplier)
	
	velocity.x = global_movement_direction.x * current_movement_speed
	velocity.z = global_movement_direction.z * current_movement_speed
	
	if input != Vector2(0,0):
		movement_direction_x = global_movement_direction.x
		movement_direction_z = global_movement_direction.z

func stop_walking(delta:float) -> void:
	
	is_walking = false
	
	velocity.x = movement_direction_x * current_movement_speed
	velocity.z = movement_direction_z * current_movement_speed
	
	if current_movement_speed > MIN_MOVEMENT_SPEED:
		
		if is_airborne == false:
			
			current_movement_speed = \
			clampf(current_movement_speed - \
			(delta * MOVEMENT_DECELERATION_RATE_GROUNDED), \
			MIN_MOVEMENT_SPEED, MAX_MOVEMENT_SPEED * current_movement_speed_multiplier)
			
		elif is_airborne == true:
			
			current_movement_speed = \
			clampf(current_movement_speed - \
			(delta * MOVEMENT_DECELERATION_RATE_AIRBORNE), \
			MIN_MOVEMENT_SPEED, MAX_MOVEMENT_SPEED * current_movement_speed_multiplier)

func trigger_move_and_slide() -> void:
	move_and_slide()

func apply_jump_input() -> void:
	
	if InputManager.is_pressing_jump_input == true \
	and is_jump_input_new == true:
		
		start_jumping()
		
		is_jump_input_new = false
	
	if InputManager.is_pressing_jump_input == false \
	and is_jump_input_new == false:
		
		stop_jumping()
		
		is_jump_input_new = true

func start_jumping() -> void:
	
	if can_jump == false: return
	
	if is_jumping == true: return
	
	if is_airborne == true \
	and can_coyote_jump == false: return
	
	is_jumping = true
	
	velocity.y = velocity.y + INITIAL_JUMP_FORCE
	
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
	
	is_jump_input_buffered = false
	
	current_jump_buffer_duration = MIN_JUMP_BUFFER_DURATION

func stop_jumping() -> void:
	
	if is_jumping == false: 
		
		stop_coyote_timer()
		
		return
	
	is_jumping = false
	
	if current_jump_time != MIN_JUMP_TIME:
		current_jump_time = MIN_JUMP_TIME
	
	stop_coyote_timer()

func apply_gravity(delta: float) -> void:
	
	if can_apply_gravity == true \
	and is_airborne == true \
	and is_jumping == false:
		
		velocity.y -= current_gravity_force * delta

func check_if_player_is_airborne() -> void:
	
	if not is_on_floor():
		
		is_airborne = true
		
		if is_jumping == false \
		and is_newly_grounded == false:
			start_coyote_timer()
		
		is_newly_grounded = true
	
	if is_on_floor():
		
		is_airborne = false
		
		upon_touching_ground()

func upon_touching_ground() -> void:
	
	if is_jump_input_buffered == true:
		start_jumping()
	
	stop_coyote_timer()
	
	is_newly_grounded = false

func start_jump_buffer_timer() -> void:
	
	current_jump_buffer_duration = MIN_JUMP_BUFFER_DURATION
	
	while current_jump_buffer_duration < MAX_JUMP_BUFFER_DURATION \
	and is_jump_input_buffered == true:
		
		current_jump_buffer_duration = clampf(current_jump_buffer_duration + JUMP_BUFFER_PROGRESSION, \
		MIN_JUMP_BUFFER_DURATION, MAX_JUMP_BUFFER_DURATION)
		
		await get_tree().create_timer(JUMP_BUFFER_AWAIT_DURATION).timeout
		
		if current_jump_buffer_duration == MAX_JUMP_BUFFER_DURATION:
			
			is_jump_input_buffered = false
			
			current_jump_buffer_duration = MIN_JUMP_BUFFER_DURATION

func start_coyote_timer() -> void:
	
	if can_coyote_jump == true: return
	
	if is_jumping == true: 
		stop_coyote_timer()
		return
	
	can_coyote_jump = true
	
	if current_gravity_force != MIN_GRAVITY_FORCE:
		current_gravity_force = MIN_GRAVITY_FORCE
	
	current_coyote_time = MIN_COYOTE_TIME
	
	while current_coyote_time < MAX_COYOTE_TIME \
	and can_coyote_jump == true:
		
		current_coyote_time = clampf(current_coyote_time + COYOTE_TIMER_PROGRESSION, \
		MIN_COYOTE_TIME, MAX_COYOTE_TIME)
		
		await get_tree().create_timer(COYOTE_TIMER_AWAIT_DURATION).timeout
		
		if current_coyote_time == MAX_COYOTE_TIME:
			
			can_coyote_jump = false
			
			stop_coyote_timer()
			
			current_coyote_time = MIN_COYOTE_TIME

func stop_coyote_timer() -> void:
	
	can_coyote_jump = false
	
	current_gravity_force = DEFUALT_GRAVITY_FORCE

func check_velocity() -> void:
	
	current_velocity_x = velocity.x
	
	current_velocity_y = velocity.y
	
	current_velocity_z = velocity.z
	
	#print("X: ", current_velocity_x, \
	#" Y: ", current_velocity_y, \
	#" Z: ", current_velocity_z)

func _unhandled_input(event:InputEvent) -> void: ## Camera Controls
	
	if MouseManager.is_mouse_visible == true: return
	
	var camera_horizontal_input : float = 0.0
	var camera_vertical_input : float = -0.0
	const NULL_CAMERA_INPUT : float = 0.0
	
	if event is InputEventMouseMotion and Input.MOUSE_MODE_CAPTURED:
		camera_horizontal_input = - event.relative.x * SettingsManager.mouse_sensitivity
		camera_vertical_input = event.relative.y * SettingsManager.mouse_sensitivity
	
	# Rotates the camera on the Y axis based on tracked mouse movement
	camera_horizonal_rotation.rotate_y(camera_horizontal_input)
	
	camera_vertical_rotation.rotate_x(camera_vertical_input)
	camera_vertical_rotation.rotation.x = clamp \
	(
		camera_vertical_rotation.rotation.x, 
		deg_to_rad(MIN_LOOK_DEGREES), 
		deg_to_rad(MAX_LOOK_DEGREES)
	)
	
	body_parts.rotate_y(camera_horizontal_input)
	head_parts.rotation.x = camera_vertical_rotation.rotation.x
	head_parts.rotate_y(camera_horizontal_input)
	
	camera_horizontal_input = NULL_CAMERA_INPUT
	camera_vertical_input = NULL_CAMERA_INPUT

#func change_player_rotation_for_server(new_player_body_rotation:Vector3, new_player_head_rotation:Vector3,
#new_camera_horizontal_rotation:float, new_camera_vertical_rotation:float) -> void:
	#
	## Update server's player body rotation
	#body_parts.rotation = new_player_body_rotation
	#
	## Update server's head up/down rotation
	#head_parts.rotation.x = new_player_head_rotation.x
	#
	## Update server's head side-to-side rotation with the body
	#head_parts.rotation.y = new_player_body_rotation.y
	#
	## Update the server's camera horizontal rotation
	#camera_horizonal_rotation.rotation.y = new_camera_horizontal_rotation
	#
	## Update the server's camera horizontal rotation
	#camera_vertical_rotation.rotation.x = new_camera_vertical_rotation

func player_take_damage(damage:int) -> void:
	
	if current_health >= MIN_HEALTH:
		
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
