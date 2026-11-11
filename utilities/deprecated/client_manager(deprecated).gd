extends Node
### Something I noticed was this script had a weird PascalCase snake_case mix and I refactored it to use snake_case like the style guide suggests
#------------------------------------------#
"""

This script controls: 
	
	- client creation
	- Sending input to the server
	- Mouse controls and visibility when the player isn't loaded.

The client has authority over this script via:
	
	- "any_peer" RPC calls
	- Local non-networked functions
	
"""
#------------------------------------------#

#------------------------------------------#
# Variables:
#------------------------------------------#

# client Network Info

var port: int = 2006
var temp_server_ip: String = ""

var is_connected_to_server: bool = false
var is_player_spawned_in: bool = false

var local_client_clock: float = 0.0
var synced_client_clock: float = 5.0
const CLOCK_DESYNC_TOLERANCE_RANGE: float = 0.25
const MIN_CLIENT_CLOCK_TIME: float = 0.0
const MAX_CLIENT_CLOCK_TIME: float = 3_600 # 1 hour

var client_player: CharacterBody3D
var client_id_for_client: String
var client_id_for_server: int

#WARNING Only used for a synced client clock. Likely to be removed
var current_packet_rt_time: int
var current_packet_e2e_time: int
#WARNING Only used for a synced client clock. Likely to be removed

var current_actual_ping: float = 0.0
var current_actual_packet_loss_percentage: float = 0.0

var display_ping: int = 0
var display_packet_loss: int = 0

# Player State Managment

var current_client_player_state: Array[Dictionary] = []
var next_client_player_state: Array[Dictionary] = []

const PLAYER_STATE_INTERPOLATION_WEIGHT: float = 0.5
const CORRECTION_INTERPOLATION_WEIGHT: float = 0.25

var current_client_position: Vector3
var previous_client_position: Vector3

# Projectile State Management

const PROJECTILE_POSITION_INTERPOLATION_WEIGHT: float = 0.5

# client Movement Input

var is_holding_move_forward_input: bool = false
var is_holding_move_backward_input: bool = false
var is_holding_move_left_input: bool = false
var is_holding_move_right_input: bool = false

# client Mouse Input

var client_mouse_visible: bool = true

# client Jump Input

var is_pressing_jump_input: bool = false
var is_jump_input_new: bool = true

# client Operate and Invention Input

var is_pressing_operate_input: bool = false
var is_operate_input_new: bool = true
var is_operating: bool = false

enum INVENTION_INVENTORY{
	UNINVENTIVE_0,
	INVENTION_1, INVENTION_2, INVENTION_3, INVENTION_4}
	
var current_equipped_invention: INVENTION_INVENTORY = DEFAULT_EQUIPPED_INVENTION
const DEFAULT_EQUIPPED_INVENTION: INVENTION_INVENTORY = INVENTION_INVENTORY.UNINVENTIVE_0

# Node References

@onready var map_container: Node = $"../CurrentMap"
@onready var player_container: Node = $"../Players"

@onready var player: PackedScene = preload("uid://bv5ucnu7shjsd")

@onready var universal_projectile: PackedScene = preload("uid://bn1b4438pxw3l")
@onready var dummy_projectile: PackedScene = preload("uid://bf2aw1eve6evb")
@onready var projectile_container: Node = $"../Projectiles"

@onready var invention_zero_container: Node = $"../InventionZero"
@onready var invention_zero: PackedScene = preload("uid://bvisvcihh15rj")

#------------------------------------------#
# Virtual Functions:
#------------------------------------------#

func _ready() -> void:
	
	# Checks if the project file is a client
	client_check()

func _physics_process(delta: float) -> void:
	
	# Prevent error from sending an RPC too early
	if is_connected_to_server == false: return
	
	# Progress client-side clock
	tick_client_clocks(delta)
	
	# Sends a UDP (Unreliable) packet to determine round-trip tine (ping)
	#request_server_round_trip_time()
	
	# Prevents error from the player instance not existing
	if is_player_spawned_in == false: return
	
	# Trigger movement input on the client locally
	trigger_movement_input(delta)
	
	# Triggers move_and_slide on the client's predicted player
	trigger_move_and_slide_on_client()
	
	# Tracks the current and previous client positions
	track_client_position()
	
	# Send client player position to the server for replication
	send_client_position_to_server.rpc_id(1, client_id_for_server, \
	current_client_position, previous_client_position)
	
	# Send client player rotation to the server for replication
	send_client_player_rotation_to_server.rpc_id(1, client_id_for_server, \
	client_player.body_parts.rotation, client_player.head_parts.rotation, \
	client_player.camera_horizonal_rotation.rotation.y, \
	client_player.camera_vertical_rotation.rotation.x)

