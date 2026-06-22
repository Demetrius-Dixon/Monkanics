extends Node

#------------------------------------------#
"""

This script controls: 
	
	- Client creation
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

# Client Network Info

var Port : int = 2006
var Temp_Server_IP : String = ""

var Is_Connected_To_Server : bool = false
var Is_Player_Spawned_In : bool = false

var Local_Client_Clock : float = 0.0
var Synced_Client_Clock : float = 5.0
const CLOCK_DESYNC_TOLERANCE_RANGE : float = 0.25
const MIN_CLIENT_CLOCK_TIME : float = 0.0
const MAX_CLIENT_CLOCK_TIME : float = 3_600 # 1 hour

var Client_Player : CharacterBody3D
var Client_ID_For_Client : String
var Client_ID_For_Server : int

#WARNING Only used for a synced client clock. Likely to be removed
var Current_Packet_RT_Time : int
var Current_Packet_E2E_Time : int
#WARNING Only used for a synced client clock. Likely to be removed

var Current_Actual_Ping : float = 0.0
var Current_Actual_Packet_Loss_Percentage : float = 0.0

var Display_Ping : int = 0
var Display_Packet_Loss : int = 0

# Player State Managment

var Current_Client_Player_State : Array[Dictionary] = []
var Next_Client_Player_State : Array[Dictionary] = []

const PLAYER_STATE_INTERPOLATION_WEIGHT : float = 0.5
const CORRECTION_INTERPOLATION_WEIGHT : float = 0.25

var Current_Client_Position : Vector3
var Previous_Client_Position : Vector3

# Projectile State Management

const PROJECTILE_POSITION_INTERPOLATION_WEIGHT : float = 0.5

# Client Movement Input

var Is_Holding_Move_Forward_Input : bool = false
var Is_Holding_Move_Backward_Input : bool = false
var Is_Holding_Move_Left_Input : bool = false
var Is_Holding_Move_Right_Input : bool = false

# Client Mouse Input

var Client_Mouse_Visible : bool = true

# Client Jump Input

var Is_Pressing_Jump_Input : bool = false
var Is_Jump_Input_New : bool = true

# Client Operate and Invention Input

var Is_Pressing_Operate_Input : bool = false
var Is_Operate_Input_New : bool = true
var Is_Operating : bool = false

enum INVENTION_INVENTORY{
	UNINVENTIVE_0,
	INVENTION_1, INVENTION_2, INVENTION_3, INVENTION_4}
var Current_Equipped_Invention : INVENTION_INVENTORY = DEFAULT_EQUIPPED_INVENTION
const DEFAULT_EQUIPPED_INVENTION : INVENTION_INVENTORY = INVENTION_INVENTORY.UNINVENTIVE_0

# Node References

@onready var Map_Container : Node = $"../CurrentMap"
@onready var Player_Container : Node = $"../Players"

@onready var Player : PackedScene = preload("uid://bv5ucnu7shjsd")

@onready var Universal_Projectile : PackedScene = preload("uid://bn1b4438pxw3l")
@onready var Dummy_Projectile : PackedScene = preload("uid://bf2aw1eve6evb")
@onready var Projectile_Container : Node = $"../Projectiles"

@onready var Invention_Zero_Container : Node = $"../InventionZero"
@onready var Invention_Zero : PackedScene = preload("uid://bvisvcihh15rj")

#------------------------------------------#
# Virtual Functions:
#------------------------------------------#

func _ready() -> void:
	
	# Checks if the project file is a client
	client_check()

func _physics_process(delta: float) -> void:
	
	# Prevent error from sending an RPC too early
	if Is_Connected_To_Server == false: return
	
	# Progress client-side clock
	tick_client_clocks(delta)
	
	# Sends a UDP (Unreliable) packet to determine round-trip tine (ping)
	#request_server_round_trip_time()
	
	# Prevents error from the player instance not existing
	if Is_Player_Spawned_In == false: return
	
	# Trigger movement input on the client locally
	trigger_movement_input(delta)
	
	# Triggers move_and_slide on the client's predicted player
	trigger_move_and_slide_on_client()
	
	# Tracks the current and previous client positions
	track_client_position()
	
	# Send client player position to the server for replication
	send_client_position_to_server.rpc_id(1, Client_ID_For_Server, \
	Current_Client_Position, Previous_Client_Position)
	
	# Send client player rotation to the server for replication
	send_client_player_rotation_to_server.rpc_id(1, Client_ID_For_Server, \
	Client_Player.Body_Parts.rotation, Client_Player.Head_Parts.rotation, \
	Client_Player.Camera_Horizonal_Rotation.rotation.y, \
	Client_Player.Camera_Vertical_Rotation.rotation.x)

@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	
	# TEST This mouse_vis toggle is for testing purposes only
	# Will be removed in future versions
	if Input.is_action_just_pressed("ui_cancel"):
		if Client_Mouse_Visible == true:
			hide_mouse_cursor()
		elif Client_Mouse_Visible == false:
			show_mouse_cursor()
		else: return
	
	# Prevent error from sending an RPC too early
	if Is_Connected_To_Server == false: return
	
	# Prevents error from the player instance not existing
	if Is_Player_Spawned_In == false: return
	
	# Tracks the current movement buttons being held and not held
	track_movement_input()
	
	# Tracks the non-movement buttons being held and not held
	track_all_button_input()
	
	# Triggers jump input when applicable
	trigger_jump_input()
	
	# Trigger button input on the client locally
	trigger_operate_input()

#------------------------------------------#
# Client Creation:
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
	var Client : ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	
	Client.create_client(RelayInfo.RELAY_ROUTER_IPV4, RelayInfo.RELAY_ROUTER_PORT)
	
	# Make the client's multiplayer_peer the client
	multiplayer.multiplayer_peer = Client
	
	# Prevents error from sending an RPC too early
	await get_tree().create_timer(0.5).timeout
	Is_Connected_To_Server = true
	
	# Set the client ID variable (To save space)
	Client_ID_For_Client = str(multiplayer.get_unique_id())
	
	# Set the client ID variable as an integer for the server
	Client_ID_For_Server = multiplayer.get_unique_id()
	
	hide_mouse_cursor()

#func _input(event:InputEvent) -> void: # Quit game upon pressing Esc (Testing only)
	#
	#pass

#------------------------------------------#
# Client-Side Inputs:
#------------------------------------------#

func track_movement_input() -> void:
	
	# Tracks what movement key is being held and not held
	# Used for input-to-action logic across the client, server, and player
	
	# Move forward (Default: W Key)
	if Input.is_action_pressed("move_forward"):
		Is_Holding_Move_Forward_Input = true
	else: 
		Is_Holding_Move_Forward_Input = false
	
	# Move backward (Default: S Key)
	if Input.is_action_pressed("move_backward"):
		Is_Holding_Move_Backward_Input = true
	else: 
		Is_Holding_Move_Backward_Input = false
	
	# Move left (Default: A Key)
	if Input.is_action_pressed("move_left"):
		Is_Holding_Move_Left_Input = true
	else: 
		Is_Holding_Move_Left_Input = false
	
	# Move right (Default: D Key)
	if Input.is_action_pressed("move_right"):
		Is_Holding_Move_Right_Input = true
	else: 
		Is_Holding_Move_Right_Input = false
	
	# Updates the player script if a movement input is held
	if Is_Holding_Move_Forward_Input == true \
	or Is_Holding_Move_Backward_Input == true \
	or Is_Holding_Move_Left_Input == true \
	or Is_Holding_Move_Right_Input == true:
		
		Client_Player.Is_Movement_Input_Held = true
		
	# Updates the player script if a movement input isn't held
	if Is_Holding_Move_Forward_Input == false \
	and Is_Holding_Move_Backward_Input == false \
	and Is_Holding_Move_Right_Input == false \
	and Is_Holding_Move_Left_Input == false:
		
		Client_Player.Is_Movement_Input_Held = false

func trigger_movement_input(delta:float) -> void:
	
	# Client predicted movement call
	
	# Checks if the node is in the scene tree
	if not Player_Container.has_node(Client_ID_For_Client): return
	
	# Checks if the player is holding any movement button
	if Is_Holding_Move_Forward_Input == true \
	or Is_Holding_Move_Backward_Input == true \
	or Is_Holding_Move_Right_Input == true \
	or Is_Holding_Move_Left_Input == true:
		
		# Get player input vectors
		var input:Vector2 = Input.get_vector("move_right", "move_left", "move_backward", "move_forward")
		
		# Move the player on the client
		Client_Player.start_moving(input, delta)
		
		# Server start moving trigger
		server_apply_client_movement_input.rpc_id(1, \
		Client_ID_For_Server, \
		(Input.get_vector("move_right", "move_left", "move_backward", "move_forward")), \
		delta, &"START_MOVING")
	
	# Checks if the player has all movement keys released to stop moving
	if Is_Holding_Move_Forward_Input == false \
	and Is_Holding_Move_Backward_Input == false \
	and Is_Holding_Move_Right_Input == false \
	and Is_Holding_Move_Left_Input == false:
		
		# Client-side stop moving trigger
		Client_Player.stop_moving(delta)
		
		# Server-side stop moving trigger
		server_apply_client_movement_input.rpc_id(1, Client_ID_For_Server, Vector2(0,0), \
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
		
		Is_Pressing_Jump_Input = true
		
		# Trigger player jump buffer upon client jump input
		if Player_Container.has_node(Client_ID_For_Client) \
		and Player_Container.get_node(Client_ID_For_Client).Is_Airborne == true:
			
			# Set player jump buffer to true
			Player_Container.get_node(Client_ID_For_Client).Is_Jump_Input_Buffered = true
			
			# Start player jump buffer time
			Player_Container.get_node(Client_ID_For_Client).start_jump_buffer_timer()
	
	if Input.is_action_just_released("jump") \
	and Is_Pressing_Jump_Input == true: # <- Checks if the input was held
		
		Is_Pressing_Jump_Input = false
	
	# ---------------------------
	# Operate (Default: Left Click)
	# ---------------------------
	
	if Input.is_action_just_pressed("operate"):
		
		Is_Pressing_Operate_Input = true
		
		Client_Player.Is_Operate_Input_Held = true
	
	if Input.is_action_just_released("operate") \
	and Is_Pressing_Operate_Input == true: # <- Checks if the input was held
		
		Is_Pressing_Operate_Input = false
		
		Client_Player.Is_Operate_Input_Held = false

func trigger_jump_input() -> void:
	
	# Check if the client's node tree has their player node
	if not Player_Container.has_node(Client_ID_For_Client): return
	
	# Client predicted jump call (and synced server call)
	
	# Checks if the player is pressing the jump input-
	# -and if the jump input is new
	if Is_Pressing_Jump_Input == true \
	and Is_Jump_Input_New == true:
		
		# Trigger client start jumping function
		Client_Player.start_jumping()
		
		# Server start jumping call
		server_apply_client_button_input.rpc_id(1, Client_ID_For_Server, &"START_JUMPING")
		
		# Makes the jump input not new.
		Is_Jump_Input_New = false
	
	# # Checks if the player released the jump input-
	# -and if the jump input is old
	if Is_Pressing_Jump_Input == false \
	and Is_Jump_Input_New == false:
		
		# Trigger client stop jumping function
		Client_Player.stop_jumping()
		
		# Server stop jumping call
		server_apply_client_button_input.rpc_id(1, Client_ID_For_Server, &"STOP_JUMPING")
		
		# Renew jump input
		Is_Jump_Input_New = true 

func trigger_operate_input() -> void:
	
	# Check if the client's node tree has their player node
	if not Player_Container.has_node(Client_ID_For_Client): return
	
	# Triggers start operating input
	if Is_Pressing_Operate_Input == true \
	and Is_Operate_Input_New == true:
		
		# Local predicted start operating call
		start_operating()
		
		# Makes the operate inout not new
		Is_Operate_Input_New = false
	
	if Is_Pressing_Operate_Input == false \
	and Is_Operate_Input_New == false:
		
		# Local predicted stop operating call
		stop_operating()
		
		# Renew operate input
		Is_Operate_Input_New = true

func trigger_move_and_slide_on_client() -> void:
	
	# Checks if client's player is in the scene tree
	if Player_Container.has_node(Client_ID_For_Client):
		
		# Trigger client player's move_and_slide
		Client_Player.trigger_move_and_slide()

func start_operating() -> void:
	
	Is_Operating = true
	
	Client_Player.Is_Operating = true
	
	get_player_shooting_parameters()

func stop_operating() -> void:
	
	Is_Operating = false
	
	Client_Player.Is_Operating = false

func show_mouse_cursor() -> void:
	
	# Makes the mouse visible. This is client-side only
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Set the client's mouse vis to true
	Client_Mouse_Visible = true
	
	# Set the player script's mouse vis to true for the camera function
	if Player_Container.has_node(Client_ID_For_Client):
		
		Player_Container.get_node(Client_ID_For_Client).Player_Mouse_Visible = true

func hide_mouse_cursor() -> void:
	
	# Makes the mouse invisible. This is client-side only
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Set the client's mouse vis to false
	Client_Mouse_Visible = false
	
	# Set the player script's mouse vis to false for the camera function
	if Player_Container.has_node(Client_ID_For_Client):
		
		Player_Container.get_node(Client_ID_For_Client).Player_Mouse_Visible = false

#------------------------------------------#
# Server-Side Player Inputs:
#------------------------------------------#

@rpc("any_peer","call_remote","unreliable_ordered",0) @warning_ignore("unused_parameter")
func server_apply_client_movement_input(Sender_Client_ID:int, input:Vector2, delta:float, Client_Movement_Intention:StringName) -> void:
	
	# Does nothing intentionally. Only used to communicate with the server
	pass

@rpc("any_peer","call_remote","reliable",0) @warning_ignore("unused_parameter")
func server_apply_client_button_input(Sender_Client_ID:int, Client_Player_Input_Intention:StringName) -> void:
	
	# Does nothing intentionally. Only used to communicate with the server
	pass

#------------------------------------------#
# Client <-> Server Spawn Management:
#------------------------------------------#

@rpc("authority","call_remote","reliable",0)
func server_spawn_new_players(id: int) -> void:
	
	# Creates player
	var Spawning_Player_Ref : Node = Player.instantiate()
	
	# Updates player node name to the sent id
	Spawning_Player_Ref.name = str(id)
	
	# Adds the player to the server scene
	Player_Container.add_child(Spawning_Player_Ref, true)
	
	# Check if the scene has the player node-
	# -and is the spawning player is theirs
	if Player_Container.has_node(str(id)) \
	and id == multiplayer.get_unique_id():
		
		# Update the client's Player ID var and current camera
		Player_Container.get_node(str(id)).update_player_id(str(id))
		Player_Container.get_node(str(id)).update_current_cam(str(id))
		Player_Container.get_node(str(id)).delete_unnecessary_player_nodes_for_self()
		
		# Set the client player variable (To save space)
		Client_Player = Player_Container.get_node(str(id))
		
		# Set player spawn to true
		Is_Player_Spawned_In = true
		
		# Spawn all inventions in the scene
		spawn_all_inventions_on_client()
		
	# Spawn player that isn't the client's without info
	elif Player_Container.has_node(str(id)) \
	and id != multiplayer.get_unique_id(): 
		
		# Delete all unnecessary player nodes to save memory
		Player_Container.get_node(str(id)).delete_unnecessary_player_nodes_for_others()
		
	else: return

@rpc("authority","call_remote","reliable",0) @warning_ignore("unused_parameter")
func server_spawn_old_players(id: int, old_player_id:int) -> void:
	
	# Creates player
	var Spawning_Player_Ref : Node = Player.instantiate()
	
	# Updates player node name to the sent id
	Spawning_Player_Ref.name = str(old_player_id)
	
	# Adds the player to the server scene
	Player_Container.add_child(Spawning_Player_Ref, true)
	
	# Delete all unnecessary player nodes to save memory
	Player_Container.get_node(str(old_player_id)).delete_unnecessary_player_nodes_for_others()

@rpc("authority","call_remote","reliable",0)
func server_despawn_player(id_to_despawm: int) -> void:
	
	# WARNING This function is a WIP.
	# This isn't proper "leave the game" code.
	
	# Checks if the scene has the player node
	if Player_Container.has_node(str(id_to_despawm)):
		
		# Remove the player from the scene
		Player_Container.get_node(str(id_to_despawm)).queue_free()
		
	else: return

#------------------------------------------#
# Client <-> Server Movement Management:
#------------------------------------------#

func track_client_position() -> void:
	
	# Set the previous local client position in case of invalid movement
	Previous_Client_Position = Current_Client_Position
	
	# Set the new local client position
	Current_Client_Position = Client_Player.global_position

@rpc("any_peer","call_remote","unreliable_ordered",0) @warning_ignore("unused_parameter")
func send_client_position_to_server(Sender_Client_ID:int, Client_Position:Vector3, Prev_Client_Position:Vector3) -> void:
	
	# Does nothing intentionally. Only used to communicate with the server
	pass

@rpc("authority","call_remote","reliable",0)
func server_set_client_position() -> void:
	
	pass
	
	#INFO This function is a failsafe for any movement hack- 
	# -but was intentionally left incomplete due to the lack of practical data
	
	## Reset the client's position to the last valid one
	#Client_Player.global_position = lerp(Client_Player.global_position, \
	#Previous_Client_Position, INTERPOLATION_WEIGHT)

@rpc("any_peer","call_remote","unreliable_ordered",0) @warning_ignore("unused_parameter")
func send_client_player_rotation_to_server(Sender_Client_ID:int, 
Player_Body_Rotation:Vector3, Player_Head_Rotation:Vector3,
Camera_Horizonal_Rotation:float, Camera_Vertical_Rotation:float) -> void:
	
	# Does nothing intentionally. Only used to communicate with the server
	pass

#------------------------------------------#
# Client <-> Server Invention and Projectile Management:
#------------------------------------------#

func spawn_all_inventions_on_client() -> void:
	
	# ---------------------------
	# Invention 0 (Uninventive Mode)
	# ---------------------------
	
	var Invention_Zero_Ref : Node = Invention_Zero.instantiate()
	
	Invention_Zero_Container.add_child(Invention_Zero_Ref)
	
	Invention_Zero_Ref.setup_node_references(Client_Player,
	Client_Player.Global_Projectile_Origin)

func swap_invention_on_client() -> void:
	
	pass #TODO

func get_player_shooting_parameters() -> void:
	
	if Client_Player.Can_Operate == false: return
	
	# Update the camera raycast
	Client_Player.Camera_Raycast.force_raycast_update()
	
	# Create collision variables
	var Camera_Raycast_Collision_Point : Vector3 = \
	Client_Player.Camera_Raycast.get_collision_point()
	
	var New_Muzzle_Raycast_Collision_Point : Vector3 = \
	Client_Player.Global_Muzzle_Raycast.to_local(Camera_Raycast_Collision_Point)
	
	# Update muzzle raycast to go toward camera raycast hit location
	Client_Player.Global_Muzzle_Raycast.target_position = \
	New_Muzzle_Raycast_Collision_Point
	Client_Player.Global_Muzzle_Raycast.force_raycast_update()
	
	# Create hit distance variable
	var Muzzle_Raycast_Hit_Distance : float
	
	# Get the distance between the start/end of the muzzle raycast
	Muzzle_Raycast_Hit_Distance = Client_Player.Global_Muzzle_Raycast.global_position\
	.distance_to(Client_Player.Camera_Raycast.get_collision_point())
	
	#--------------------------------------------------------------------------#
	
	# Shoot projectiles on the server
	spawn_player_projectile_on_server.rpc_id(1, \
	Client_ID_For_Server, \
	500.0, \
	Client_Player.Global_Projectile_Origin.global_position, \
	Camera_Raycast_Collision_Point, \
	Muzzle_Raycast_Hit_Distance, \
	Client_Player.Camera.global_rotation)
	
	# Client predicted projectile
	shoot_client_predicted_projectile(500.0, \
	Client_Player.Global_Projectile_Origin.global_position, \
	Camera_Raycast_Collision_Point, \
	Muzzle_Raycast_Hit_Distance)
	
	#--------------------------------------------------------------------------#
	
	# Add fire rate delay
	Client_Player.Can_Operate = false
	
	# Fire rate timer and action re-enabling
	await get_tree().create_timer(calculate_operation_delay(500)).timeout
	
	Client_Player.Can_Operate = true
	
	# Check if the operate input is held for auto fire
	if Client_Player.Is_Operating == true: 
		
		get_player_shooting_parameters()

func shoot_client_predicted_projectile(Predicted_Projectile_Speed:float,
Predicted_Projectile_Spawn_Position:Vector3, 
Predicted_Projectile_Target_Position:Vector3, 
Client_Raycast_Hit_Distance:float) -> void:
	
	var Projectile_To_Spawn : Object = Universal_Projectile.instantiate()
	
	# Add projectile to client scene
	Projectile_Container.add_child(Projectile_To_Spawn)
	
	# Client predicted projectile doesn't rely on client/server calls
	Projectile_To_Spawn.Can_Act_By_Itself = true
	
	# Check if the player is too close to a wall
	if Client_Raycast_Hit_Distance <= Client_Player.END_PROJECTILE_SHOOT_DISTANCE:
		
		Projectile_To_Spawn.Spawned_Too_Close = true
		
		Projectile_To_Spawn.global_position = \
		Client_Player.Global_Projectile_Origin.global_position
		
		return
		
	else: 
		
		# If not too close, spawn projectile in it's normal position(s)
		Projectile_To_Spawn.global_position = \
		Predicted_Projectile_Spawn_Position
	
	# Don't rotate the projectile if the model is too close
	if Client_Raycast_Hit_Distance <= Client_Player.END_PROJECTILE_SHOOT_DISTANCE:
		
		pass
		
	# Check if the muzzle raycast is too close for look_at() to work
	elif Client_Raycast_Hit_Distance <= Client_Player.MIN_PROJECTILE_SHOOT_DISTANCE:
		
		# If too close, rotate the projectile in the camera's direction
		Projectile_To_Spawn.rotation = Client_Player.Camera.global_rotation
		
	else: 
		
		# If ok, rotate the projectile to the camera raycast's end point
		Projectile_To_Spawn.look_at(Predicted_Projectile_Target_Position)
	
	# Set projectile speed
	Projectile_To_Spawn.Assigned_Projectile_Speed = \
	Predicted_Projectile_Speed

@rpc("any_peer","call_remote","reliable",0) 
@warning_ignore("unused_parameter") @warning_ignore("shadowed_variable")
func spawn_player_projectile_on_server(Sender_Client_ID:int,
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
	if Owning_Client == Client_ID_For_Client: return
	
	# If the projectile already exists ignore it
	if Projectile_Container.has_node(Projectile_NodePath): return
	
	# Instantiate projectile
	var Projectile_To_Spawn : Object = Dummy_Projectile.instantiate()
	
	# Set the projectile's name
	Projectile_To_Spawn.name = Projectile_Name
	
	# Add projectile to client scene
	Projectile_Container.add_child(Projectile_To_Spawn)
	
	# Set projectile position to it's spawn point
	Projectile_To_Spawn.global_position = Projectile_Spawn_Position

@rpc("authority","call_remote","reliable",0)
func despawn_dummy_projectile_on_all_clients(
Projectile_NodePath:NodePath) -> void:
	
	if Projectile_Container.has_node(Projectile_NodePath):
		
		get_node(Projectile_NodePath).queue_free()

#------------------------------------------#
# Player Mortality Management:
#------------------------------------------#

#@rpc("authority","call_remote","reliable",0)
#func server_kill_player() -> void:
	#
	#pass #TODO Will be used later

@rpc("authority","call_remote","reliable",0)
func server_respawn_player(Player_To_Respawn:NodePath, Respawm_Position:Vector3) -> void:
	
	get_node(Player_To_Respawn).respawn_player(Respawm_Position)

#------------------------------------------#
# Client-Side Gamestate Managment:
#------------------------------------------#

@rpc("authority","call_remote","unreliable_ordered",0)
func broadcast_new_player_state(New_Player_State:Array[Dictionary]) -> void:
	
	# Sets the next player state to interpolate to
	Next_Client_Player_State = New_Player_State
	
	# Loops through the array to update the client's-
	# perspective of all other players
	for state in Next_Client_Player_State:
		
		# Checks if the player node in the loop exists
		# Continues if null
		var All_Players:Node = get_node_or_null(state[&"NP"])
		if All_Players == null: continue
		
		# Saves the name of the player in the loop
		var Name:StringName = state[&"NN"]
		
		# Checks if this is the same client to update network info
		if Name == Client_ID_For_Client:
			
			# Actual ping & packet loss
			Current_Actual_Ping = state[&"P"]
			Current_Actual_Packet_Loss_Percentage = state[&"PL"]
			
			# Ping & packet loss for UI
			Display_Ping = int(state[&"P"])
			Display_Packet_Loss = int(state[&"PL"])
			
			All_Players.Current_Health = state[&"H"]
			Client_Player.Health_Bar.change_health_value(state[&"H"])
		
		# Apply all other global player positions client-side-
		# -and interpolate between the last and current state
		# Then, check if this client's predicted move was valid
		if Name != Client_ID_For_Client:
			
			# Update the client's position on the server
			All_Players.global_position = \
			lerp(All_Players.global_position, state[&"POS"], \
			PLAYER_STATE_INTERPOLATION_WEIGHT)
		
		# Update every OTHER player's rotation (Body and Head)
		# Own rotation is local (No prediction or correction needed)
		if Name != Client_ID_For_Client and Is_Connected_To_Server == true:
			
			All_Players.Body_Parts.rotation = state[&"BR"]
			All_Players.Head_Parts.rotation = state[&"HR"]
			All_Players.Current_Health = state[&"H"]
			
		else: pass
	
	# Makes the current client player state the most recent one-
	# -after the player state is applied and interpolated to
	Current_Client_Player_State = Next_Client_Player_State
	
	# Clear the next player state varable for the next use
	Next_Client_Player_State.clear()

@rpc("authority","call_remote","unreliable_ordered",0)
func broadcast_new_projectile_positions(
Projectile_NodePath:NodePath, 
Projectile_Position:Vector3, 
Owning_Client:String) -> void:
	
	# Check if the dummy projectile should replicate
	if Projectile_Container.has_node(Projectile_NodePath) \
	and Owning_Client != Client_ID_For_Client:
		
		var Projectile : Node = get_node(Projectile_NodePath)
		
		# Apply new positions to dummy projectiles
		Projectile.global_position = \
		lerp(Projectile.global_position, Projectile_Position, \
		PROJECTILE_POSITION_INTERPOLATION_WEIGHT)

#------------------------------------------#
# Client <-> Server Clock Management:
#------------------------------------------#

func set_synced_client_clock(New_Synced_Client_Time:float) -> void:
	
	# Set the client clock to a synced time
	Synced_Client_Clock = clampf(New_Synced_Client_Time, MIN_CLIENT_CLOCK_TIME, MAX_CLIENT_CLOCK_TIME)

func tick_client_clocks(delta:float) -> void:
	
	# Add to the server synced client clock
	Synced_Client_Clock += clampf(delta, MIN_CLIENT_CLOCK_TIME, MAX_CLIENT_CLOCK_TIME)
	
	# Add to the local unsynced client clock
	Local_Client_Clock += clampf(delta, MIN_CLIENT_CLOCK_TIME, MAX_CLIENT_CLOCK_TIME)
	
	#print("Client Time: ", Synced_Client_Clock)
	#print("Local Client Time: ", Local_Client_Clock)

func request_server_round_trip_time() -> void:
	
	# Sends a unreliable UDP packet to the server and back
	send_round_trip_to_server.rpc_id(1, Client_ID_For_Server, Time.get_ticks_msec())

@rpc("any_peer","call_remote","unreliable",0) @warning_ignore("unused_parameter")
func send_round_trip_to_server(Client_ID:int, Client_Time:int) -> void:
	
	# Does nothing intentionally. Only used to communicate with the server
	pass

@rpc("any_peer","call_remote","unreliable",0)
func send_round_trip_back_to_client(Past_Client_Time:int, Server_Timestamp:float) -> void:
	
	# Gets current client time
	var Current_Client_Time : int = Time.get_ticks_msec()
	
	# Calculates approx packet round-trip time (Ping)
	Current_Packet_RT_Time = Current_Client_Time - Past_Client_Time
	
	# Calculated approx packet end-to-end time
	@warning_ignore("integer_division")
	Current_Packet_E2E_Time = Current_Packet_RT_Time / 2
	
	#print("Ping: ", Current_Packet_RT_Time)
	
	# Check if the client and server clock are synced. Correct if not.
	if Synced_Client_Clock < Server_Timestamp - CLOCK_DESYNC_TOLERANCE_RANGE:
		set_synced_client_clock(Synced_Client_Clock + Server_Timestamp + Current_Packet_RT_Time)
	elif Synced_Client_Clock > Server_Timestamp + CLOCK_DESYNC_TOLERANCE_RANGE:
		set_synced_client_clock(Synced_Client_Clock + Server_Timestamp - Current_Packet_RT_Time)

func calculate_operation_delay(Rounds_Per_Minute:float) -> float:
	
	# Formula for calculating RPM for easy fire rate implementation
	return 60.0 / Rounds_Per_Minute

#------------------------------------------#
#------------------------------------------#
