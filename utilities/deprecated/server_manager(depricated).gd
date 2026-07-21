extends Node
#------------------------------------------#
"""
This script controls: 
	
	- Server creation
	- Server-to-client communication
	- Game management
	- Client management
	
Make sure to:
	Have all server actions be checked with:
		[ if not multiplayer.is_server(): return ]
	
"""
#------------------------------------------#

#------------------------------------------#
# Variables:
#------------------------------------------#

# Server Info

var Port : int = 2006
var Temp_Server_IP : String = ""

const NULL_SERVER_RETURN_VALUE : float = -1.0

# Client Info Arrays

var Connected_Client_IDs : Array[int] = []
var Connected_Client_Players : Array[Node] = []

# Player State Management

var Player_State_History : Array[Array] = []
const MAX_PLAYER_STATE_HISTORY : int = 30

# Projectile Management

var Active_Projectiles : Array[Object]

const MIN_PROJECTILE_SHOOT_DISTANCE : float = 9.5
const END_PROJECTILE_SHOOT_DISTANCE : float = 3.0

# Server Clock Management

var Server_Clock : float = 5.0
const MIN_SERVER_CLOCK_TIME : float = 0.0
const MAX_SERVER_CLOCK_TIME : float = 3_600 # 1 hour

# Node References

@onready var Map_Container : Node = $"../CurrentMap"

@onready var Player_Container : Node = $"../Players"
@onready var Player : PackedScene = preload("uid://bv5ucnu7shjsd")

@onready var Projectile_Container : Node = $"../Projectiles"
@onready var Universal_Projectile : PackedScene = preload("uid://bn1b4438pxw3l")
@onready var Dummy_Projectile : PackedScene = preload("uid://bf2aw1eve6evb")

const DAMAGE_TAKER_NAME : StringName = &"PlayerDamageTaker"

#------------------------------------------#
# Virtual Functions:
#------------------------------------------#

func _ready() -> void:
	
	# Checks if the project file is a server
	server_check()

func _physics_process(delta: float) -> void:
	
	# Checks if this is the server
	if not multiplayer.is_server(): return
	
	# Ticks to progress server-side clock
	tick_server_clock(delta)
	
	# Server gets a new player state every tick
	get_new_gamestate()
	
	# Move all projectiles
	move_all_projectiles()
	
	# Tick all projectile lifetimers
	tick_all_projectile_lifetime_counters(delta)
	
	# Get and set all client ping/packet loss
	update_all_clients_network_info()
	
	#var Current_Map : Node = 
	
	#print(Map_Container.get_child(0).name)
	
	#print($"../CurrentMap/Zoolag".select_spawn_point())

#------------------------------------------#
# Setup Functions:
#------------------------------------------#

func server_check() -> void:
	
	# Checks if the project file is a server-
	# -to start the server protocalls
	if OS.has_feature("dedicated_server"): 
		start_server_game()
		name = "NetworkManager"
	else: return

func select_server_port() -> void: 
	Port = randi_range(2000, 9999)

#------------------------------------------#
# Server Creation and Game Setup:
#------------------------------------------#

func start_server_game() -> void:
	
	# Create server
	var Server : ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	#var Server_Creation : Error = 
	
	Server.set_bind_ip(ServerInfo.RELAY_ROUTER_IPV4)
	
	Server.create_server(ServerInfo.RELAY_ROUTER_PORT)
	
	# Server creation check
	#if Server_Creation != OK:
		#
		##select_server_port()
		#start_server_game()
		#
	#else: pass
	
	print("Server Created")
	
	# Make the server's multiplayer_peer the server
	multiplayer.multiplayer_peer = Server
	
	# Connect server signals
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	#TODO Add other signal connections

func peer_connected(id: int) -> void:
	
	# Checks if this is the server
	if not multiplayer.is_server(): return
	
	# Add the client's id to the id array
	Connected_Client_IDs.append(id)
	
	# Load connected client's player
	server_spawn_old_players(id, Connected_Client_IDs)
	server_spawn_new_players(id)
	
	# Test print
	print(Connected_Client_IDs)

func peer_disconnected(id: int) -> void:
	
	# Checks if this is the server
	if not multiplayer.is_server(): return
	
	# Despawn disconnected client's player
	server_despawn_player(id)

#------------------------------------------#
# Server Spawning and Despawning:
#------------------------------------------#