@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	
	# TEST This mouse_vis toggle is for testing purposes only
	# Will be removed in future versions
	if Input.is_action_just_pressed("ui_cancel"):
		if client_mouse_visible == true:
			hide_mouse_cursor()
		elif client_mouse_visible == false:
			show_mouse_cursor()
		else: return
	
	# Prevent error from sending an RPC too early
	if is_connected_to_server == false: return
	
	# Prevents error from the player instance not existing
	if is_player_spawned_in == false: return
	
	# Tracks the current movement buttons being held and not held
	track_movement_input()
	
	# Tracks the non-movement buttons being held and not held
	track_all_button_input()
	
	# Triggers jump input when applicable
	trigger_jump_input()
	
	# Trigger button input on the client locally
	trigger_operate_input()

#------------------------------------------#
# client Creation:
#------------------------------------------#

func client_check() -> void:
	
	# Checks if the project file is a client-
	# -to start the client protocalls
	if OS.has_feature("dedicated_server"): 
		return
	else: 
		start_client_game()
		name = "NetworkManager"

func start_client_game() -> void:
	
	#INFO This auto-join server code is a WIP,- 
	# -as the player will enter a client-side state before joining a server.
	
	# Create client
	var client: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	
	#client.create_client(ServerInfo.RELAY_ROUTER_IPV4, ServerInfo.RELAY_ROUTER_PORT)
	
	# Make the client's multiplayer_peer the client
	multiplayer.multiplayer_peer = client
	
	# Prevents error from sending an RPC too early
	await get_tree().create_timer(0.5).timeout
	is_connected_to_server = true
	
	# Set the client ID variable (To save space)
	client_id_for_client = str(multiplayer.get_unique_id())
	
	# Set the client ID variable as an integer for the server
	client_id_for_server = multiplayer.get_unique_id()
	
	hide_mouse_cursor()

#func _input(event:InputEvent) -> void: # Quit game upon pressing Esc (Testing only)
	#
	#pass

#------------------------------------------#
# client-Side Inputs:
#------------------------------------------#

func track_movement_input() -> void:
	
	# Tracks what movement key is being held and not held
	# Used for input-to-action logic across the client, server, and player
	
	# Move forward (Default: W Key)
	if Input.is_action_pressed("move_forward"):
		is_holding_move_forward_input = true
	else: 
		is_holding_move_forward_input = false
	
	# Move backward (Default: S Key)
	if Input.is_action_pressed("move_backward"):
		is_holding_move_backward_input = true
	else: 
		is_holding_move_backward_input = false
	
	# Move left (Default: A Key)
	if Input.is_action_pressed("move_left"):
		is_holding_move_left_input = true
	else: 
		is_holding_move_left_input = false
	
	# Move right (Default: D Key)
	if Input.is_action_pressed("move_right"):
		is_holding_move_right_input = true
	else: 
		is_holding_move_right_input = false
	
	# Updates the player script if a movement input is held
	if is_holding_move_forward_input == true \
	or is_holding_move_backward_input == true \
	or is_holding_move_left_input == true \
	or is_holding_move_right_input == true:
		
		client_player.is_movement_input_held = true
		
	# Updates the player script if a movement input isn't held
	if is_holding_move_forward_input == false \
	and is_holding_move_backward_input == false \
	and is_holding_move_right_input == false \
	and is_holding_move_left_input == false:
		
		client_player.is_movement_input_held = false

