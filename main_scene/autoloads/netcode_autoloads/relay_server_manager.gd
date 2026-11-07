extends Node

var relay_server_tcp : TCPServer
var relay_server_udp : UDPServer
var relay_server_ordered_udp : UDPServer

var relay_to_lobby_server_tcp : StreamPeerTCP
var tcp_data_buffer : PackedByteArray = PackedByteArray()
var relay_to_lobby_tcp_data_buffer : PackedByteArray = PackedByteArray()

var connected_clients : Array[Dictionary] = []
var relay_sessions : Array[Dictionary] = []
var next_session_id_to_assign : int = 0

func _ready() -> void:
	
	if not OS.has_feature(FeatureManager.DEDICATED_SERVER) \
	or not OS.has_feature(FeatureManager.RELAY_SERVER): 
		
		queue_free()
	
	if OS.has_feature(FeatureManager.RELAY_SERVER):
		
		create_relay()
		
	else: 
		
		queue_free()

func _process(_delta: float) -> void:
	
	poll_relay_to_client_manager_tcp()
	decode_client_tcp_stream()
	
	poll_relay_server_udp()
	poll_relay_server_ordered_udp()
	
	poll_relay_to_lobby_server_tcp()
	decode_lobby_tcp_stream()

func create_relay() -> void:
	
	relay_server_tcp = TCPServer.new()
	relay_server_tcp.listen(
		EndpointManager.RELAY_MANAGER_TCP_PORT, 
		EndpointManager.RELAY_REGIONS[&"NA"])
	print("Relay TCP Created")
	
	relay_server_udp = UDPServer.new()
	relay_server_udp.listen(
		EndpointManager.RELAY_MANAGER_UDP_PORT, 
		EndpointManager.RELAY_REGIONS[&"NA"])
	print("Relay UDP Created")
	
	relay_server_ordered_udp = UDPServer.new()
	relay_server_ordered_udp.listen(
		EndpointManager.RELAY_MANAGER_ORDERED_UDP_PORT, 
		EndpointManager.RELAY_REGIONS[&"NA"])
	print("Relay Ordered UDP Created")
	
	relay_to_lobby_server_tcp = StreamPeerTCP.new()
	relay_to_lobby_server_tcp.connect_to_host(
		EndpointManager.LOBBY_MANAGER_IPV4, 
		EndpointManager.LOBBY_MANAGER_TCP_PORT)
	print("Relay -> Lobby TCP Created")
	
	await get_tree().create_timer(1).timeout
	
	connect_to_lobby_server()

func connect_to_lobby_server() -> void:
	
	var relay_registration_info : Dictionary = {
		
		&"region": "US",
		&"key": SecretManager.TEST_KEY
		
	}
	
	send_tcp_data_to_lobby_server("register_official_relay_server", relay_registration_info)






func poll_relay_to_lobby_server_tcp() -> void:
	
	relay_to_lobby_server_tcp.poll()
	
	var lobby_server_bytes : Variant = relay_to_lobby_server_tcp.get_available_bytes()
	
	if lobby_server_bytes > 0:
		
		var data : Variant = relay_to_lobby_server_tcp.get_data(
		lobby_server_bytes)[1]
		
		#print(data)
		
		relay_to_lobby_tcp_data_buffer.append_array(data)

func decode_lobby_tcp_stream() -> void:
	
	if relay_to_lobby_tcp_data_buffer.is_empty(): return
	
	while relay_to_lobby_tcp_data_buffer.size() >= 4:
		
		var data_size : int = relay_to_lobby_tcp_data_buffer.decode_u32(0)
		
		if relay_to_lobby_tcp_data_buffer.size() < 4 + data_size:
			break
		
		var data : PackedByteArray = relay_to_lobby_tcp_data_buffer.slice(4, 4 + data_size)
		var packet : Variant = JSON.parse_string(data.get_string_from_utf8())
		
		relay_to_lobby_tcp_data_buffer = relay_to_lobby_tcp_data_buffer.slice(4 + data_size)
		
		#print(packet)
		
		trigger_lobby_tcp_command(packet[&"command"], packet[&"info"])

func send_tcp_data_to_lobby_server(command:String, info:Variant) -> void:
	
	var packet : Dictionary = {
	&"command": command,
	&"info": info
	}
	
	var data := JSON.stringify(packet).to_utf8_buffer()
	
	relay_to_lobby_server_tcp.put_u32(data.size())
	relay_to_lobby_server_tcp.put_data(data)

