extends Node

var main_server : TCPServer
var connected_clients : Array[Dictionary] = []
var next_client_game_id_to_assign : int = 0

var relay_server_udp : UDPServer
var relay_server_ordered_udp : UDPServer

var active_lobbies : Array[Dictionary] = []
var next_lobby_id_to_assign : int = 0

func _ready() -> void:
	
	if not OS.has_feature("dedicated_server"): 
		queue_free()
	else: 
		create_server()

func _process(_delta: float) -> void:
	
	poll_main_server()
	decode_tcp_stream()
	
	poll_relay_server_udp()
	poll_relay_server_ordered_udp()

func create_server() -> void:
	
	main_server = TCPServer.new()
	main_server.listen(EndpointManager.RELAY_TCP_PORT, EndpointManager.RELAY_NORTH_AMERICA_IPV4)
	print("Relay TCP Created")
	
	relay_server_udp = UDPServer.new()
	relay_server_udp.listen(EndpointManager.RELAY_UDP_PORT, EndpointManager.RELAY_NORTH_AMERICA_IPV4)
	print("Relay UDP Created")
	
	relay_server_ordered_udp = UDPServer.new()
	relay_server_ordered_udp.listen(EndpointManager.RELAY_ORDERED_UDP_PORT, EndpointManager.RELAY_NORTH_AMERICA_IPV4)
	print("Relay Ordered UDP Created")




func poll_main_server() -> void:
	
	# Register new clients
	if main_server.is_connection_available():
		
		var client : Dictionary = {
			
			&"username": "",
			&"tcp_peer": main_server.take_connection(),
			&"udp_peer": null,
			&"udp_ordered_peer": null,
			&"tcp_data_buffer": PackedByteArray(),
			&"ip_address": 0,
			&"game_id": assign_client_game_id(),
			
		}
		
		var peer : Variant = client[&"tcp_peer"]
		
		client[&"ip_address"] = peer.get_connected_host()
		
		connected_clients.append(client)
		
		send_tcp_data_to_client("confirm_tcp_registration", client[&"game_id"], peer)
		
		#print("TCP Client Connected: ", client)
	
	if connected_clients.is_empty(): return
	
	# Set up erasure array (For loops cannot iterate while looping)
	var clients_to_erase : Array = []
	
	# Poll current clients
	for client in connected_clients:
		
		if client[&"tcp_peer"] == null: 
			continue
		
		var tcp_client : Variant = client[&"tcp_peer"]
		var data_buffer : Variant = client[&"tcp_data_buffer"]
		
		tcp_client.poll()
		
		if client[&"tcp_peer"].get_status() != \
		StreamPeerTCP.STATUS_CONNECTED:
			
			clients_to_erase.append(client)
			
			continue
		
		var bytes : Variant = tcp_client.get_available_bytes()
		
		if bytes > 0:
			
			var data : Variant = tcp_client.get_data(bytes)[1]
			
			data_buffer.append_array(data)
	
	# Remove disconnected clients
	if not clients_to_erase.is_empty():
		
		for client:Variant in clients_to_erase:
			
			connected_clients.erase(client)
		
		clients_to_erase.clear()

func decode_tcp_stream() -> void:
	
	if connected_clients.is_empty(): return
	
	for tcp_client in connected_clients:
		
		var client : Variant = tcp_client[&"tcp_peer"]
		var data_buffer : Variant = tcp_client[&"tcp_data_buffer"]
		
		while data_buffer.size() >= 4:
			
			var data_size : int = data_buffer.decode_u32(0)
			
			if data_buffer.size() < 4 + data_size:
				break
			
			var data : PackedByteArray = data_buffer.slice(4, 4 + data_size)
			var packet : Dictionary = JSON.parse_string(data.get_string_from_utf8())
			
			#print(packet)
			
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

func forward_tcp_data_to_specific_client(data:Variant, recipient:StreamPeerTCP) -> void:
	
	var command : String = data[&"command"]
	var info : Dictionary = data[&"info"]
	
	send_tcp_data_to_client(command, info, recipient)

func forward_tcp_data_to_all_clients(data:Variant, sender:StreamPeerTCP) -> void:
	
	var command : String = data[&"command"]
	var info : Dictionary = data[&"info"]
	
	for client in connected_clients:
		
		if sender == client[&"peer"]: 
			pass
			continue
		
		send_tcp_data_to_client(command, info, client[&"peer"])