func trigger_movement_input(delta: float) -> void:
	
	# client predicted movement call
	
	# Checks if the node is in the scene tree
	if not player_container.has_node(client_id_for_client): return
	
	# Checks if the player is holding any movement button
	if is_holding_move_forward_input == true \
	or is_holding_move_backward_input == true \
	or is_holding_move_right_input == true \
	or is_holding_move_left_input == true:
		
		# Get player input vectors
		var input: Vector2 = Input.get_vector("move_right", "move_left", "move_backward", "move_forward")
		
		# Move the player on the client
		client_player.start_moving(input, delta)
		
		# Server start moving trigger
		server_apply_client_movement_input.rpc_id(1, \
		client_id_for_server, \
		(Input.get_vector("move_right", "move_left", "move_backward", "move_forward")), \
		delta, &"START_MOVING")
	
	# Checks if the player has all movement keys released to stop moving
	if is_holding_move_forward_input == false \
	and is_holding_move_backward_input == false \
	and is_holding_move_right_input == false \
	and is_holding_move_left_input == false:
		
		# client-side stop moving trigger
		client_player.stop_moving(delta)
		
		# Server-side stop moving trigger
		server_apply_client_movement_input.rpc_id(1, client_id_for_server, Vector2(0,0), \
		delta, &"STOP_MOVING")

func track_all_button_input() -> void:
	
	# Tracks if a non-movement input:
		# Has been pressed
		# Has been held
		# Has been released
		# Is new
	# Used for input-to-action logic across the client, server, and player
	
	# ---------------------------
	# Jump (Default: Spacebar)
	# ---------------------------
	
	if Input.is_action_just_pressed("jump"):
		
		is_pressing_jump_input = true
		
		# Trigger player jump buffer upon client jump input
		if player_container.has_node(client_id_for_client) \
		and player_container.get_node(client_id_for_client).is_airborne == true:
			
			# Set player jump buffer to true
			player_container.get_node(client_id_for_client).is_jump_input_buffered = true
			
			# Start player jump buffer time
			player_container.get_node(client_id_for_client).start_jump_buffer_timer()
	
	if Input.is_action_just_released("jump") \
	and is_pressing_jump_input == true: # <- Checks if the input was held
		
		is_pressing_jump_input = false
	
	# ---------------------------
	# Operate (Default: Left Click)
	# ---------------------------
	
	if Input.is_action_just_pressed("operate"):
		
		is_pressing_operate_input = true
		
		client_player.is_operate_input_held = true
	
	if Input.is_action_just_released("operate") \
	and is_pressing_operate_input == true: # <- Checks if the input was held
		
		is_pressing_operate_input = false
		
		client_player.is_operate_input_held = false

func trigger_jump_input() -> void:
	
	# Check if the client's node tree has their player node
	if not player_container.has_node(client_id_for_client): return
	
	# client predicted jump call (and synced server call)
	
	# Checks if the player is pressing the jump input-
	# -and if the jump input is new
	if is_pressing_jump_input == true \
	and is_jump_input_new == true:
		
		# Trigger client start jumping function
		client_player.start_jumping()
		
		# Server start jumping call
		server_apply_client_button_input.rpc_id(1, client_id_for_server, &"START_JUMPING")
		
		# Makes the jump input not new.
		is_jump_input_new = false
	
	# # Checks if the player released the jump input-
	# -and if the jump input is old
	if is_pressing_jump_input == false \
	and is_jump_input_new == false:
		
		# Trigger client stop jumping function
		client_player.stop_jumping()
		
		# Server stop jumping call
		server_apply_client_button_input.rpc_id(1, client_id_for_server, &"STOP_JUMPING")
		
		# Renew jump input
		is_jump_input_new = true 

func trigger_operate_input() -> void:
	
	# Check if the client's node tree has their player node
	if not player_container.has_node(client_id_for_client): return
	
	# Triggers start operating input
	if is_pressing_operate_input == true \
	and is_operate_input_new == true:
		
		# Local predicted start operating call
		start_operating()
		
		# Makes the operate inout not new
		is_operate_input_new = false
	
	if is_pressing_operate_input == false \
	and is_operate_input_new == false:
		
		# Local predicted stop operating call
		stop_operating()
		
		# Renew operate input
		is_operate_input_new = true

func trigger_move_and_slide_on_client() -> void:
	
	# Checks if client's player is in the scene tree
	if player_container.has_node(client_id_for_client):
		
		# Trigger client player's move_and_slide
		client_player.trigger_move_and_slide()

func start_operating() -> void:
	
	is_operating = true
	
	client_player.is_operating = true
	
	get_player_shooting_parameters()

func stop_operating() -> void:
	
	is_operating = false
	
	client_player.is_operating = false

