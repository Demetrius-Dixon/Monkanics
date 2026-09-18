extends Node

var relay_server_udp : UDPServer
var connected_udp_clients : Array[Dictionary] = []

var relay_server_ordered_udp : UDPServer
var connected_ordered_udp_clients : Array[Dictionary] = []

var relay_server_tcp : TCPServer
var connected_tcp_clients : Array[Dictionary] = []

var dedicated_server : PacketPeerUDP



func _ready() -> void:
	
	if not OS.has_feature("dedicated_server"): 
		queue_free()
	else: 
		create_relay_servers()
		#LobbyManager.create_lobby(dedicated_server)

func _process(_delta: float) -> void:
	
	poll_relay_server_udp()
	
	poll_relay_server_ordered_udp()
	
	poll_relay_server_tcp()
	decode_tcp_stream()

func create_relay_servers() -> void:
	
	relay_server_udp = UDPServer.new()
	relay_server_udp.listen(EndpointManager.RELAY_UDP_PORT, EndpointManager.RELAY_NORTH_AMERICA_IPV4)
	print("Relay UDP Created")
	
	relay_server_ordered_udp = UDPServer.new()
	relay_server_ordered_udp.listen(EndpointManager.RELAY_ORDERED_UDP_PORT, EndpointManager.RELAY_NORTH_AMERICA_IPV4)
	print("Relay Ordered UDP Created")
	
	relay_server_tcp = TCPServer.new()
	relay_server_tcp.listen(EndpointManager.RELAY_TCP_PORT, EndpointManager.RELAY_NORTH_AMERICA_IPV4)
	print("Relay TCP Created")




func poll_relay_server_udp() -> void:
	
	relay_server_udp.poll()
	
	if relay_server_udp.is_connection_available():
		
		var peer : Variant = relay_server_udp.take_connection()
		var packet : Variant = peer.get_packet().get_string_from_utf8()
		
		for registered_client in connected_udp_clients:
			
			if peer == registered_client[&"peer"]:
				return
		
		#print("Server Received Packet: ", packet)
		
		var json_translation : Variant = JSON.new()
		json_translation = JSON.parse_string(packet)
		packet = json_translation
		
		var command : String = json_translation[&"command"]
		var info : Variant = json_translation[&"info"]
		
		trigger_udp_server_command(command, info, peer, packet)
	
	for client in connected_udp_clients:
		
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
	
	for client in connected_udp_clients:
		
		if sender == client[&"peer"]: 
			pass
			continue
		
		client[&"peer"].put_packet(packet_to_forward.to_utf8_buffer())

func register_udp_client(peer:PacketPeerUDP) -> void:
	
	for registered_client in connected_udp_clients:
		
		if peer == registered_client[&"peer"]:
			
			send_udp_packet_to_client("confirm_udp_registration", null, registered_client[&"peer"])
			
			return
	
	var client_to_save : Dictionary = {&"peer": peer}
	
	connected_udp_clients.append(client_to_save)

func trigger_udp_server_command(command:String, info:Variant, 
peer:Variant, whole_packet:Variant)-> void:
	
	if command == "register_to_udp":
		register_udp_client(peer)
	
	if command == "forward_udp_to":
		forward_udp_packet_to_specific_client(whole_packet, info)
	
	if command == "forward_udp_to_all":
		forward_udp_packet_to_all_clients(whole_packet, peer)





func poll_relay_server_ordered_udp() -> void:
	
	relay_server_ordered_udp.poll()
	
	if relay_server_ordered_udp.is_connection_available():
		
		var peer : Variant = relay_server_ordered_udp.take_connection()
		var packet : Variant = peer.get_packet().get_string_from_utf8()
		
		for registered_client in connected_ordered_udp_clients:
			
			if peer == registered_client[&"peer"]:
				return
		
		#print("Server Received Packet: ", packet)
		
		var json_translation : Variant = JSON.new()
		json_translation = JSON.parse_string(packet)
		packet = json_translation
		
		var command : String = json_translation[&"command"]
		var info : Variant = json_translation[&"info"]
		
		print("Server Received Packet: ", packet)
		
		trigger_ordered_udp_server_command(command, info, peer, packet)
	
	for client in connected_ordered_udp_clients:
		
		if client[&"peer"].get_available_packet_count() > 0:
			
			var peer : PacketPeerUDP = client[&"peer"]
			var packet : Variant = client[&"peer"].get_packet().get_string_from_utf8()
			
			#print("Server Received Packet: ", packet)
			
			var json_translation : Variant = JSON.new()
			json_translation = JSON.parse_string(packet)
			packet = json_translation
			
			var command : String = json_translation[&"command"]
			var info : Variant = json_translation[&"info"]
			var packet_sequence_number : int = json_translation[&"sequence_number"]
			var expected_sequence_number : int = client[&"last_sequence_number"]
			
			print("Server Received Packet: ", packet)
			
			var sequence_difference : int = \
			packet_sequence_number - expected_sequence_number
			
			if sequence_difference <= 0:
				
				continue
				
			else:
				
				trigger_ordered_udp_server_command(command, info, peer, packet)
				
				client[&"last_sequence_number"] = packet_sequence_number
				
				send_ordered_udp_packet_to_client("Test_Client", null, peer)

func send_ordered_udp_packet_to_client(command:String, info:Variant, recipient:PacketPeerUDP) -> void:
	
	var sequence_number : int
	
	for client in connected_ordered_udp_clients:
		
		if client[&"peer"] == recipient:
			
			client[&"server_packet_sequence_number"] = \
			client[&"server_packet_sequence_number"] + 1
			
			sequence_number = client[&"server_packet_sequence_number"]
	
	var packet : Dictionary = {}
	
	packet = {&"command": command, 
	&"info": info,
	&"sequence_number": sequence_number
	}
	
	var packet_to_send : Variant = JSON.stringify(packet)
	
	recipient.put_packet(packet_to_send.to_utf8_buffer())

#TODO Forwarding functions for ordered UDP

func register_ordered_udp_client(peer:PacketPeerUDP) -> void:
	
	for registered_client in connected_ordered_udp_clients:
		
		if peer == registered_client[&"peer"]:
			
			send_ordered_udp_packet_to_client("confirm_ordered_udp_registration", null, peer)
			
			return
	
	var client_to_save : Dictionary = {
		&"peer": peer,
		&"last_sequence_number": 0,
		&"server_packet_sequence_number": 0
	}
	
	connected_ordered_udp_clients.append(client_to_save)
	
	print(connected_ordered_udp_clients)

func trigger_ordered_udp_server_command(command:String, info:Variant, 
peer:Variant, whole_packet:Variant)-> void:
	
	if command == "register_to_ordered_udp":
		register_ordered_udp_client(peer)







func poll_relay_server_tcp() -> void:
	
	if relay_server_tcp.is_connection_available():
		
		var tcp_client : Dictionary = {
			
			&"tcp_client": relay_server_tcp.take_connection(),
			&"tcp_data_buffer": PackedByteArray()
			
		}
		
		connected_tcp_clients.append(tcp_client)
		
		#print("TCP Client Connected: ", tcp_client)
	
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

#TODO Forwarding functions for TCP

func trigger_tcp_server_command(command:String, info:Variant, 
peer:Variant, whole_packet:Variant)-> void:
	
	pass









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
