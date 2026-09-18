extends Node

var relay_client_udp : PacketPeerUDP



var relay_client_tcp : StreamPeerTCP
var tcp_data_buffer : PackedByteArray = PackedByteArray()

var is_registered_with_relay : bool = false

func _ready() -> void:
	
	if OS.has_feature("dedicated_server"): 
		queue_free()
	else: 
		create_client()

func _process(_delta: float) -> void:
	
	poll_client_udp()
	
	
	
	poll_client_tcp()
	decode_tcp_stream()
	
	#if Input.is_action_just_pressed("ui_cancel"):
		
		#pass

func create_client() -> void:
	
	if OS.has_feature("dedicated_server"): return
	
	relay_client_udp = PacketPeerUDP.new()
	relay_client_udp.connect_to_host(EndpointManager.RELAY_SERVER_NA_IPV4, EndpointManager.RELAY_SERVER_PORT)
	
	
	
	relay_client_tcp = StreamPeerTCP.new()
	relay_client_tcp.connect_to_host(EndpointManager.RELAY_SERVER_NA_IPV4, EndpointManager.RELAY_TCP_PORT)
	
	#register_to_relay_server()
	
	print("Client Created")
	
	
	#await get_tree().create_timer(1).timeout
	#
	#SpawnManager.spawn_local("player", 0,0,0)

func register_to_relay_server() -> void:
	
	send_udp_packet_to_relay("register", null)
	
	confirm_registration_to_relay_server()

func confirm_registration_to_relay_server() -> void:
	
	await get_tree().create_timer(1.0).timeout
	
	if is_registered_with_relay == true:
		return
	
	register_to_relay_server()
	
	#print("Confirmed")

#func unregister_from_relay_server() -> void:
	#ClientManager.put_packet("unregister".to_utf8_buffer())



func poll_client_udp() -> void:
	
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
	
	if command == "confirm_registration":
		is_registered_with_relay = true
		
		#print("CLIENT IS REGISTERED")
	
	if command == "load_map":
		MapManager.load_map(info)




func trigger_udp_ordered_client_command(command:String, info:Variant) -> void:
	pass
	
	


func poll_client_tcp() -> void:
	
	relay_client_tcp.poll()
	
	var bytes : Variant = relay_client_tcp.get_available_bytes()
	
	if bytes > 0:
		
		var data : Variant = relay_client_tcp.get_data(bytes)[1]
		
		tcp_data_buffer.append_array(data)

func decode_tcp_stream() -> void:
	
	if tcp_data_buffer.is_empty(): return
	
	while tcp_data_buffer.size() >= 4:
		
		var data_size : int = tcp_data_buffer.decode_u32(0)
		
		if tcp_data_buffer.size() < 4 + data_size:
			break
		
		var data : PackedByteArray = tcp_data_buffer.slice(4, 4 + data_size)
		var packet : Dictionary = JSON.parse_string(data.get_string_from_utf8())
		
		tcp_data_buffer = tcp_data_buffer.slice(4 + data_size)
		
		trigger_tpc_client_command(packet[&"command"], packet[&"info"])

func send_tcp_data_to_relay(command:String, info:Variant) -> void:
	
	var packet : Dictionary = {
	&"command": command,
	&"info": info
	}
	
	var data := JSON.stringify(packet).to_utf8_buffer()
	
	relay_client_tcp.put_u32(data.size())
	relay_client_tcp.put_data(data)

func trigger_tpc_client_command(command:String, info:Variant) -> void:
	pass
	
	