func show_mouse_cursor() -> void:
	
	# Makes the mouse visible. This is client-side only
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Set the client's mouse vis to true
	client_mouse_visible = true
	
	# Set the player script's mouse vis to true for the camera function
	if player_container.has_node(client_id_for_client):
		
		player_container.get_node(client_id_for_client).Player_Mouse_Visible = true

func hide_mouse_cursor() -> void:
	
	# Makes the mouse invisible. This is client-side only
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Set the client's mouse vis to false
	client_mouse_visible = false
	
	# Set the player script's mouse vis to false for the camera function
	if player_container.has_node(client_id_for_client):
		
		player_container.get_node(client_id_for_client).Player_Mouse_Visible = false

#------------------------------------------#
# Server-Side Player Inputs:
#------------------------------------------#

@rpc("any_peer","call_remote","unreliable_ordered",0) @warning_ignore("unused_parameter")
func server_apply_client_movement_input(sender_client_id: int, input: Vector2, delta: float, client_movement_intention: StringName) -> void:
	
	# Does nothing intentionally. Only used to communicate with the server
	pass

@rpc("any_peer","call_remote","reliable", 0) @warning_ignore("unused_parameter")
func server_apply_client_button_input(sender_client_id:int, client_player_input_intention:StringName) -> void:
	
	# Does nothing intentionally. Only used to communicate with the server
	pass

#------------------------------------------#
# client <-> Server Spawn Management:
#------------------------------------------#

@rpc("authority","call_remote","reliable", 0)
func server_spawn_new_players(id: int) -> void:
	
	# Creates player
	var spawning_player_refrence: Node = player.instantiate()
	
	# Updates player node name to the sent id
	spawning_player_refrence.name = str(id)
	
	# Adds the player to the server scene
	player_container.add_child(spawning_player_refrence, true)
	
	# Check if the scene has the player node-
	# -and is the spawning player is theirs
	if player_container.has_node(str(id)) \
	and id == multiplayer.get_unique_id():
		
		# Update the client's Player ID var and current camera
		player_container.get_node(str(id)).update_player_id(str(id))
		player_container.get_node(str(id)).update_current_cam(str(id))
		player_container.get_node(str(id)).delete_unnecessary_player_nodes_for_self()
		
		# Set the client player variable (To save space)
		client_player = player_container.get_node(str(id))
		
		# Set player spawn to true
		is_player_spawned_in = true
		
		# Spawn all inventions in the scene
		spawn_all_inventions_on_client()
		
	# Spawn player that isn't the client's without info
	elif player_container.has_node(str(id)) \
	and id != multiplayer.get_unique_id(): 
		
		# Delete all unnecessary player nodes to save memory
		player_container.get_node(str(id)).delete_unnecessary_player_nodes_for_others()
		
	else: return

@rpc("authority","call_remote","reliable", 0) @warning_ignore("unused_parameter")
func server_spawn_old_players(id: int, old_player_id: int) -> void:
	
	# Creates player
	var spawning_player_refrence: Node = player.instantiate()
	
	# Updates player node name to the sent id
	spawning_player_refrence.name = str(old_player_id)
	
	# Adds the player to the server scene
	player_container.add_child(spawning_player_refrence, true)
	
	# Delete all unnecessary player nodes to save memory
	player_container.get_node(str(old_player_id)).delete_unnecessary_player_nodes_for_others()

@rpc("authority","call_remote","reliable", 0)
func server_despawn_player(id_to_despawm: int) -> void:
	
	# WARNING This function is a WIP.
	# This isn't proper "leave the game" code.
	
	# Checks if the scene has the player node
	if player_container.has_node(str(id_to_despawm)):
		
		# Remove the player from the scene
		player_container.get_node(str(id_to_despawm)).queue_free()
		
	else: return

#------------------------------------------#
# client <-> Server Movement Management:
#------------------------------------------#

func track_client_position() -> void:
	
	# Set the previous local client position in case of invalid movement
	previous_client_position = current_client_position
	
	# Set the new local client position
	current_client_position = client_player.global_position

@rpc("any_peer","call_remote","unreliable_ordered", 0) @warning_ignore("unused_parameter", "shadowed_variable")
func send_client_position_to_server(sender_client_id: int, client_position: Vector3, previous_client_position: Vector3) -> void:
	
	# Does nothing intentionally. Only used to communicate with the server
	pass

