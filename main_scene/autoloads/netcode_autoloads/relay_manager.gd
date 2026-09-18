extends Node

var relay_server_udp : UDPServer
var relay_server_tcp : TCPServer

var dedicated_server : PacketPeerUDP

var connected_clients : Array[Dictionary] = []
var connected_tcp_clients : Array[Dictionary] = []

var next_client_id_to_assign : int = 0

func _ready() -> void:
	
	if not OS.has_feature("dedicated_server"): 
		queue_free()
	else: 
		create_relay_servers()
		#LobbyManager.create_lobby(dedicated_server)

func _process(_delta: float) -> void:
	
	poll_relay_server_udp()
	
	
	
	poll_relay_server_tcp()
	decode_tcp_stream()

func create_relay_servers() -> void:
	
	relay_server_udp = UDPServer.new()
	relay_server_udp.listen(EndpointManager.RELAY_SERVER_PORT, EndpointManager.RELAY_SERVER_NA_IPV4)
	print("Relay UDP Created")
	
	
	
	relay_server_tcp = TCPServer.new()
	relay_server_tcp.listen(EndpointManager.RELAY_TCP_PORT, EndpointManager.RELAY_SERVER_NA_IPV4)
	print("Relay TCP Created")



func poll_relay_server_udp() -> void:
	
	relay_server_udp.poll()
	
	if relay_server_udp.is_connection_available():
		
		var peer : Variant = relay_server_udp.take_connection()
		var packet : Variant = peer.get_packet().get_string_from_utf8()
		
		#print("Server Received Packet: ", packet)
		
		var json_translation : Variant = JSON.new()
		json_translation = JSON.parse_string(packet)
		packet = json_translation
		
		var command : String = json_translation[&"command"]
		var info : Variant = json_translation[&"info"]
		
		trigger_udp_server_command(command, info, peer, packet)
	
	for client in connected_clients:
		
		if client[&"peer"].get_available_packet_count() > 0:
			
			var peer : PacketPeerUDP = client[&"peer"]
			var packet : Variant = client[&"peer"].get_packet().get_string_from_utf8()
			
			#print("Server Received Packet: ", packet)
			
			var json_translation : Variant = JSON.new()
			json_translation = JSON.parse_string(packet)
			packet = json_translation
			
			var command : String = json_translation[&"command"]
			var info : Variant = json_translation[&"info"]
			
			#print("Server Received Packet: ", packet)
			
			trigger_udp_server_command(command, info, peer, packet)

func send_udp_packet_to_client(command:String, info:Variant, recipient:PacketPeerUDP) -> void:
	
	var packet : Dictionary = {}
	
	packet = {&"command": command, &"info": info}
	
	var packet_to_send : Variant = JSON.stringify(packet)
	
	recipient.put_packet(packet_to_send.to_utf8_buffer())

func forward_udp_packet_to_specific_client(packet:Dictionary, recipient:PacketPeerUDP) -> void:
	
	var packet_to_forward : Variant = JSON.stringify(packet)
	
	recipient.put_packet(packet_to_forward.to_utf8_buffer())

func forward_udp_packet_to_all_clients(packet:Dictionary, sender:PacketPeerUDP) -> void:
	
	var packet_to_forward : Variant = JSON.stringify(packet)
	
	for client in connected_clients:
		
		if sender == client[&"peer"]: 
			pass
			continue
		
		client[&"peer"].put_packet(packet_to_forward.to_utf8_buffer())

func trigger_udp_server_command(command:String, info:Variant, 
peer:Variant, whole_packet:Variant)-> void:
	
	if command == "register":
		register_client(peer, assign_client_id())
	
	if command == "forward_to":
		forward_udp_packet_to_specific_client(whole_packet, info)
	
	if command == "forward_all":
		forward_udp_packet_to_all_clients(whole_packet, peer)









func poll_relay_server_tcp() -> void:
	
	if relay_server_tcp.is_connection_available():
		
		var tcp_client : Dictionary = {
			
			&"tcp_client": relay_server_tcp.take_connection(),
			&"tcp_data_buffer": PackedByteArray()
			
		}
		
		connected_tcp_clients.append(tcp_client)
		
		print("TCP Client Connected: ", tcp_client)
	
	if connected_tcp_clients.is_empty(): return
	
	for tcp_client in connected_tcp_clients:
		
		var client : Variant = tcp_client[&"tcp_client"]
		var data_buffer : Variant = tcp_client[&"tcp_data_buffer"]
		
		client.poll()
		
		var bytes : Variant = client.get_available_bytes()
		
		if bytes > 0:
			
			var data : Variant = client.get_data(bytes)[1]
			
			data_buffer.append_array(data)

func decode_tcp_stream() -> void:
	
	if connected_tcp_clients.is_empty(): return
	
	for tcp_client in connected_tcp_clients:
		
		var client : Variant = tcp_client[&"tcp_client"]
		var data_buffer : Variant = tcp_client[&"tcp_data_buffer"]
		
		while data_buffer.size() >= 4:
			
			var data_size : int = data_buffer.decode_u32(0)
			
			if data_buffer.size() < 4 + data_size:
				break
			
			var data : PackedByteArray = data_buffer.slice(4, 4 + data_size)
			var packet : Dictionary = JSON.parse_string(data.get_string_from_utf8())
			
			data_buffer = data_buffer.slice(4 + data_size)
			tcp_client[&"tcp_data_buffer"] = data_buffer
			
			trigger_tcp_server_command(packet[&"command"], packet[&"info"], client, packet)

func send_tcp_data_to_client(command:String, info:Variant, recipient:StreamPeerTCP) -> void:
	
	var packet : Dictionary = {
	&"command": command,
	&"info": info
	}
	
	var data := JSON.stringify(packet).to_utf8_buffer()
	
	recipient.put_u32(data.size())
	recipient.put_data(data)

func trigger_tcp_server_command(command:String, info:Variant, 
peer:Variant, whole_packet:Variant)-> void:
	
	pass








func register_client(peer:StreamPeerTCP, id:int) -> void:
	
	for registered_client in connected_clients:
		
		if peer == registered_client[&"peer"]:
			
			#send_packet_to_client("confirm_registration", null, registered_client[&"peer"])
			
			return
	
	var client_to_save : Dictionary = {
			&"peer": peer,
			&"id": id
		}
	
	connected_clients.append(client_to_save)
	
	#print(connected_clients)
	
	#send_packet_to_client("confirm_registration", null, peer)
	#send_packet_to_client("load_map", &"bnza_zoolag", peer)
	#send_packet_to_client("spawn", &"", peer)

func assign_client_id() -> int:
	
	next_client_id_to_assign = next_client_id_to_assign + 1
	
	return next_client_id_to_assign

#func unregister_client(client_to_disconnect:Variant) -> void:
	#
	#client_to_disconnect[&"peer"].close()
	#
	#connected_clients.erase(client_to_disconnect)

func spawn_synced(spawnable:String, spawn_position:Vector3) -> void:
	
	var command : String = "spawn"
	
	var info : Dictionary = {
		
		&"spawnable": spawnable,
		&"spawn_position": spawn_position
		
	}
	
	var packet : Dictionary = {&"command": command, &"info": info}
	
	forward_udp_packet_to_all_clients(packet, dedicated_server)

func despawn_synced() -> void:
	pass

func get_new_gamestate() -> void:
	
	pass
