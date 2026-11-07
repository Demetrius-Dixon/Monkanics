extends Node

# Lobby Server
var client_manager_to_lobby_server_tcp : StreamPeerTCP
var is_registered_with_lobby_server_tcp : bool = false
var can_poll_lobby_tcp : bool = false
var lobby_server_tcp_data_buffer : PackedByteArray = PackedByteArray()

# Relay Server
var is_connected_to_relay : bool = false

var client_manager_to_relay_server_tcp : StreamPeerTCP
var is_registered_with_relay_server_tcp : bool = false
var can_poll_relay_tcp : bool = false
var relay_server_tcp_data_buffer : PackedByteArray = PackedByteArray()

var client_manager_to_relay_server_udp : PacketPeerUDP
var is_registered_with_relay_udp : bool = false
var can_poll_relay_udp : bool = false
const UDP_REGISTRATION_RETRY_DELAY : float = 0.25

var client_manager_to_relay_server_ordered_udp : PacketPeerUDP
var is_registered_with_relay_ordered_udp : bool = false
var can_poll_relay_ordered_udp : bool = false
var current_ordered_packet_sequence_number : int = 0
const ORDERED_UDP_REGISTRATION_RETRY_DELAY : float = 0.25

# Lobby
var received_active_lobbies : Array[Dictionary] = []
var is_in_lobby : bool = false
var is_host : bool = false
var players_in_lobby : Array

# Client
var client_id : int = 0
var client_player_node : Node = null

# Game
var players : Array[Node]
var projectiles : Array[Node]






func _ready() -> void:
	
	if OS.has_feature(FeatureManager.DEDICATED_SERVER): 
		queue_free()
	else: 
		UiManager.load_ui_element("main_menu")

func _process(_delta: float) -> void:
	
	poll_client_to_lobby_server_tcp()
	decode_lobby_server_tcp_stream()
	
	poll_client_to_relay_server_tcp()
	decode_relay_server_tcp_stream()
	
	poll_client_to_relay_server_udp()
	
	poll_client_to_relay_server_ordered_udp()
	
	if Input.is_action_just_pressed("ui_cancel"):
		
		#pass
		
		MouseManager.toggle_mouse()

func _physics_process(_delta: float) -> void:
	
	host_process()
	
	client_process()

func host_process() -> void:
	
	if is_host == false: return
	if is_connected_to_relay == false: return
	
	host_get_new_gamestate()

func client_process() -> void:
	
	if is_host == true: return
	if is_connected_to_relay == false: return
	
	pass




func create_client_and_connect_to_lobby_server_tcp() -> void:
	
	if OS.has_feature("dedicated_server"): return
	
	if is_registered_with_lobby_server_tcp == true: return
	
	can_poll_lobby_tcp = true
	
	client_manager_to_lobby_server_tcp = StreamPeerTCP.new()
	client_manager_to_lobby_server_tcp.connect_to_host(
		EndpointManager.LOBBY_MANAGER_IPV4, 
		EndpointManager.LOBBY_MANAGER_TCP_PORT)
	
	print("Client Created and Connected to Lobby Server TCP")

func poll_client_to_lobby_server_tcp() -> void:
	
	if can_poll_lobby_tcp == false: return
	
	# Poll Lobby Manager TCP
	client_manager_to_lobby_server_tcp.poll()
	
	var lobby_server_bytes : Variant = client_manager_to_lobby_server_tcp.get_available_bytes()
	
	if lobby_server_bytes > 0:
		
		var data : Variant = client_manager_to_lobby_server_tcp.get_data(
		lobby_server_bytes)[1]
		
		lobby_server_tcp_data_buffer.append_array(data)
		
		#print(data)

