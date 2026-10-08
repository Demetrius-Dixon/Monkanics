extends Node

var client_manager_to_lobby_manager_tcp : StreamPeerTCP
var is_registered_with_lobby_manager : bool = false

var client_manager_to_relay_manager_tcp : StreamPeerTCP
var is_registered_with_relay_manager : bool = false

var tcp_data_buffer : PackedByteArray = PackedByteArray()
var can_poll_tcp : bool = false

var client_manager_to_relay_manager_udp : PacketPeerUDP
var is_registered_with_relay_udp : bool = false
const UDP_REGISTRATION_RETRY_DELAY : float = 0.25
var can_poll_udp : bool = false

var client_manager_to_relay_manager_ordered_udp : PacketPeerUDP
var is_registered_with_relay_ordered_udp : bool = false
var current_ordered_packet_sequence_number : int = 0
var last_server_packet_sequence_number : int = 0
const ORDERED_UDP_REGISTRATION_RETRY_DELAY : float = 0.25
var can_poll_ordered_udp : bool = false

var received_active_lobbies : Array[Dictionary] = []
var is_in_lobby : bool = false
var is_host : bool = false
var players_in_lobby : Array

var game_id : int = 0
var client_player_node : Node = null

func _ready() -> void:
	
	if OS.has_feature("dedicated_server"): 
		queue_free()
	else: 
		UiManager.load_ui_element("main_menu")

func _process(_delta: float) -> void:
	
	poll_client_tcp()
	decode_tcp_stream()
	
	poll_client_udp()
	
	poll_client_ordered_udp()
	
	if Input.is_action_just_pressed("ui_cancel"):
		
		pass

func _physics_process(_delta: float) -> void:
	pass
	#if is_host == false:
		#send_player_position_to_host()






func create_client() -> void:
	
	if OS.has_feature("dedicated_server"): return
	
	if is_registered_with_lobby_manager == true: return
	
	can_poll_tcp = true
	
	client_manager_to_lobby_manager_tcp = StreamPeerTCP.new()
	client_manager_to_lobby_manager_tcp.connect_to_host(EndpointManager.LOBBY_MANAGER_IPV4, EndpointManager.LOBBY_MANAGER_TCP_PORT)
	
	#client_manager_to_relay_manager_tcp = StreamPeerTCP.new()
	#client_manager_to_relay_manager_tcp.connect_to_host(EndpointManager.relay_regions[&"NA"], EndpointManager.RELAY_MANAGER_TCP_PORT)
	
	print("Client Created")

func open_client_udp_channels() -> void:
	
	can_poll_udp = true
	can_poll_ordered_udp = true
	
	client_manager_to_relay_manager_udp = PacketPeerUDP.new()
	client_manager_to_relay_manager_udp.connect_to_host(EndpointManager.relay_regions[&"NA"], EndpointManager.LOBBY_MANAGER_UDP_PORT)
	register_to_relay_udp_server()
	
	client_manager_to_relay_manager_ordered_udp = PacketPeerUDP.new()
	client_manager_to_relay_manager_ordered_udp.connect_to_host(EndpointManager.relay_regions[&"NA"], EndpointManager.LOBBY_MANAGER_ORDERED_UDP_PORT )
	register_to_relay_ordered_udp_server()

func register_to_relay_udp_server() -> void:
	
	send_udp_packet_to_relay("register_to_udp", game_id)
	
	confirm_registration_to_relay_udp_server()

func confirm_registration_to_relay_udp_server() -> void:
	
	await get_tree().create_timer(UDP_REGISTRATION_RETRY_DELAY).timeout
	
	if is_registered_with_relay_udp == true: return
	
	register_to_relay_udp_server()

func register_to_relay_ordered_udp_server() -> void:
	
	send_ordred_udp_packet_to_relay("register_to_ordered_udp", game_id)
	
	confirm_registration_to_relay_ordered_udp_server()

func confirm_registration_to_relay_ordered_udp_server() -> void:
	
	await get_tree().create_timer(ORDERED_UDP_REGISTRATION_RETRY_DELAY).timeout
	
	if is_registered_with_relay_ordered_udp == true: return
	
	register_to_relay_ordered_udp_server()