@rpc("authority","call_remote","reliable",0)
func server_spawn_new_players(id: int) -> void:
	
	# Checks if this is the server
	if not multiplayer.is_server(): return
	
	# Creates player
	var Player_Ref : Node = Player.instantiate()
	
	# Updates player node name to the client's id
	Player_Ref.name = str(id)
	
	# Adds the player to the server scene
	Player_Container.add_child(Player_Ref, true)
	
	# Check if the scene has the player node
	if Player_Container.has_node(str(id)):
		
		# Adds client player to the connected client array
		Connected_Client_Players.append(Player_Container.get_node(str(id)))
		
	else: return
	
	# For loop for currently connected clients
	for client in Connected_Client_IDs:
		
		# Apply the client's id to the rpc_id
		var Sending_Client : int = client
		
		# Spawn player on the all current clients
		server_spawn_new_players.rpc_id(Sending_Client, id)

@rpc("authority","call_remote","reliable",0)
func server_spawn_old_players(id: int, old_player_id:Array[int]) -> void:
	
	# Checks if this is the server
	if not multiplayer.is_server(): return
	
	# Spawn all current players for the joining client
	for old_player in old_player_id:
		
		# Check to not spawn the same new client twice
		if old_player == id: 
			
			pass
			
		else:
			
			# Spawn old players for new clients
			server_spawn_old_players.rpc_id(id, id, old_player)

@rpc("authority","call_remote","reliable",0)
func server_despawn_player(id_to_despawm: int) -> void:
	
	# Checks if this is the server
	if not multiplayer.is_server(): return
	
	# Checks if the server scene has the player node
	if Player_Container.has_node(str(id_to_despawm)):
		
		# Loop through  all clients
		for remaining_clients in Connected_Client_IDs:
			
			# Prevents the remaining clients from being wrongfully despawned
			if remaining_clients == id_to_despawm: 
				pass
			
			# Despawn leaving player on all other clients
			else:
				server_despawn_player.rpc_id(remaining_clients, id_to_despawm)
		
		# Remove the player from the scene
		Player_Container.get_node(str(id_to_despawm)).queue_free()
		
		# Removes the player from the client array (If possible)
		if Connected_Client_Players.has(Player_Container.get_node(str(id_to_despawm))):
			Connected_Client_Players.erase(Player_Container.get_node(str(id_to_despawm)))
		
		# Remove the client's id to the id array (If possible)
		if Connected_Client_IDs.has(id_to_despawm):
			Connected_Client_IDs.erase(id_to_despawm)
			
			# Test print
			print(Connected_Client_IDs)
		
	else: return

#------------------------------------------#
# Networked Client/Server Input Management:
#------------------------------------------#

@rpc("any_peer","call_remote","unreliable_ordered",0)
func server_apply_client_movement_input(Sender_Client_ID:int, input:Vector2, delta:float, Client_Movement_Intention:StringName) -> void:
	
	# Checks if this is the server
	if not multiplayer.is_server(): return
	
	# Checks if the client player exists
	if not Player_Container.has_node(str(Sender_Client_ID)): return
	
	# Input constants
	const START_MOVING : StringName = &"START_MOVING"
	const STOP_MOVING : StringName = &"STOP_MOVING"
	
	# Client movement intention var
	var Current_Client_Player_Movement_Intention : StringName = Client_Movement_Intention
	
	# The client wants their player to start moving
	if Current_Client_Player_Movement_Intention == START_MOVING:
		
		# Tells the client's player to move using the sent input
		Player_Container.get_node(str(Sender_Client_ID)).start_moving(input, delta)
		
	# The client wants their player to stop moving
	elif Current_Client_Player_Movement_Intention == STOP_MOVING:
		
		# Tells the client's player to stop moving
		Player_Container.get_node(str(Sender_Client_ID)).stop_moving(delta)
		
	# Ignore invalid input
	else: return