func decode_lobby_server_tcp_stream() -> void:
	
	if lobby_server_tcp_data_buffer.is_empty(): return
	
	while lobby_server_tcp_data_buffer.size() >= 4:
		
		var data_size : int = lobby_server_tcp_data_buffer.decode_u32(0)
		
		if lobby_server_tcp_data_buffer.size() < 4 + data_size:
			break
		
		var data : PackedByteArray = lobby_server_tcp_data_buffer.slice(4, 4 + data_size)
		var packet : Variant = JSON.parse_string(data.get_string_from_utf8())
		
		lobby_server_tcp_data_buffer = lobby_server_tcp_data_buffer.slice(4 + data_size)
		
		trigger_lobby_server_tpc_command(packet[&"command"], packet[&"info"])
		
		#print(packet)

func send_tcp_data_to_lobby_server(command:String, info:Variant) -> void:
	
	var packet : Dictionary = {
	&"command": command,
	&"info": info
	}
	
	var data := JSON.stringify(packet).to_utf8_buffer()
	
	client_manager_to_lobby_server_tcp.put_u32(data.size())
	client_manager_to_lobby_server_tcp.put_data(data)

func trigger_lobby_server_tpc_command(command:String, info:Variant) -> void:
	
	# Lobby Manager Registration
	if command == "confirm_lobby_server_tcp_registration":
		
		is_registered_with_lobby_server_tcp = true
		
		client_id = info
		
		print("Client -> Lobby Manager TCP Registered")
	
	# Relay Manager Registration
	if command == "client_connect_to_relay":
		connect_to_relay_server(info)
	
	if command == "confirm_relay_server_tcp_registration":
		
		is_connected_to_relay = true
		
		is_registered_with_relay_server_tcp = true
		
		open_relay_server_udp_channels(info)
		
		print("Client -> Relay Manager TCP Registered")
	
	if command == "confirm_relay_server_udp_registration":
		
		is_registered_with_relay_udp = true
		
		print("Client -> Relay Manager UDP Registered")
	
	if command == "confirm_relay_server_ordered_udp_registration":
		
		is_registered_with_relay_ordered_udp = true
		
		print("Client -> Relay Manager Ordered UDP Registered")
	
	# Lobby Management
	if command == "receive_active_lobby":
		
		received_active_lobbies.append(info)
		
		#print("Lobbies on Client: ", received_active_lobbies)
	
	if command == "join_lobby":
		
		is_in_lobby = true
		
		players_in_lobby.append(client_manager_to_lobby_server_tcp)
		
		UiManager.unload_all_ui_elements()
		
		MapManager.load_map(info[&"map"])









func connect_to_relay_server(relay_to_connect_to:String) -> void:
	
	can_poll_relay_tcp = true
	
	client_manager_to_relay_server_tcp = StreamPeerTCP.new()
	client_manager_to_relay_server_tcp.connect_to_host(
		relay_to_connect_to, 
		EndpointManager.RELAY_MANAGER_TCP_PORT)
	
	await get_tree().create_timer(1).timeout
	
	send_tcp_data_to_relay_server("set_client_id", client_id)

func open_relay_server_udp_channels(relay_to_connect_to:String) -> void:
	
	can_poll_relay_udp = true
	can_poll_relay_ordered_udp = true
	
	client_manager_to_relay_server_udp = PacketPeerUDP.new()
	client_manager_to_relay_server_udp.connect_to_host(
		relay_to_connect_to, 
		EndpointManager.RELAY_MANAGER_UDP_PORT)
	register_to_relay_udp_server()
	
	client_manager_to_relay_server_ordered_udp = PacketPeerUDP.new()
	client_manager_to_relay_server_ordered_udp.connect_to_host(
		relay_to_connect_to, 
		EndpointManager.RELAY_MANAGER_ORDERED_UDP_PORT)
	register_to_relay_ordered_udp_server()

func register_to_relay_udp_server() -> void:
	
	send_udp_packet_to_relay_server("register_to_relay_server_udp", client_id)
	
	confirm_registration_to_relay_udp_server()

func confirm_registration_to_relay_udp_server() -> void:
	
	await get_tree().create_timer(UDP_REGISTRATION_RETRY_DELAY).timeout
	
	if is_registered_with_relay_udp == true: return
	
	register_to_relay_udp_server()