func trigger_lobby_tcp_command(command:String, info:Variant) -> void:
	
	if command == "start_relay_session":
		create_relay_session_instance(info)
	
	if command == "join_relay_session":
		join_relay_session(info)






func poll_relay_to_client_manager_tcp() -> void:
	
	# Register new clients
	if relay_server_tcp.is_connection_available():
		
		var client : Dictionary = {
			
			&"client_id": -1,
			&"ip_address": 0,
			&"tcp_peer": relay_server_tcp.take_connection(),
			&"tcp_data_buffer": PackedByteArray(),
			&"udp_peer": null,
			&"ordered_udp_peer": null,
			&"last_client_sequence_number": 0,
			&"current_session": 0,
			&"is_host": false
			
		}
		
		var peer : Variant = client[&"tcp_peer"]
		
		client[&"ip_address"] = peer.get_connected_host()
		
		connected_clients.append(client)
		
		send_tcp_data_to_client("confirm_relay_server_tcp_registration", 
		EndpointManager.RELAY_REGIONS[&"NA"], peer)
		
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

func decode_client_tcp_stream() -> void:
	
	if connected_clients.is_empty(): return
	
	for tcp_client in connected_clients:
		
		var peer : Variant = tcp_client[&"tcp_peer"]
		var data_buffer : Variant = tcp_client[&"tcp_data_buffer"]
		var current_session : Variant = tcp_client[&"current_session"]
		var is_host : Variant = tcp_client[&"is_host"]
		
		while data_buffer.size() >= 4:
			
			var data_size : int = data_buffer.decode_u32(0)
			
			if data_buffer.size() < 4 + data_size:
				break
			
			var data : PackedByteArray = data_buffer.slice(4, 4 + data_size)
			var packet : Dictionary = JSON.parse_string(data.get_string_from_utf8())
			
			#print(packet)
			
			data_buffer = data_buffer.slice(4 + data_size)
			tcp_client[&"tcp_data_buffer"] = data_buffer
			
			var command : String = packet[&"command"]
			var info : Variant = packet[&"info"]
			
			# Set the relay's ID for this client, if applicable
			if command == "set_client_id":
				
				for client in connected_clients:
					
					if client[&"tcp_peer"] == peer:
						
						client[&"client_id"] = int(info)
						
						print("Relay Server Applied Client ID: ", \
						client[&"client_id"])
			
			# Host forward logic (Host -> All Clients)
			if is_host == true:
				
				for session in relay_sessions:
					
					if current_session == session[&"session_id"]:
						
						var client_ids : Array[int] = get_client_ids_from_session_id(current_session, false)
						
						for client_id in client_ids:
							
							send_tcp_data_to_client(command, info, get_tcp_peer_from_client_id(client_id))
			
			# Client forwarding logic (All Clients -> Host)
			if is_host == false:
				
				for session in relay_sessions:
					
					if current_session == session[&"session_id"]:
						
						var host_id : int = get_host_id_from_session_id(current_session)
						
						var host_peer : StreamPeerTCP = get_tcp_peer_from_client_id(host_id)
						
						send_tcp_data_to_client(command, info, host_peer)

func get_tcp_peer_from_client_id(client_id:int) -> StreamPeerTCP:
	
	for client in connected_clients:
		
		if client[&"client_id"] == client_id:
			return client[&"tcp_peer"]
		
	return null

func send_tcp_data_to_client(command:String, info:Variant, recipient:StreamPeerTCP) -> void:
	
	var packet : Dictionary = {
	&"command": command,
	&"info": info
	}
	
	var data := JSON.stringify(packet).to_utf8_buffer()
	
	recipient.put_u32(data.size())
	recipient.put_data(data)







func get_client_ids_from_session_id(session_id:int, include_host:bool) -> Array[int]:
	
	var client_ids: Array[int] = []
	
	for client in connected_clients:
		
		if client[&"current_session"] != session_id:
			continue
		
		if include_host == false \
		and client[&"is_host"]:
			continue
		
		client_ids.append(client[&"client_id"])
		
	return client_ids