@rpc("any_peer","call_remote","reliable",0)
func server_apply_client_button_input(Sender_Client_ID:int, Client_Player_Input_Intention:StringName) -> void:
	
	# Checks if this is the server
	if not multiplayer.is_server(): return
	
	# Checks if the client player exists
	if not Player_Container.has_node(str(Sender_Client_ID)): return
	
	# Input constants
	const START_JUMPING : StringName = &"START_JUMPING"
	const STOP_JUMPING : StringName = &"STOP_JUMPING"
	
	# Client movement intention var
	var Current_Client_Player_Input_Intention : StringName = Client_Player_Input_Intention
	
	# Tells to the client's player to start jumping
	if Current_Client_Player_Input_Intention == START_JUMPING:
		
		Player_Container.get_node(str(Sender_Client_ID)).start_jumping()
		
	# Tells to the client's player to stop jumping
	elif Current_Client_Player_Input_Intention == STOP_JUMPING:
		
		Player_Container.get_node(str(Sender_Client_ID)).stop_jumping()
		
	# Ignore invalid input
	else: return

#------------------------------------------#
# Client <-> Server Player Management:
#------------------------------------------#

@rpc("any_peer","call_remote","unreliable_ordered",0) @warning_ignore("unused_parameter")
func send_client_position_to_server(Sender_Client_ID:int, Client_Position:Vector3, Prev_Client_Position:Vector3) -> void:
	
	# Checks if this is the server
	if not multiplayer.is_server(): return
	
	# Checks if the client player exists
	if not Player_Container.has_node(str(Sender_Client_ID)): return
	
	# Client player location vars
	var Min_Accep_Position : Vector3
	var Max_Accep_Position : Vector3
	const ACCEP_POS_X : float = 1.0
	const ACCEP_POS_Y : float = 1.0
	const ACCEP_POS_Z : float = 1.0
	
	# Calculate min and max client predicted position
	Min_Accep_Position = Client_Position - Vector3(ACCEP_POS_X,ACCEP_POS_Y,ACCEP_POS_Z)
	Max_Accep_Position = Client_Position + Vector3(ACCEP_POS_X,ACCEP_POS_Y,ACCEP_POS_Z)
	
	# Check if the server's player is accurate enough to the client player
	if Player_Container.get_node(str(Sender_Client_ID)).global_position <= Client_Position + Max_Accep_Position \
	and Player_Container.get_node(str(Sender_Client_ID)).global_position >= Client_Position - Min_Accep_Position:
		
		# Set the server player's position to the client's position-
		# -for replication
		Player_Container.get_node(str(Sender_Client_ID)).global_position = Client_Position
		
	else:
		
		pass 
		#TODO Adjust so that this DOESN'T trigger while dead
		# (I never knew this worked)
		
		# Set the server's position to the client's LAST accepted position-
		# -for replication upon an invalid position
		#Player_Container.get_node(str(Sender_Client_ID)).global_position = Prev_Client_Position
		
		#INFO This function is a failsafe for any movement hack- 
		# -but was intentionally left incomplete due to the lack of practical data
		
		## Reset the offending client back to their previous valid position
		#server_set_client_position.rpc_id(Sender_Client_ID)

@rpc("authority","call_remote","reliable",0)
func server_set_client_position() -> void:
	
	# Checks if this is the server
	if not multiplayer.is_server(): return
	
	pass 
	
	#INFO This function is a failsafe for any movement hack- 
	# -but was intentionally left incomplete due to the lack of practical data
	
	# Left blank intentionally
	# Only used to communicate with the client

@rpc("any_peer","call_remote","unreliable_ordered",0)
func send_client_player_rotation_to_server(Sender_Client_ID:int, 
Player_Body_Rotation:Vector3, Player_Head_Rotation:Vector3,
Camera_Horizonal_Rotation:float, Camera_Vertical_Rotation:float) -> void:
	
	# Checks if this is the server
	if not multiplayer.is_server(): return
	
	# Checks if the client player exists
	if not Player_Container.has_node(str(Sender_Client_ID)): return
	
	# Change the player's body and head rotation
	Player_Container.get_node(str(Sender_Client_ID)).change_player_rotation_for_server(\
	Player_Body_Rotation, Player_Head_Rotation, Camera_Horizonal_Rotation, Camera_Vertical_Rotation)

#------------------------------------------#
# Client <-> Server Projectile Management:
#------------------------------------------#