@rpc("authority","call_remote","reliable", 0)
func server_set_client_position() -> void:
	
	pass
	
	#INFO This function is a failsafe for any movement hack- 
	# -but was intentionally left incomplete due to the lack of practical data
	
	## Reset the client's position to the last valid one
	#client_player.global_position = lerp(client_player.global_position, \
	#previous_client_position, INTERPOLATION_WEIGHT)

@rpc("any_peer","call_remote","unreliable_ordered", 0) @warning_ignore("unused_parameter")
func send_client_player_rotation_to_server(sender_client_id: int, 
player_body_rotation: Vector3, player_head_rotation: Vector3,
camera_horizonal_rotation: float, camera_vertical_rotation: float) -> void:
	
	# Does nothing intentionally. Only used to communicate with the server
	pass

#------------------------------------------#
# client <-> Server Invention and Projectile Management:
#------------------------------------------#

func spawn_all_inventions_on_client() -> void:
	
	# ---------------------------
	# Invention 0 (Uninventive Mode)
	# ---------------------------
	
	var invention_zero_Ref: Node = invention_zero.instantiate()
	
	invention_zero_container.add_child(invention_zero_Ref)
	
	invention_zero_Ref.setup_node_references(client_player,
	client_player.global_projectile_origin)

func swap_invention_on_client() -> void:
	
	pass #TODO

func get_player_shooting_parameters() -> void:
	
	if client_player.can_operate == false: return
	
	# Update the camera raycast
	client_player.camera_raycast.force_raycast_update()
	
	# Create collision variables
	var camera_raycast_collision_point: Vector3 = \
	client_player.camera_raycast.get_collision_point()
	
	var new_muzzle_raycast_collision_point: Vector3 = \
	client_player.global_muzzle_raycast.to_local(camera_raycast_collision_point)
	
	# Update muzzle raycast to go toward camera raycast hit location
	client_player.global_muzzle_raycast.target_position = \
	new_muzzle_raycast_collision_point
	client_player.global_muzzle_raycast.force_raycast_update()
	
	# Create hit distance variable
	var muzzle_raycast_hit_distance: float
	
	# Get the distance between the start/end of the muzzle raycast
	muzzle_raycast_hit_distance = client_player.global_muzzle_raycast.global_position\
	.distance_to(client_player.camera_raycast.get_collision_point())
	
	#--------------------------------------------------------------------------#
	
	# Shoot projectiles on the server
	spawn_player_projectile_on_server.rpc_id(1, \
	client_id_for_server, \
	500.0, \
	client_player.global_projectile_origin.global_position, \
	camera_raycast_collision_point, \
	muzzle_raycast_hit_distance, \
	client_player.camera.global_rotation)
	
	# client predicted projectile
	shoot_client_predicted_projectile(500.0, \
	client_player.global_projectile_origin.global_position, \
	camera_raycast_collision_point, \
	muzzle_raycast_hit_distance)
	
	#--------------------------------------------------------------------------#
	
	# Add fire rate delay
	client_player.can_operate = false
	
	# Fire rate timer and action re-enabling
	await get_tree().create_timer(calculate_operation_delay(500)).timeout
	
	client_player.can_operate = true
	
	# Check if the operate input is held for auto fire
	if client_player.is_operating == true: 
		
		get_player_shooting_parameters()