func get_host_id_from_session_id(session_id:int) -> int:
	
	for session in relay_sessions:
		
		if session[&"session_id"] == session_id:
			
			return session[&"host"]
	
	return 0







func poll_relay_server_udp() -> void:
	
	relay_server_udp.poll()
	
	# Poll for new UDP connections
	if relay_server_udp.is_connection_available():
		
		var peer : Variant = relay_server_udp.take_connection()
		var packet : Variant = peer.get_packet().get_string_from_utf8()
		
		#print("Server Received Packet: ", packet)
		
		var json_translation : Variant = JSON.new()
		json_translation = JSON.parse_string(packet)
		packet = json_translation
		
		var command : String = json_translation[&"command"]
		var info : Variant = json_translation[&"info"]
		
		if command == "register_to_relay_server_udp":
			
			for client in connected_clients:
				
				if client[&"client_id"] == info:
					
					client[&"udp_peer"] = peer
					
					send_tcp_data_to_client("confirm_relay_server_udp_registration", 
					null, client[&"tcp_peer"])
					
					print("Registered UDP peer for client: ", client[&"client_id"])
					print("UDP peer: ", client[&"udp_peer"])
	
	# Poll connected clients
	for client in connected_clients:
		
		if client[&"udp_peer"] == null: 
			continue
		
		while client[&"udp_peer"].get_available_packet_count() > 0:
			
			if client[&"udp_peer"] == null:
				continue
			
			var packet : Variant = client[&"udp_peer"].get_packet().get_string_from_utf8()
			var current_session : Variant = client[&"current_session"]
			var is_host : Variant = client[&"is_host"]
			
			#print("Server Received Packet: ", packet)
			
			var json_translation : Variant = JSON.new()
			json_translation = JSON.parse_string(packet)
			packet = json_translation
			
			var command : String = json_translation[&"command"]
			var info : Variant = json_translation[&"info"]
			
			#print("Server Received Packet: ", packet)
			
			# Host forward logic (Host -> All Clients)
			if is_host == true:
				
				for session in relay_sessions:
					
					if current_session == session[&"session_id"]:
						
						var client_ids : Array[int] = get_client_ids_from_session_id(current_session, false)
						
						for client_id in client_ids:
							
							send_udp_packet_to_client(command, info, get_udp_peer_from_client_id(client_id))
			
			# Client forwarding logic (All Clients -> Host)
			if is_host == false:
				
				for session in relay_sessions:
					
					if current_session == session[&"session_id"]:
						
						var host_id : int = get_host_id_from_session_id(current_session)
						
						var host_peer : PacketPeerUDP = get_udp_peer_from_client_id(host_id)
						
						send_udp_packet_to_client(command, info, host_peer)

func get_udp_peer_from_client_id(client_id:int) -> PacketPeerUDP:
	
	for client in connected_clients:
		
		if client[&"client_id"] == client_id:
			return client[&"udp_peer"]
		
	return null

func send_udp_packet_to_client(command:String, info:Variant, recipient:PacketPeerUDP) -> void:
	
	var packet : Dictionary = {}
	
	packet = {&"command": command, &"info": info}
	
	var packet_to_send : Variant = JSON.stringify(packet)
	
	recipient.put_packet(packet_to_send.to_utf8_buffer())










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
		
		if command == "register_to_relay_server_ordered_udp":
			
			for client in connected_clients:
				
				if client[&"client_id"] == info:
					
					client[&"ordered_udp_peer"] = peer
					
					send_tcp_data_to_client("confirm_relay_server_ordered_udp_registration", 
					null, client[&"tcp_peer"])
					
					print("Registered Orered UDP peer for client: ", client[&"client_id"])
					print("UDP peer: ", client[&"ordered_udp_peer"])
	
	for client in connected_clients:
		
		if client[&"ordered_udp_peer"] == null: 
			continue
		
		while client[&"ordered_udp_peer"].get_available_packet_count() > 0:
			
			var packet : Variant = client[&"ordered_udp_peer"].get_packet().get_string_from_utf8()
			
			#print("Server Received Ordered Packet: ", packet)
			
			var json_translation : Variant = JSON.new()
			json_translation = JSON.parse_string(packet)
			packet = json_translation
			
			var command : String = json_translation[&"command"]
			var info : Variant = json_translation[&"info"]
			var current_session : Variant = client[&"current_session"]
			var is_host : Variant = client[&"is_host"]
			var packet_sequence_number : int = json_translation[&"sequence_number"]
			var last_sequence_number : int = client[&"last_client_sequence_number"]
			
			#print("Server Received Ordered Packet: ", packet)
			
			client[&"last_client_sequence_number"] = packet_sequence_number
			
			# Host forward logic (Host -> All Clients)
			if is_host == true:
				
				for session in relay_sessions:
					
					if current_session == session[&"session_id"]:
						
						var client_ids : Array[int] = get_client_ids_from_session_id(current_session, false)
						
						for client_id in client_ids:
							
							send_ordered_udp_packet_to_client(command, info, \
							get_ordered_udp_peer_from_client_id(client_id), \
							packet_sequence_number, last_sequence_number)
			
			# Client forwarding logic (All Clients -> Host)
			if is_host == false:
				
				for session in relay_sessions:
					
					if current_session == session[&"session_id"]:
						
						var host_id : int = get_host_id_from_session_id(current_session)
						
						var host_peer : PacketPeerUDP = get_ordered_udp_peer_from_client_id(host_id)
						
						send_ordered_udp_packet_to_client(command, info, \
						host_peer, \
						packet_sequence_number, last_sequence_number)