@rpc("any_peer","call_remote","reliable",0)
func spawn_player_projectile_on_server(Sender_Client_ID:int,
Client_Projectile_Speed:float,
Client_Projectile_Spawn_Position:Vector3, 
Client_Projectile_Target_Position:Vector3,
Client_Raycast_Hit_Distance:float,
Client_Camera_Rotation:Vector3) -> void:
	
	# Checks if this is the server
	if not multiplayer.is_server(): return
	
	# ------------------------------
	
	# Instantiate universal projectile
	var Projectile_Ref : Node = Universal_Projectile.instantiate()
	
	# ------------------------------
	
	# Apply client projectile stats
	Projectile_Ref.Assigned_Projectile_Speed = Client_Projectile_Speed
	Projectile_Ref.Assigned_Spawn_Position = Client_Projectile_Spawn_Position
	
	# Check if the client's hit distance isn't too close
	if Client_Raycast_Hit_Distance <= MIN_PROJECTILE_SHOOT_DISTANCE:
		
		# If too close, rotate projectile to the client's camera rotation
		Projectile_Ref.Assigned_Target_Rotation = Client_Camera_Rotation
		
	else:
		
		# If ok, rotate toward the client's camera raycast hit position
		Projectile_Ref.Assigned_Target_Position = Client_Projectile_Target_Position
	
	# ------------------------------
	
	# Designate owning client
	Projectile_Ref.Assigned_Owning_Client = str(Sender_Client_ID)
	
	# ------------------------------
	
	# Spawn client projectile in main scene
	Projectile_Container.add_child(Projectile_Ref)
	
	# Connect projectile notifier signal
	Projectile_Ref.connect("notify_Collision_For_Server", \
	process_projectile_collision)
	
	# Gives the projectile a pseudo id number for replication
	Projectile_Ref.name = str(self)
	
	# Check if the client's hit distance isn't too close
	if Client_Raycast_Hit_Distance <= END_PROJECTILE_SHOOT_DISTANCE:
		
		Projectile_Ref.Ready_For_Deletion = true
		
	elif Client_Raycast_Hit_Distance <= MIN_PROJECTILE_SHOOT_DISTANCE:
		
		# # Set the server's spawn and rotation correctly
		Projectile_Ref.initialize_projectile_when_too_close()
		
	else:
		
		# Set the server's spawn and rotation correctly
		Projectile_Ref.initialize_projectile()
	
	# ------------------------------
	
	# Add projectile to active projectile array
	Active_Projectiles.append(Projectile_Ref)
	
	# ------------------------------
	
	# Spawn projectile on all clients
	spawn_dummy_projectile_on_all_clients.rpc( \
	str(Sender_Client_ID), \
	Projectile_Ref.name, \
	Projectile_Ref.get_path(),
	Projectile_Ref.Assigned_Spawn_Position)

func process_projectile_collision(
Body:Node,
Projectile_Damage:float,
Owning_Client:String,
Projectile_NodePath:NodePath) -> void:
	
	# Checks if this is the server
	if not multiplayer.is_server(): return
	
	var Hit_Player : Node = Body.get_parent()
	var Projectile_To_Process : Node = get_node(Projectile_NodePath)
	
	# Check so the owning client doesn't hit themselves
	if Hit_Player.name == Owning_Client:
		
		return
	
	# Deal damage to other client
	if Hit_Player.name != Owning_Client \
	and Body.name == DAMAGE_TAKER_NAME:
		
		Hit_Player.player_take_damage(Projectile_Damage)
		
		print(Hit_Player.Current_Health)
		
		if Hit_Player.Current_Health <= 0:
			
			server_respawn_player(Hit_Player)
		
		Projectile_To_Process.Ready_For_Deletion = true
		
	# If the projectile hits geometry
	else:
		
		Projectile_To_Process.Ready_For_Deletion = true

@rpc("authority","call_remote","reliable",0) @warning_ignore("unused_parameter")
func spawn_dummy_projectile_on_all_clients(
Owning_Client:String,
Projectile_Name:String,
Projectile_NodePath:NodePath,
Projectile_Spawn_Position:Vector3) -> void:
	
	# Checks if this is the server
	if not multiplayer.is_server(): return
	
	# Does nothing intentionally. Only used to communicate with the client.
	pass

@rpc("authority","call_remote","reliable",0) @warning_ignore("unused_parameter")
func despawn_dummy_projectile_on_all_clients(
Projectile_NodePath:NodePath) -> void:
	
	# Checks if this is the server
	if not multiplayer.is_server(): return
	
	# Does nothing intentionally. Used to communicate with the client
	pass