func assign_client_game_id() -> int:
	
	next_client_game_id_to_assign = \
	next_client_game_id_to_assign + 1
	
	return next_client_game_id_to_assign

func trigger_tcp_server_command(command:String, info:Variant, 
peer:Variant, all_data:Variant)-> void:
	
	if command == "forward_tcp_to":
		forward_tcp_data_to_specific_client(all_data, info)
	
	if command == "forward_tcp_to_all":
		forward_tcp_data_to_all_clients(all_data, peer)
	
	if command == "create_lobby":
		create_lobby_instance(peer, info)
	
	if command == "request_to_join_lobby":
		
		var id_to_get : int
		
		for client in connected_clients:
			
			if peer == client[&"tcp_peer"]:
				
				id_to_get = client[&"game_id"]
		
		client_join_lobby(peer, id_to_get, info)
	
	if command == "request_active_lobby":
		
		if active_lobbies.is_empty(): return
		
		for lobby in active_lobbies:
			
			send_tcp_data_to_client("receive_active_lobby", lobby, peer)







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
		
		for client in connected_clients:
			
			if client[&"udp_peer"] == peer:
				
				send_tcp_data_to_client("confirm_udp_registration", null, client[&"tcp_peer"])
				
				return
			
			if info == client[&"game_id"] \
			and command == "register_to_udp":
				
				client[&"udp_peer"] = peer
				
				send_tcp_data_to_client("confirm_udp_registration", null, client[&"tcp_peer"])
	
	for client in connected_clients:
		
		if client[&"udp_peer"] == null: continue
		
		if client[&"udp_peer"].get_available_packet_count() > 0:
			
			var peer : PacketPeerUDP = client[&"udp_peer"]
			var packet : Variant = client[&"udp_peer"].get_packet().get_string_from_utf8()
			
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
		
		if sender == client[&"udp_peer"]: 
			pass
			continue
		
		client[&"udp_peer"].put_packet(packet_to_forward.to_utf8_buffer())

func trigger_udp_server_command(command:String, info:Variant, 
peer:Variant, whole_packet:Variant)-> void:
	
	if command == "forward_udp_to":
		forward_udp_packet_to_specific_client(whole_packet, info)
	
	if command == "forward_udp_to_all":
		forward_udp_packet_to_all_clients(whole_packet, peer)







func poll_relay_server_ordered_udp() -> void:
	
	relay_server_ordered_udp.poll()
	
	if relay_server_ordered_udp.is_connection_available():
		
		var peer : Variant = relay_server_ordered_udp.take_connection()
		var packet : Variant = peer.get_packet().get_string_from_utf8()
		
		#print("Server Received Ordered Packet: ", packet)
		
		var json_translation : Variant = JSON.new()
		json_translation = JSON.parse_string(packet)
		packet = json_translation
		
		var command : String = json_translation[&"command"]
		var info : Variant = json_translation[&"info"]
		
		#print("Server Received Ordered Packet: ", packet)
		
		for client in connected_clients:
			
			if client[&"udp_ordered_peer"] == peer:
				
				send_tcp_data_to_client("confirm_ordered_udp_registration", null, client[&"tcp_peer"])
				
				return
			
			if info == client[&"game_id"] \
			and command == "register_to_ordered_udp":
				
				client[&"udp_ordered_peer"] = peer
				
				send_tcp_data_to_client("confirm_ordered_udp_registration", null, client[&"tcp_peer"])
	
	for client in connected_clients:
		
		if client[&"udp_ordered_peer"] == null: continue
		
		if client[&"udp_ordered_peer"].get_available_packet_count() > 0:
			
			var peer : PacketPeerUDP = client[&"udp_ordered_peer"]
			var packet : Variant = client[&"udp_ordered_peer"].get_packet().get_string_from_utf8()
			
			#print("Server Received Ordered Packet: ", packet)
			
			var json_translation : Variant = JSON.new()
			json_translation = JSON.parse_string(packet)
			packet = json_translation
			
			var command : String = json_translation[&"command"]
			var info : Variant = json_translation[&"info"]
			var packet_sequence_number : int = json_translation[&"sequence_number"]
			var expected_sequence_number : int = client[&"last_sequence_number"]
			
			#print("Server Received Ordered Packet: ", packet)
			
			var sequence_difference : int = \
			packet_sequence_number - expected_sequence_number
			
			if sequence_difference <= 0:
				
				continue
				
			else:
				
				trigger_ordered_udp_server_command(command, info, peer, packet)
				
				client[&"last_sequence_number"] = packet_sequence_number