func register_to_relay_ordered_udp_server() -> void:
	
	send_ordered_udp_packet_to_relay_server("register_to_relay_server_ordered_udp", client_id)
	
	confirm_registration_to_relay_ordered_udp_server()

func confirm_registration_to_relay_ordered_udp_server() -> void:
	
	await get_tree().create_timer(ORDERED_UDP_REGISTRATION_RETRY_DELAY).timeout
	
	if is_registered_with_relay_ordered_udp == true: return
	
	register_to_relay_ordered_udp_server()









func poll_client_to_relay_server_tcp() -> void:
	
	# Poll Relay Manager TCP
	if can_poll_relay_tcp == false: return
	
	client_manager_to_relay_server_tcp.poll()
	
	var relay_server_bytes : Variant = client_manager_to_relay_server_tcp.get_available_bytes()
	
	if relay_server_bytes > 0:
		
		var data : Variant = client_manager_to_relay_server_tcp.get_data(
		relay_server_bytes)[1]
		
		relay_server_tcp_data_buffer.append_array(data)
		
		#print(data)

func decode_relay_server_tcp_stream() -> void:
	
	if relay_server_tcp_data_buffer.is_empty(): return
	
	while relay_server_tcp_data_buffer.size() >= 4:
		
		var data_size : int = relay_server_tcp_data_buffer.decode_u32(0)
		
		if relay_server_tcp_data_buffer.size() < 4 + data_size:
			break
		
		var data : PackedByteArray = relay_server_tcp_data_buffer.slice(4, 4 + data_size)
		var packet : Variant = JSON.parse_string(data.get_string_from_utf8())
		
		relay_server_tcp_data_buffer = relay_server_tcp_data_buffer.slice(4 + data_size)
		
		trigger_relay_server_tpc_command(packet[&"command"], packet[&"info"])
		
		#print(packet)

func send_tcp_data_to_relay_server(command:String, info:Variant) -> void:
	
	var packet : Dictionary = {
	&"command": command,
	&"info": info
	}
	
	var data := JSON.stringify(packet).to_utf8_buffer()
	
	client_manager_to_relay_server_tcp.put_u32(data.size())
	client_manager_to_relay_server_tcp.put_data(data)

func trigger_relay_server_tpc_command(command:String, info:Variant) -> void:
	
	# Game
	if command == "new_player_joined":
		
		players_in_lobby.append(info)
		
		spawn_other_player(str(info))
	
	if command == "load_map":
		MapManager.load_map(info)
	
	if command == "spawn_own_player":
		spawn_own_player()







func poll_client_to_relay_server_udp() -> void:
	
	# Poll Relay Manager UDP
	if can_poll_relay_udp == false: return
	
	while client_manager_to_relay_server_udp.get_available_packet_count() > 0:
		
		var packet : Variant = client_manager_to_relay_server_udp.get_packet()
		var packet_string : Variant = packet.get_string_from_utf8()
		
		#print("Client Recieved Packet: ", packet)
		
		var json_translation : Variant = JSON.new()
		json_translation = JSON.parse_string(packet_string)
		packet = json_translation
		
		var command : String = json_translation[&"command"]
		var info : Variant = json_translation[&"info"]
		
		#print("Client Recieved Packet: ", packet)
		
		trigger_relay_server_udp_command(command, info)

func send_udp_packet_to_relay_server(command:String, info:Variant) -> void:
	
	if is_connected_to_relay == false: return
	
	var packet : Dictionary = {&"command": command, &"info": info}
	
	var packet_to_send : Variant = JSON.stringify(packet)
	
	client_manager_to_relay_server_udp.put_packet(packet_to_send.to_utf8_buffer())

@warning_ignore("unused_parameter")
func trigger_relay_server_udp_command(command:String, info:Variant) -> void:
	
	pass