func move_all_projectiles() -> void:
	
	# Checks if this is the server
	if not multiplayer.is_server(): return
	
	# Loop through all server projectiles
	for active_projectile in Active_Projectiles:
		
		active_projectile.move_projectile()

func tick_all_projectile_lifetime_counters(delta:float) -> void:
	
	# Checks if this is the server
	if not multiplayer.is_server(): return
	
	# Loop through all server projectiles
	for active_projectile in Active_Projectiles:
		
		# Tick the lifetime counters down by delta
		active_projectile.Current_Projectile_Lifetime \
		= active_projectile.Current_Projectile_Lifetime + delta
		
		# Remove expired projectiles
		if active_projectile.Current_Projectile_Lifetime \
		>= active_projectile.MAX_PROJECTILE_LIFETIME \
		
		or active_projectile.Ready_For_Deletion == true:
			
			despawn_dummy_projectile_on_all_clients.rpc(
			active_projectile.get_path())
			
			Active_Projectiles.erase(active_projectile)
			
			active_projectile.delete_projectile()

#------------------------------------------#
# Player Mortality Management:
#------------------------------------------#

#@rpc("authority","call_remote","reliable",0)
#func server_kill_player() -> void:
	#
	## Checks if this is the server
	#if not multiplayer.is_server(): return
	#
	#pass #TODO Will be used later

@rpc("authority","call_remote","reliable",0)
func server_respawn_player(Player_To_Respawn:Node) -> void:
	
	# Checks if this is the server
	if not multiplayer.is_server(): return
	
	var Random_Respawn_Position : Vector3 = Map_Container.get_child(0).select_spawn_point()
	
	#print(Random_Respawn_Position)
	
	Player_To_Respawn.respawn_player(Random_Respawn_Position)
	
	server_respawn_player.rpc(Player_To_Respawn.get_path(), Random_Respawn_Position)

#------------------------------------------#
# Server Gamestate and Game history Management:
#------------------------------------------#

func get_new_gamestate() -> void:
	
	# Checks if this is the server
	if not multiplayer.is_server(): return
	
	# Checks if the client array has elements
	if Connected_Client_Players.is_empty() == true: return
	
	# Save the status of all players in a new array
	var New_Player_State_For_Server : Array[Dictionary] = []
	var New_Player_State_For_Client : Array[Dictionary] = []
	
	# Get the state of all connected players
	for player in Connected_Client_Players:
		
		# Triggers move and slide for all server-side players
		# This line is required
		player.trigger_move_and_slide()
		
		# Player info for server reference
		New_Player_State_For_Server.append(
			
			{
			
			&"Time": Server_Clock,
			&"NodeName": player.get_name(),
			&"NodePath": player.get_path(),
			&"Position": player.global_position,
			&"Velocity": player.velocity,
			&"BodyRotation": player.Body_Parts.rotation,
			&"HeadRotation": player.Head_Parts.rotation,
			&"Ping": get_client_ping(int(player.name)),
			&"PacketLoss": get_client_packet_loss(int(player.name))
			
			}
			
			)
		
		# Player info for client replication
		New_Player_State_For_Client.append(
			
			{
				
				&"NN": player.get_name(), # Node Name
				&"NP": player.get_path(), # Node Path
				&"POS": player.global_position, # Position
				&"BR": player.Body_Parts.rotation, # Body Rotation
				&"HR": player.Head_Parts.rotation, # Head Rotation
				&"H": player.Current_Health, # Health
				&"P": get_client_ping(int(player.name)), # Ping
				&"PL": get_client_packet_loss(int(player.name)) # Packet Loss
				
			}
			
		)
	
	# Save player state history (Last 30 ticks)
	collect_player_state_history(New_Player_State_For_Server)
	
	# Broadcast new player states
	if not Connected_Client_Players.is_empty():
		broadcast_new_player_state.rpc(New_Player_State_For_Client)
	
	# Broadcast new projectile positions
	if not Active_Projectiles.is_empty():
		broadcast_new_projectile_positions()

@rpc("authority","call_remote","unreliable_ordered",0) @warning_ignore("unused_parameter")
func broadcast_new_player_state(New_Player_State:Array[Dictionary]) -> void:
	
	# Checks if this is the server
	if not multiplayer.is_server(): return
	
	pass
	
	# Server doesn't have a function body because-
	# -the state of the players are already on the server.
	
	# This prevents redundent rpc calls on the server-
	# -while still allowing the checksum to pass.
	
	# Only the client needs to send info to other clients via this call.