func poll_client_tcp() -> void:
	
	if can_poll_tcp == false: return
	
	client_manager_to_lobby_manager_tcp.poll()
	
	var lobby_manager_bytes : Variant = client_manager_to_lobby_manager_tcp.get_available_bytes()
	
	if lobby_manager_bytes > 0:
		
		var data : Variant = client_manager_to_lobby_manager_tcp.get_data(
		lobby_manager_bytes)[1]
		
		#print(data)
		
		tcp_data_buffer.append_array(data)
	
	#client_manager_to_lobby_manager_tcp.poll()
	#
	#var relay_manager_bytes : Variant = client_manager_to_relay_manager_tcp.get_available_bytes()
	#
	#if relay_manager_bytes > 0:
		#
		#var data : Variant = client_manager_to_relay_manager_tcp.get_data(
		#relay_manager_bytes)[1]
		#
		##print(data)
		#
		#tcp_data_buffer.append_array(data)

func decode_tcp_stream() -> void:
	
	if tcp_data_buffer.is_empty(): return
	
	while tcp_data_buffer.size() >= 4:
		
		var data_size : int = tcp_data_buffer.decode_u32(0)
		
		if tcp_data_buffer.size() < 4 + data_size:
			break
		
		var data : PackedByteArray = tcp_data_buffer.slice(4, 4 + data_size)
		var packet : Variant = JSON.parse_string(data.get_string_from_utf8())
		
		tcp_data_buffer = tcp_data_buffer.slice(4 + data_size)
		
		#print(packet)
		
		trigger_tpc_client_command(packet[&"command"], packet[&"info"])

func send_tcp_data_to_lobby_manager(command:String, info:Variant) -> void:
	
	var packet : Dictionary = {
	&"command": command,
	&"info": info
	}
	
	var data := JSON.stringify(packet).to_utf8_buffer()
	
	client_manager_to_lobby_manager_tcp.put_u32(data.size())
	client_manager_to_lobby_manager_tcp.put_data(data)

func send_tcp_data_to_relay_manager(command:String, info:Variant) -> void:
	
	var packet : Dictionary = {
	&"command": command,
	&"info": info
	}
	
	var data := JSON.stringify(packet).to_utf8_buffer()
	
	client_manager_to_relay_manager_tcp.put_u32(data.size())
	client_manager_to_relay_manager_tcp.put_data(data)

func trigger_tpc_client_command(command:String, info:Variant) -> void:
	
	if command == "confirm_tcp_registration":
		
		is_registered_with_lobby_manager = true
		
		game_id = info
		
		#open_client_udp_channels()
		
		#print("Client TCP Registered")
	
	if command == "confirm_udp_registration":
		
		is_registered_with_relay_udp = true
		
		#print("Client UDP Registered")
	
	if command == "confirm_ordered_udp_registration":
		
		is_registered_with_relay_ordered_udp = true
		
		#print("Client Ordered UDP Registered")
	
	if command == "receive_active_lobby":
		
		received_active_lobbies.append(info)
		
		#print("Lobbies on Client: ", received_active_lobbies)
	
	if command == "join_lobby":
		
		is_in_lobby = true
		
		players_in_lobby.append(client_manager_to_lobby_manager_tcp)
		
		UiManager.unload_all_ui_elements()
		
		MapManager.load_map(info[&"map"])
	
	if command == "new_player_joined":
		
		players_in_lobby.append(info)
		
		spawn_other_player(str(info))
	
	if command == "load_map":
		MapManager.load_map(info)
	
	if command == "spawn_own_player":
		spawn_own_player()






func poll_client_udp() -> void:
	
	if can_poll_udp == false: return
	
	if client_manager_to_relay_manager_udp.get_available_packet_count() > 0:
		
		var packet : Variant = client_manager_to_relay_manager_udp.get_packet()
		var packet_string : Variant = packet.get_string_from_utf8()
		
		#print("Client Recieved Packet: ", packet)
		
		var json_translation : Variant = JSON.new()
		json_translation = JSON.parse_string(packet_string)
		packet = json_translation
		
		var command : String = json_translation[&"command"]
		var info : Variant = json_translation[&"info"]
		
		#print("Client Recieved Packet: ", packet)
		
		trigger_udp_client_command(command, info)

