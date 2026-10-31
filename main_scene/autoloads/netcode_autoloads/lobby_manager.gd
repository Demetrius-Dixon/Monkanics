extends Node

var lobby_manager_tpc : TCPServer

var registered_relay_servers : Array[Dictionary] = []

var connected_clients : Array[Dictionary] = []
var next_client_client_id_to_assign : int = 0

var active_lobbies : Array[Dictionary] = []
var next_lobby_id_to_assign : int = 0

func _ready() -> void:
	
	if not OS.has_feature(FeatureManager.DEDICATED_SERVER) \
	or not OS.has_feature(FeatureManager.LOBBY_SERVER): 
		
		queue_free()
	
	if OS.has_feature(FeatureManager.LOBBY_SERVER):
		
		create_lobby_manager()
		
	else: 
		
		queue_free()

func _process(_delta: float) -> void:
	
	poll_lobby_manager_tpc()
	decode_tcp_stream()

func create_lobby_manager() -> void:
	
	lobby_manager_tpc = TCPServer.new()
	lobby_manager_tpc.listen(
		EndpointManager.LOBBY_MANAGER_TCP_PORT, 
		EndpointManager.LOBBY_MANAGER_IPV4)
	print("Lobby Manager TCP Created")







func poll_lobby_manager_tpc() -> void:
	
	# Register new clients
	if lobby_manager_tpc.is_connection_available():
		
		var client : Dictionary = {
			
			&"client_id": assign_client_client_id(),
			&"ip_address": 0,
			&"tcp_peer": lobby_manager_tpc.take_connection(),
			&"tcp_data_buffer": PackedByteArray(),
			&"current_lobby": null,
			&"is_host": null,
			
		}
		
		var peer : Variant = client[&"tcp_peer"]
		
		client[&"ip_address"] = peer.get_connected_host()
		
		connected_clients.append(client)
		
		send_tcp_data_to_client("confirm_lobby_manager_tcp_registration", client[&"client_id"], peer)
		
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
		
		# Check if the client is connected
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
		var current_lobby : Variant = tcp_client[&"current_lobby"]
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
			
			trigger_tcp_server_command(packet[&"command"], packet[&"info"], 
			client, packet, current_lobby, is_host)

func send_tcp_data_to_client(command:String, info:Variant, recipient:StreamPeerTCP) -> void:
	
	var packet : Dictionary = {
	&"command": command,
	&"info": info
	}
	
	var data := JSON.stringify(packet).to_utf8_buffer()
	
	recipient.put_u32(data.size())
	recipient.put_data(data)

func assign_client_client_id() -> int:
	
	next_client_client_id_to_assign = \
	next_client_client_id_to_assign + 1
	
	return next_client_client_id_to_assign

@warning_ignore("unused_parameter")
func trigger_tcp_server_command(command:String, info:Variant, 
peer:Variant, all_data:Variant, current_lobby:Variant, is_host:Variant)-> void:
	
	if command == "register_official_relay_server":
		
		var region_to_register : String = info[&"region"]
		var sent_key : Variant = info[&"key"]
		
		#print(region_to_register)
		#print(sent_key)
		
		if sent_key == SecretManager.TEST_KEY:
			
			# Check if the region is already registered
			for relay in registered_relay_servers:
				
				if region_to_register == relay[&"region"]: 
					
					return
			
			registered_relay_servers.append({
			
			&"relay_peer": peer,
			&"region": "US",
			&"relay_ip": peer.get_connected_host()
			})
			
			print(region_to_register, " Relay Registered")
	
	if command == "create_lobby":
		create_lobby_instance(peer, info)
	
	if command == "request_to_join_lobby":
		
		var id_to_get : int
		
		for client in connected_clients:
			
			if peer == client[&"tcp_peer"]:
				
				id_to_get = client[&"client_id"]
		
		client_join_lobby(peer, id_to_get, info)
	
	if command == "request_active_lobby":
		
		if active_lobbies.is_empty(): return
		
		for lobby in active_lobbies:
			
			send_tcp_data_to_client("receive_active_lobby", lobby, peer)











func create_lobby_instance(host:StreamPeerTCP, lobby_name:String) -> void:
	
	var new_lobby_id : int = assign_lobby_id()
	
	active_lobbies.append({
		
		&"lobby_id": new_lobby_id,
		&"lobby_name": lobby_name,
		&"host": host,
		&"game_mode": "Bean-anza",
		&"map": "bnza_zoolag",
		#&"current_player_count": 0,
		#&"max_players": 6,
		&"players": [host],
		&"relay": EndpointManager.relay_regions[&"NA"]
		
	})
	
	var client_id : int
	
	# Assign the hosts current lobby
	for client in connected_clients:
		
		if host == client[&"tcp_peer"]:
			
			client[&"current_lobby"] = new_lobby_id
			
			client[&"is_host"] = true
			
			client_id = client[&"client_id"]
			
			#print(client[&"current_lobby"])
	
	# Connect host to the relay
	send_tcp_data_to_client("client_connect_to_relay", 
	EndpointManager.relay_regions[&"NA"], host)
	
	await get_tree().create_timer(2).timeout
	
	# Create relay connection session
	for relay in registered_relay_servers:
		
		if relay[&"relay_ip"] == EndpointManager.relay_regions[&"NA"]:
			
			var info_to_send : Dictionary = {
				&"lobby_id": new_lobby_id,
				&"client_id": client_id}
			
			send_tcp_data_to_client("start_relay_session", info_to_send, relay[&"relay_peer"])
	
	# Start host game locally
	send_tcp_data_to_client("load_map", "bnza_zoolag", host)
	send_tcp_data_to_client("spawn_own_player", 
	{&"x": 0, &"y": 0, &"z": 0}, 
	host)
	
	#print("Lobbies on Server: ", active_lobbies)
	print("Lobby Created")

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
			print("New Client Joined Lobby: ", client)
			
			var lobby_data : Dictionary = {
				
				&"host": lobby[&"host"],
				&"game_mode": lobby[&"game_mode"],
				&"map": lobby[&"map"],
				&"players": lobby[&"players"]
				
			}
			
			# Assign current lobby and host connection on joining client
			for client_in_lobby in connected_clients:
				
				if client == client_in_lobby[&"tcp_peer"]:
					
					client_in_lobby[&"current_lobby"] = lobby_id
					client_in_lobby[&"is_host"] = false
			
			# Connect client to relay
			send_tcp_data_to_client("client_connect_to_relay", 
			EndpointManager.relay_regions[&"NA"], client)
			
			await get_tree().create_timer(2).timeout
			
			# Info to send to joining client
			send_tcp_data_to_client("join_lobby", lobby_data, client)
			
			# Join relay connection session
			for relay in registered_relay_servers:
				
				if relay[&"relay_ip"] == EndpointManager.relay_regions[&"NA"]:
					
					var info_to_send : Dictionary = {
						&"lobby_id": lobby[&"lobby_id"],
						&"client_id": client_id
						}
					
					send_tcp_data_to_client("join_relay_session", info_to_send, relay[&"relay_peer"])
			
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