func get_ordered_udp_peer_from_client_id(client_id:int) -> PacketPeerUDP:
	
	for client in connected_clients:
		
		if client[&"client_id"] == client_id:
			return client[&"ordered_udp_peer"]
		
	return null

func send_ordered_udp_packet_to_client(command:String, info:Variant, 
recipient:PacketPeerUDP, sequence_number:int, last_sequence_number:int) -> void:
	
	var packet : Dictionary = {
		
		&"command": command, 
		&"info": info,
		&"sequence_number": sequence_number,
		&"last_sequence_number": last_sequence_number
	}
	
	var packet_to_send : Variant = JSON.stringify(packet)
	
	recipient.put_packet(packet_to_send.to_utf8_buffer())









func create_relay_session_instance(info:Variant) -> void:
	
	var new_relay_session : Dictionary = {
		
		&"session_id": info[&"lobby_id"],
		&"host": info[&"client_id"],
		&"peers": [info[&"client_id"]]
	}
	
	for client in connected_clients:
		
		if client[&"client_id"] == info[&"client_id"]:
			
			client[&"current_session"] = new_relay_session[&"session_id"]
			
			client[&"is_host"] = true
			
			# Start host game client-side
			send_tcp_data_to_client("load_map", "bnza_zoolag", client[&"tcp_peer"])
			send_tcp_data_to_client("spawn_own_player", 
			{&"x": 0, &"y": 0, &"z": 0}, 
			client[&"tcp_peer"])
			
		else: continue
	
	relay_sessions.append(new_relay_session)
	
	print("Relay Session Started")

func assign_session_id() -> int:
	
	next_session_id_to_assign = \
	next_session_id_to_assign + 1
	
	return next_session_id_to_assign

func join_relay_session(info:Variant) -> void:
	
	# Client joins session
	for session in relay_sessions:
		
		if session[&"session_id"] == info[&"lobby_id"]:
			
			session[&"peers"].append(info[&"client_id"])
			
			# Update client info
			for client in connected_clients:
			
				if client[&"client_id"] == info[&"client_id"]:
					
					client[&"current_session"] = session[&"session_id"]
					
					client[&"is_host"] = false
					
					var peer : StreamPeerTCP = client[&"tcp_peer"]
					var id : int = client[&"client_id"]
					
					send_tcp_data_to_client("new_player_joined", id, peer)
					
					send_tcp_data_to_client("spawn_own_player", 
					{&"x": 0, &"y": 0, &"z": 0} , 
					peer)
					
					#TODO While existing clients get new spawns, new clients-
					# don't get old spawns. Build a client_id array that sends to new clients.
					
					# Send info to all other clients
					for session_peer:Variant in \
					get_client_ids_from_session_id(session[&"session_id"], true):
						
						if session_peer == id: continue
						
						send_tcp_data_to_client("new_player_joined", session_peer, 
						get_tcp_peer_from_client_id(session_peer))
					
				else: continue
			
			#print(session[&"peers"])
			print("Client Joined Relay Session: ", session[&"session_id"])
			
		else: continue