func send_udp_packet_to_relay(command:String, info:Variant) -> void:
	
	var packet : Dictionary = {&"command": command, &"info": info}
	
	var packet_to_send : Variant = JSON.stringify(packet)
	
	client_manager_to_relay_manager_udp.put_packet(packet_to_send.to_utf8_buffer())

@warning_ignore("unused_parameter")
func trigger_udp_client_command(command:String, info:Variant) -> void:
	
	pass







func poll_client_ordered_udp() -> void:
	
	if can_poll_ordered_udp == false: return
	
	if client_manager_to_relay_manager_ordered_udp.get_available_packet_count() > 0:
		
		var packet : Variant = client_manager_to_relay_manager_ordered_udp.get_packet()
		var packet_string : Variant = packet.get_string_from_utf8()
		
		#print("Client Recieved Ordered Packet: ", packet)
		
		var json_translation : Variant = JSON.new()
		json_translation = JSON.parse_string(packet_string)
		packet = json_translation
		
		var command : String = json_translation[&"command"]
		var info : Variant = json_translation[&"info"]
		var packet_sequence_number : int = json_translation[&"sequence_number"]
		
		#print("Client Received Ordered Packet: ", packet)
		
		var sequence_difference : int = \
		packet_sequence_number - last_server_packet_sequence_number
		
		if sequence_difference <= 0:
			
			return
			
		else:
			
			trigger_ordered_udp_client_command(command, info)
			
			last_server_packet_sequence_number = packet_sequence_number

func send_ordred_udp_packet_to_relay(command:String, info:Variant) -> void:
	
	var packet : Dictionary = {
		&"command": command, 
		&"info": info,
		&"sequence_number": increment_ordered_packet_sequence_number()
		}
	
	var packet_to_send : Variant = JSON.stringify(packet)
	
	client_manager_to_relay_manager_ordered_udp.put_packet(packet_to_send.to_utf8_buffer())

func increment_ordered_packet_sequence_number() -> int:
	
	current_ordered_packet_sequence_number = \
	current_ordered_packet_sequence_number + 1
	
	return current_ordered_packet_sequence_number

@warning_ignore("unused_parameter")
func trigger_ordered_udp_client_command(command:String, info:Variant) -> void:
	
	if command == "send_untrusted_position_to_host":
		
		#print("GOTTEN")
		pass
		
		








func request_active_lobbies_from_server() -> void:
	
	reset_active_lobby_data()
	
	send_tcp_data_to_lobby_manager("request_active_lobby", null)

func reset_active_lobby_data() -> void:
	received_active_lobbies.clear()

func request_to_join_lobby(lobby_id:int) -> void:
	send_tcp_data_to_lobby_manager("request_to_join_lobby", lobby_id)
	
	#print("CLIENT ATTEMPTED TO JOIN LOBBY")






func create_lobby(lobby_name:String) -> void:
	
	send_tcp_data_to_lobby_manager("create_lobby", lobby_name)
	
	is_host = true

func spawn_own_player() -> void:
	
	var own_player : Node = SpawnManager.spawn_local("player", 0,0,0)
	
	own_player.name = "own_player"
	
	own_player.camera.current = true
	
	client_player_node = own_player

func spawn_other_player(node_name:String) -> void:
	
	var new_player : Node = SpawnManager.spawn_local("player", 0,0,0)
	
	new_player.name = node_name

func send_player_position_to_host() -> void:
	
	if client_player_node == null: 
		
		return
		
	else:
		
		var untrusted_player_position : Vector3 = client_player_node.position
		
		send_ordred_udp_packet_to_relay("send_untrusted_position_to_server", untrusted_player_position)

func host_get_new_gamestate() -> void:
	
	if not is_host: return
	
	