func shoot_client_predicted_projectile(Predicted_Projectile_Speed: float,
Predicted_Projectile_Spawn_Position: Vector3, 
Predicted_Projectile_Target_Position: Vector3, 
Client_Raycast_Hit_Distance: float) -> void:
	
	var Projectile_To_Spawn: Object = universal_projectile.instantiate()
	
	# Add projectile to client scene
	projectile_container.add_child(Projectile_To_Spawn)
	
	# client predicted projectile doesn't rely on client/server calls
	Projectile_To_Spawn.can_act_by_itself = true
	
	# Check if the player is too close to a wall
	if Client_Raycast_Hit_Distance <= client_player.END_PROJECTILE_SHOOT_DISTANCE:
		
		Projectile_To_Spawn.spawned_too_close = true
		
		Projectile_To_Spawn.global_position = \
		client_player.global_projectile_origin.global_position
		
		return
		
	else: 
		
		# If not too close, spawn projectile in it's normal position(s)
		Projectile_To_Spawn.global_position = \
		Predicted_Projectile_Spawn_Position
	
	# Don't rotate the projectile if the model is too close
	if Client_Raycast_Hit_Distance <= client_player.END_PROJECTILE_SHOOT_DISTANCE:
		
		pass
		
	# Check if the muzzle raycast is too close for look_at() to work
	elif Client_Raycast_Hit_Distance <= client_player.MIN_PROJECTILE_SHOOT_DISTANCE:
		
		# If too close, rotate the projectile in the camera's direction
		Projectile_To_Spawn.rotation = client_player.camera.global_rotation
		
	else: 
		
		# If ok, rotate the projectile to the camera raycast's end point
		Projectile_To_Spawn.look_at(Predicted_Projectile_Target_Position)
	
	# Set projectile speed
	Projectile_To_Spawn.assigned_projectile_speed = \
	Predicted_Projectile_Speed

@rpc("any_peer","call_remote","reliable", 0) 
@warning_ignore("unused_parameter") @warning_ignore("shadowed_variable")
func spawn_player_projectile_on_server(sender_client_id:int,
Client_Projectile_Speed:float,
Client_Projectile_Spawn_Position:Vector3, 
Client_Projectile_Target_Position:Vector3) -> void:
	
	# Does nothing intentionally. Only used to communicate with the server
	
	# Called from other scripts, but still passes the checksum because this is-
	# -in the client script
	pass

@rpc("authority","call_remote","reliable",0)
func spawn_dummy_projectile_on_all_clients(
Owning_Client:String,
Projectile_Name:String,
Projectile_NodePath:NodePath,
Projectile_Spawn_Position:Vector3) -> void:
	
	# If the projectile is owned by this client, don't spawn it
	if Owning_Client == client_id_for_client: return
	
	# If the projectile already exists ignore it
	if projectile_container.has_node(Projectile_NodePath): return
	
	# Instantiate projectile
	var Projectile_To_Spawn: Object = dummy_projectile.instantiate()
	
	# Set the projectile's name
	Projectile_To_Spawn.name = Projectile_Name
	
	# Add projectile to client scene
	projectile_container.add_child(Projectile_To_Spawn)
	
	# Set projectile position to it's spawn point
	Projectile_To_Spawn.global_position = Projectile_Spawn_Position

@rpc("authority","call_remote","reliable", 0)
func despawn_dummy_projectile_on_all_clients(
Projectile_NodePath:NodePath) -> void:
	
	if projectile_container.has_node(Projectile_NodePath):
		
		get_node(Projectile_NodePath).queue_free()

#------------------------------------------#
# Player Mortality Management:
#------------------------------------------#

#@rpc("authority","call_remote","reliable",0)
#func server_kill_player() -> void:
	#
	#pass #TODO Will be used later

@rpc("authority","call_remote","reliable", 0)
func server_respawn_player(Player_To_Respawn: NodePath, Respawm_Position: Vector3) -> void:
	
	get_node(Player_To_Respawn).respawn_player(Respawm_Position)

#------------------------------------------#
# client-Side Gamestate Managment:
#------------------------------------------#

@rpc("authority","call_remote","unreliable_ordered", 0)
func broadcast_new_player_state(New_Player_State:Array[Dictionary]) -> void:
	
	# Sets the next player state to interpolate to
	next_client_player_state = New_Player_State
	
	# Loops through the array to update the client's-
	# perspective of all other players
	for state in next_client_player_state:
		
		# Checks if the player node in the loop exists
		# Continues if null
		var All_Players:Node = get_node_or_null(state[&"NP"])
		if All_Players == null: continue
		
		# Saves the name of the player in the loop
		var Name:StringName = state[&"NN"]
		
		# Checks if this is the same client to update network info
		if Name == client_id_for_client:
			
			# Actual ping & packet loss
			current_actual_ping = state[&"P"]
			current_actual_packet_loss_percentage = state[&"PL"]
			
			# Ping & packet loss for UI
			display_ping = int(state[&"P"])
			display_packet_loss = int(state[&"PL"])
			
			All_Players.current_health = state[&"H"]
			client_player.health_bar.change_health_value(state[&"H"])
		
		# Apply all other global player positions client-side-
		# -and interpolate between the last and current state
		# Then, check if this client's predicted move was valid
		if Name != client_id_for_client:
			
			# Update the client's position on the server
			All_Players.global_position = \
			lerp(All_Players.global_position, state[&"POS"], \
			PLAYER_STATE_INTERPOLATION_WEIGHT)
		
		# Update every OTHER player's rotation (Body and Head)
		# Own rotation is local (No prediction or correction needed)
		if Name != client_id_for_client and is_connected_to_server == true:
			
			All_Players.body_parts.rotation = state[&"BR"]
			All_Players.head_parts.rotation = state[&"HR"]
			All_Players.current_health = state[&"H"]
			
		else: pass
	
	# Makes the current client player state the most recent one-
	# -after the player state is applied and interpolated to
	current_client_player_state = next_client_player_state
	
	# Clear the next player state varable for the next use
	next_client_player_state.clear()