@rpc("authority","call_remote","unreliable_ordered",0) @warning_ignore("unused_parameter")
func broadcast_new_projectile_positions() -> void:
	
	# Checks if this is the server
	if not multiplayer.is_server(): return
	
	# Loop through all projectiles individually
	for projectile_to_replicate in Active_Projectiles:
		
		# Send separate RPCs for every projectile
		broadcast_new_projectile_positions.rpc(projectile_to_replicate.get_path(), 
		projectile_to_replicate.global_position,
		projectile_to_replicate.Assigned_Owning_Client)

func collect_player_state_history(New_Player_State:Array[Dictionary]) -> void:
	
	# Checks if this is the server
	if not multiplayer.is_server(): return
	
	# Checks if the state history array is full
	if Player_State_History.size() == MAX_PLAYER_STATE_HISTORY:
		
		# Removes the oldest gamestate if the array is full
		Player_State_History.push_front(New_Player_State)
		Player_State_History.pop_back()
		
	else:
		
		# Adds a new gamestate element if the array has space
		Player_State_History.push_front(New_Player_State)

#------------------------------------------#
# Client <-> Server Stat Management:
#------------------------------------------#

@rpc("any_peer","call_remote","unreliable",0)
func send_round_trip_to_server(Client_ID:int, Client_Time:int) -> void:
	
	# Checks if this is the server
	if not multiplayer.is_server(): return
	
	# Relays another packet and sends it back to the client-
	# -to calculate round-trip time for packets. (Ping)
	send_round_trip_back_to_client.rpc_id(Client_ID, Client_Time, Server_Clock)

@rpc("any_peer","call_remote","unreliable",0) @warning_ignore("unused_parameter")
func send_round_trip_back_to_client(Past_Client_Time:int, Server_Timestamp:float) -> void:
	
	# Checks if this is the server
	if not multiplayer.is_server(): return
	
	# Does nothing intentionally. Used to communicate with the client
	pass

func tick_server_clock(delta:float) -> void:
	
	# Checks if this is the server
	if not multiplayer.is_server(): return
	
	# Advance server clock by delta
	Server_Clock += clampf(delta, MIN_SERVER_CLOCK_TIME, MAX_SERVER_CLOCK_TIME)
	
	#print("Server Time: ", Server_Clock)
	
	# Clock wrap function just in case
	# (Will happen if the server's been running for about 231.5~ days straight)
	if Server_Clock >= MAX_SERVER_CLOCK_TIME:
		Server_Clock = MIN_SERVER_CLOCK_TIME

func update_all_clients_network_info() -> void:
	
	# Checks if this is the server
	if not multiplayer.is_server(): return
	
	# Set all client's ping/packet loss values in the server's player
	for client in Connected_Client_IDs:
		
		var Client_Player_Ref : Node = Player_Container.get_node(str(client))
		
		Client_Player_Ref.Client_Ping = \
		get_client_ping(client)
		
		Client_Player_Ref.Client_Packet_Loss_Percentage = \
		get_client_packet_loss(client)

func get_client_ping(Client_ID:int) -> float:
	
	# Checks if this is the server
	if not multiplayer.is_server(): return NULL_SERVER_RETURN_VALUE
	
	var Enet_Multiplayer : ENetMultiplayerPeer = multiplayer.multiplayer_peer
	var Enet_Peer : ENetPacketPeer = Enet_Multiplayer.get_peer(Client_ID)
	
	var Client_Ping : float = Enet_Peer.get_statistic(ENetPacketPeer.PEER_LAST_ROUND_TRIP_TIME)
	
	return Client_Ping

func get_client_packet_loss(Client_ID:int) -> float:
	
	# Checks if this is the server
	if not multiplayer.is_server(): return NULL_SERVER_RETURN_VALUE
	
	var Enet_Multiplayer : ENetMultiplayerPeer = multiplayer.multiplayer_peer
	var Enet_Peer : ENetPacketPeer = Enet_Multiplayer.get_peer(Client_ID)
	
	var Client_Packet_Loss_Percentage : float = Enet_Peer.get_statistic(ENetPacketPeer.PEER_PACKET_LOSS)
	
	return Client_Packet_Loss_Percentage

#------------------------------------------#
#------------------------------------------#