func send_ordered_udp_packet_to_client(command:String, info:Variant, recipient:PacketPeerUDP) -> void:
	
	var sequence_number : int
	
	for client in connected_clients:
		
		if client[&"udp_ordered_peer"] == recipient:
			
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

func forward_ordered_udp_packet_to_specific_client(packet:Dictionary, recipient:PacketPeerUDP) -> void:
	
	var packet_to_forward : Variant = JSON.stringify(packet)
	
	recipient.put_packet(packet_to_forward.to_utf8_buffer())

func forward_ordered_udp_packet_to_all_clients(packet:Dictionary, sender:PacketPeerUDP) -> void:
	
	var packet_to_forward : Variant = JSON.stringify(packet)
	
	for client in connected_clients:
		
		if sender == client[&"udp_ordered_peer"]: 
			pass
			continue
		
		client[&"udp_ordered_peer"].put_packet(packet_to_forward.to_utf8_buffer())

func trigger_ordered_udp_server_command(command:String, info:Variant, 
peer:Variant, whole_packet:Variant)-> void:
	
	if command == "forward_ordered_udp_to":
		forward_ordered_udp_packet_to_specific_client(whole_packet, info)
	
	if command == "forward_ordered_udp_to_all":
		forward_ordered_udp_packet_to_all_clients(whole_packet, peer)










func send_game_data_to_all_players() -> void:
	pass
	
	

func create_lobby_instance(host:StreamPeerTCP, lobby_name:String) -> void:
	
	active_lobbies.append({
		
		&"lobby_id": assign_lobby_id(),
		&"lobby_name": lobby_name,
		&"host": host,
		&"game_mode": "Bean-anza",
		&"map": "bnza_zoolag",
		#&"current_player_count": 0,
		#&"max_players": 6,
		&"players": [host]
		
	})
	
	send_tcp_data_to_client("load_map", "bnza_zoolag", host)
	send_tcp_data_to_client("spawn_own_player", 
	{&"x": 0, &"y": 0, &"z": 0}, 
	host)
	
	#print("Lobbies on Server: ", active_lobbies)
	#print("Lobby Created")

func assign_lobby_id() -> int:
	
	next_lobby_id_to_assign = \
	next_lobby_id_to_assign + 1
	
	return next_lobby_id_to_assign

func client_join_lobby(client:StreamPeerTCP, client_id:int, lobby_id:int) -> void:
	
	if active_lobbies.is_empty(): return
	
	for lobby in active_lobbies:
		
		if lobby[&"lobby_id"] == lobby_id:
			
			lobby[&"players"].append(client)
			
			#print(lobby[&"players"])
			#print("New Client Joined Lobby: ", client)
			
			var lobby_data : Dictionary = {
				
				&"host": lobby[&"host"],
				&"game_mode": lobby[&"game_mode"],
				&"map": lobby[&"map"],
				&"players": lobby[&"players"]
				
			}
			
			# Info to send to joining client
			send_tcp_data_to_client("join_lobby", lobby_data, client)
			
			send_tcp_data_to_client("spawn_own_player", 
			{&"x": 0, &"y": 0, &"z": 0} , 
			client)
			
			for client_in_lobby:Variant in lobby[&"players"]:
				
				if client_in_lobby == client: continue
				
				send_tcp_data_to_client("new_player_joined", client_id, client)
			
			# info to send to current host
			send_tcp_data_to_client("new_player_joined", client_id, lobby[&"host"])
			
			# Send info to all other clients
			for client_in_lobby:Variant in lobby[&"players"]:
				
				if client_in_lobby == client: continue
				
				if client_in_lobby == lobby[&"host"]: continue
				
				send_tcp_data_to_client("new_player_joined", client_id, client_in_lobby)

func assign_host_in_lobby() -> void:
	pass
	