@rpc("authority","call_remote","unreliable_ordered", 0)
func broadcast_new_projectile_positions(
Projectile_NodePath: NodePath, 
Projectile_Position: Vector3, 
Owning_Client: String) -> void:
	
	# Check if the dummy projectile should replicate
	if projectile_container.has_node(Projectile_NodePath) \
	and Owning_Client != client_id_for_client:
		
		var Projectile: Node = get_node(Projectile_NodePath)
		
		# Apply new positions to dummy projectiles
		Projectile.global_position = \
		lerp(Projectile.global_position, Projectile_Position, \
		PROJECTILE_POSITION_INTERPOLATION_WEIGHT)

#------------------------------------------#
# client <-> Server Clock Management:
#------------------------------------------#

func set_synced_client_clock(New_Synced_Client_Time:float) -> void:
	
	# Set the client clock to a synced time
	synced_client_clock = clampf(New_Synced_Client_Time, MIN_CLIENT_CLOCK_TIME, MAX_CLIENT_CLOCK_TIME)

func tick_client_clocks(delta:float) -> void:
	
	# Add to the server synced client clock
	synced_client_clock += clampf(delta, MIN_CLIENT_CLOCK_TIME, MAX_CLIENT_CLOCK_TIME)
	
	# Add to the local unsynced client clock
	local_client_clock += clampf(delta, MIN_CLIENT_CLOCK_TIME, MAX_CLIENT_CLOCK_TIME)
	
	#print("client Time: ", synced_client_clock)
	#print("Local client Time: ", local_client_clock)

func request_server_round_trip_time() -> void:
	
	# Sends a unreliable UDP packet to the server and back
	send_round_trip_to_server.rpc_id(1, client_id_for_server, Time.get_ticks_msec())

@rpc("any_peer","call_remote","unreliable", 0) @warning_ignore("unused_parameter")
func send_round_trip_to_server(Client_ID: int, Client_Time: int) -> void:
	
	# Does nothing intentionally. Only used to communicate with the server
	pass

@rpc("any_peer","call_remote","unreliable",  0)
func send_round_trip_back_to_client(Past_Client_Time: int, Server_Timestamp: float) -> void:
	
	# Gets current client time
	var Current_Client_Time: int = Time.get_ticks_msec()
	
	# Calculates approx packet round-trip time (Ping)
	current_packet_rt_time = Current_Client_Time - Past_Client_Time
	
	# Calculated approx packet end-to-end time
	@warning_ignore("integer_division")
	current_packet_e2e_time = current_packet_rt_time / 2
	
	#print("Ping: ", current_packet_rt_time)
	
	# Check if the client and server clock are synced. Correct if not.
	if synced_client_clock < Server_Timestamp - CLOCK_DESYNC_TOLERANCE_RANGE:
		set_synced_client_clock(synced_client_clock + Server_Timestamp + current_packet_rt_time)
	elif synced_client_clock > Server_Timestamp + CLOCK_DESYNC_TOLERANCE_RANGE:
		set_synced_client_clock(synced_client_clock + Server_Timestamp - current_packet_rt_time)

func calculate_operation_delay(Rounds_Per_Minute: float) -> float:
	
	# Formula for calculating RPM for easy fire rate implementation
	return 60.0 / Rounds_Per_Minute

#------------------------------------------#
#------------------------------------------#
