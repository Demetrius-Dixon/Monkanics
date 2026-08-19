extends Node

var ingest_server : UDPServer

var registered_clients : Array[Dictionary] = []

var active_lobbies : Array[Dictionary] = []

const CLIENT_TIMEOUT_LIMIT : float = 30.0
const END_TIMEOUT_TIMER : float = 0.0

func _ready() -> void:
	
	if not OS.has_feature("dedicated_server"): 
		queue_free()
	if not OS.has_feature("ingest"):
		queue_free()
	else: 
		create_ingest_server()

func _process(_delta: float) -> void:
	
	poll_ingest_server()

func _physics_process(delta: float) -> void:
	
	tick_client_timeout_timers(delta)

func create_ingest_server() -> void:
	
	ingest_server = UDPServer.new()
	
	ingest_server.listen(ServerInfo.INGEST_SERVER_PORT, ServerInfo.INGEST_SERVER_IPV4)
	
	print("Ingest Server Created")

func poll_ingest_server() -> void:
	
	ingest_server.poll()
	
	if ingest_server.is_connection_available():
		
		var peer : Variant = ingest_server.take_connection()
		var packet : Variant = peer.get_packet()
		#print("Server received data: ", packet.get_string_from_utf8())
		
		trigger_server_command(packet.get_string_from_utf8(), peer, peer.get_packet_ip())
	
	for registered_client in registered_clients:
		
		if registered_client[&"peer"].get_available_packet_count() > 0:
			
			var packet : Variant = registered_client[&"peer"].get_packet()
			#print("Server received data: ", packet.get_string_from_utf8())
			
			trigger_server_command(packet.get_string_from_utf8(), registered_client[&"peer"], registered_client[&"peer"].get_packet_ip())

func trigger_server_command(command:StringName, peer:Variant, packet_ip:String) -> void:
	
	if command == "register":
		register_client(peer, packet_ip)
		return
	
	if command == "unregister":
		unregister_client(peer)
		return
	
	if command == "create_lobby":
		create_lobby(peer)
		return
	
	if command == "request_active_lobbies":
		send_lobbies_to_client(peer)

func register_client(peer:Variant, packet_ip:String) -> void:
	
	for registered_client in registered_clients:
		if registered_client[&"peer"] == peer: 
			
			registered_client[&"TimeoutTimer"] = CLIENT_TIMEOUT_LIMIT
			
			return
		
	var client_to_register : Dictionary = {}
	
	client_to_register = {
		
		&"peer": peer,
		&"PeerIP": packet_ip,
		&"IsInLobby": false,
		&"TimeoutTimer": CLIENT_TIMEOUT_LIMIT
		
	}
	
	registered_clients.append(client_to_register)
	
	peer.put_packet("confirm_registration".to_utf8_buffer())
	
	print("Client Registered")
	
	print(registered_clients)

func unregister_client(peer:Variant) -> void:
	
	var client_to_unregister : Dictionary
	var safe_to_unregister : bool = false
	
	for registered_client in registered_clients:
		if registered_client[&"peer"] == peer:
			
			client_to_unregister = registered_client
			
			peer.put_packet("confirm_unregistration".to_utf8_buffer())
			
			safe_to_unregister = true
	
	if safe_to_unregister == true:
		
		registered_clients.erase(client_to_unregister)
		
		client_to_unregister[&"peer"].close()
	
	print(registered_clients)

func create_lobby(peer:Variant) -> void:
	
	for registered_client in registered_clients:
		if registered_client[&"peer"] == peer: 
			pass
		else:
			return
	
	for lobby in active_lobbies:
		if lobby[&"players"].has(peer):
			return
	
	active_lobbies.append({
		
		#&"lobby_name": str(peer) + " 's Game!",
		&"host": peer,
		&"game_mode": "Bean-anza",
		&"map": "Zoolag",
		&"current_player_count": 1,
		&"max_players": 6,
		&"players": [peer]
		
	})
	
	peer.put_packet("confirm_is_in_lobby".to_utf8_buffer())
	
	print(active_lobbies)
	print("Lobby Created")

func tick_client_timeout_timers(time_passed:float) -> void:
	
	if registered_clients.size() <= 0: return
	
	for client in registered_clients:
		
		client[&"TimeoutTimer"] = client[&"TimeoutTimer"] - time_passed
		
		if client[&"TimeoutTimer"] <= END_TIMEOUT_TIMER:
			
			trigger_server_command("unregister", client[&"peer"], client[&"PeerIP"])

func send_lobbies_to_client(peer:Variant) -> void:
	
	for lobby in active_lobbies:
	
		var client_command_dict : Dictionary = {
		
				&"command": "add_lobby_to_dictionary",
				&"lobby_info": lobby
		}
		
		var lobby_to_send : Variant = JSON.stringify(client_command_dict)
		
		peer.put_packet(lobby_to_send.to_utf8_buffer())
