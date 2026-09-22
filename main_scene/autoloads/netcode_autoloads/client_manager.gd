extends Node

var main_client : StreamPeerTCP
var tcp_data_buffer : PackedByteArray = PackedByteArray()
var can_poll_tcp : bool = false
var game_id : int = 0

var relay_client_udp : PacketPeerUDP
var is_registered_with_relay_udp : bool = false
const UDP_REGISTRATION_RETRY_DELAY : float = 0.25
var can_poll_udp : bool = false

var relay_client_ordered_udp : PacketPeerUDP
var is_registered_with_relay_ordered_udp : bool = false
var current_ordered_packet_sequence_number : int = 0
var last_server_packet_sequence_number : int = 0
const ORDERED_UDP_REGISTRATION_RETRY_DELAY : float = 0.25
var can_poll_ordered_udp : bool = false







func _ready() -> void:
	
	if OS.has_feature("dedicated_server"): 
		queue_free()
	else: 
		
		await get_tree().create_timer(0.01).timeout
		
		UiManager.load_ui_element("main_menu")

func _process(_delta: float) -> void:
	
	poll_client_udp()
	
	poll_client_ordered_udp()
	
	poll_client_tcp()
	decode_tcp_stream()
	
	if Input.is_action_just_pressed("ui_cancel"):
		
		pass

func create_client() -> void:
	
	if OS.has_feature("dedicated_server"): return
	
	can_poll_tcp = true
	
	main_client = StreamPeerTCP.new()
	main_client.connect_to_host(EndpointManager.RELAY_NORTH_AMERICA_IPV4, EndpointManager.RELAY_TCP_PORT)
	
	print("Client Created")

func open_client_udp_channels() -> void:
	
	can_poll_udp = true
	can_poll_ordered_udp = true
	
	relay_client_udp = PacketPeerUDP.new()
	relay_client_udp.connect_to_host(EndpointManager.RELAY_NORTH_AMERICA_IPV4, EndpointManager.RELAY_UDP_PORT)
	register_to_relay_udp_server()
	
	relay_client_ordered_udp = PacketPeerUDP.new()
	relay_client_ordered_udp.connect_to_host(EndpointManager.RELAY_NORTH_AMERICA_IPV4, EndpointManager.RELAY_ORDERED_UDP_PORT)
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
	
	main_client.poll()
	
	var bytes : Variant = main_client.get_available_bytes()
	
	if bytes > 0:
		
		var data : Variant = main_client.get_data(bytes)[1]
		
		tcp_data_buffer.append_array(data)

func decode_tcp_stream() -> void:
	
	if tcp_data_buffer.is_empty(): return
	
	while tcp_data_buffer.size() >= 4:
		
		var data_size : int = tcp_data_buffer.decode_u32(0)
		
		if tcp_data_buffer.size() < 4 + data_size:
			break
		
		var data : PackedByteArray = tcp_data_buffer.slice(4, 4 + data_size)
		var packet : Variant = JSON.parse_string(data.get_string_from_utf8())
		
		tcp_data_buffer = tcp_data_buffer.slice(4 + data_size)
		
		trigger_tpc_client_command(packet[&"command"], packet[&"info"])

func send_tcp_data_to_relay(command:String, info:Variant) -> void:
	
	var packet : Dictionary = {
	&"command": command,
	&"info": info
	}
	
	var data := JSON.stringify(packet).to_utf8_buffer()
	
	main_client.put_u32(data.size())
	main_client.put_data(data)

func trigger_tpc_client_command(command:String, info:Variant) -> void:
	
	if command == "confirm_tcp_registration":
		
		game_id = info
		
		open_client_udp_channels()
		
		print("Client TCP Registered")
	
	if command == "confirm_udp_registration":
		
		is_registered_with_relay_udp = true
		
		print("Client UDP Registered")
	
	if command == "confirm_ordered_udp_registration":
		
		is_registered_with_relay_ordered_udp = true
		
		print("Client Ordered UDP Registered")
	
	if command == "load_map":
		MapManager.load_map(info)
	
	if command == "spawn_own_player":
		
		var spawn_x : float = info[&"x"]
		var spawn_y : float = info[&"y"]
		var spawn_z : float = info[&"z"]
		
		SpawnManager.spawn_local("player", spawn_x, spawn_y, spawn_z)
	
	if command == "spawn_other_player":
		pass






func poll_client_udp() -> void:
	
	if can_poll_udp == false: return
	
	if relay_client_udp.get_available_packet_count() > 0:
		
		var packet : Variant = relay_client_udp.get_packet()
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
	
	relay_client_udp.put_packet(packet_to_send.to_utf8_buffer())

func trigger_udp_client_command(command:String, info:Variant) -> void:
	
	pass







func poll_client_ordered_udp() -> void:
	
	if can_poll_ordered_udp == false: return
	
	if relay_client_ordered_udp.get_available_packet_count() > 0:
		
		var packet : Variant = relay_client_ordered_udp.get_packet()
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
	
	relay_client_ordered_udp.put_packet(packet_to_send.to_utf8_buffer())

func increment_ordered_packet_sequence_number() -> int:
	
	current_ordered_packet_sequence_number = \
	current_ordered_packet_sequence_number + 1
	
	return current_ordered_packet_sequence_number

func trigger_ordered_udp_client_command(command:String, info:Variant) -> void:
	
	pass




func create_lobby() -> void:
	
	send_tcp_data_to_relay("create_lobby", null)