func poll_client_to_relay_server_ordered_udp() -> void:
	
	# Poll Relay Manager Ordered UDP
	if can_poll_relay_ordered_udp == false: return
	
	while client_manager_to_relay_server_ordered_udp.get_available_packet_count() > 0:
		
		var packet : Variant = client_manager_to_relay_server_ordered_udp.get_packet()
		var packet_string : Variant = packet.get_string_from_utf8()
		
		#print("Client Recieved Ordered Packet: ", packet)
		
		var json_translation : Variant = JSON.new()
		json_translation = JSON.parse_string(packet_string)
		packet = json_translation
		
		var command : String = json_translation[&"command"]
		var info : Variant = json_translation[&"info"]
		var sequence_number : int = json_translation[&"sequence_number"]
		var last_sequence_number : int = json_translation[&"last_sequence_number"]
		
		#print("Client Received Ordered Packet: ", packet)
		
		var sequence_difference : int = \
		sequence_number - last_sequence_number
		
		if sequence_difference <= 0:
			
			return
			
		else:
			
			trigger_relay_server_ordered_udp_command(command, info)

func send_ordered_udp_packet_to_relay_server(command:String, info:Variant) -> void:
	
	var packet : Dictionary = {
		&"command": command, 
		&"info": info,
		&"sequence_number": increment_ordered_packet_sequence_number()
		}
	
	var packet_to_send : Variant = JSON.stringify(packet)
	
	client_manager_to_relay_server_ordered_udp.put_packet(packet_to_send.to_utf8_buffer())

func increment_ordered_packet_sequence_number() -> int:
	
	current_ordered_packet_sequence_number = \
	current_ordered_packet_sequence_number + 1
	
	return current_ordered_packet_sequence_number

@warning_ignore("unused_parameter")
func trigger_relay_server_ordered_udp_command(command:String, info:Variant) -> void:
	
	if command == "host_send_gamestate":
		
		pass
		
		
		
		
		#print("Got Gamestate")







func request_active_lobbies_from_server() -> void:
	
	reset_active_lobby_data()
	
	send_tcp_data_to_lobby_server("request_active_lobby", null)

func reset_active_lobby_data() -> void:
	received_active_lobbies.clear()

func request_to_join_lobby(lobby_id:int) -> void:
	send_tcp_data_to_lobby_server("request_to_join_lobby", lobby_id)
	
	#print("CLIENT ATTEMPTED TO JOIN LOBBY")









func create_lobby(lobby_name:String) -> void:
	
	send_tcp_data_to_lobby_server("create_lobby", lobby_name)
	
	is_host = true

func spawn_own_player() -> void:
	
	var own_player : Node = SpawnManager.spawn_local("player", 0,0,0)
	
	own_player.name = "own_player"
	
	own_player.camera.current = true
	
	client_player_node = own_player
	
	players.append(own_player)

func spawn_other_player(node_name:String) -> void:
	
	var new_player : Node = SpawnManager.spawn_local("player", 0,0,0)
	
	new_player.name = str(int(node_name))
	
	players.append(new_player)
	
	#print(client_players)

func send_player_position_to_host() -> void:
	
	if client_player_node == null: 
		
		return
		
	else:
		
		var untrusted_player_position : Vector3 = client_player_node.position
		
		send_ordered_udp_packet_to_relay_server("send_untrusted_position_to_server", untrusted_player_position)

func host_get_new_gamestate() -> void:
	
	var new_gamestate : Array[Dictionary] = []
	
	# Get the state of all connected players
	for player in players:
		
		# Triggers move_and_slide() for all host-side players
		# This line is required for host-side players to move
		player.trigger_move_and_slide()
		
		# Player info for server reference
		new_gamestate.append({
			
			&"NodeName": player.get_name(),
			&"NodePath": player.get_path(),
			&"Position": player.global_position,
			&"Velocity": player.velocity,
			&"BodyRotation": player.body_parts.rotation,
			&"HeadRotation": player.head_parts.rotation
			})
	
	send_ordered_udp_packet_to_relay_server("host_send_gamestate", new_gamestate)
	
	#print(new_gamestate)
