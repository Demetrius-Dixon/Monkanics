extends Node

var Ingest_Server : UDPServer

var Registered_Relay_Clients : Array[Dictionary] = []
var Paired_Lobbies : Array[Dictionary] = []

const Client_Timeout_Limit : float = 30.0
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
	
	pair_lobby()

func _physics_process(delta: float) -> void:
	
	tick_client_timeout_timers(delta)

func create_ingest_server() -> void:
	
	Ingest_Server = UDPServer.new()
	
	Ingest_Server.listen(ServerInfo.INGEST_SERVER_PORT, ServerInfo.INGEST_SERVER_IPV4)
	
	print("Ingest Server Created")

func poll_ingest_server() -> void:
	
	Ingest_Server.poll()
	
	if Ingest_Server.is_connection_available():
		
		var Peer : Variant = Ingest_Server.take_connection()
		
		var Packet : Variant = Peer.get_packet()
		
		print("Server received data: ", Packet.get_string_from_utf8())
		
		trigger_server_command(Packet.get_string_from_utf8(), Peer, Peer.get_packet_ip())
	
	for registered_client in Registered_Relay_Clients:
		
		if registered_client[&"Peer"].get_available_packet_count() > 0:
			
			var Packet : Variant = registered_client[&"Peer"].get_packet()
			
			print("Server received data: ", Packet.get_string_from_utf8())
			
			trigger_server_command(Packet.get_string_from_utf8(), registered_client[&"Peer"], registered_client[&"Peer"].get_packet_ip())

func trigger_server_command(Command:StringName, Peer:Variant, Packet_IP:String) -> void:
	
	if Command == "Register":
		
		for registered_client in Registered_Relay_Clients:
			if registered_client[&"Peer"] == Peer: 
				
				registered_client[&"TimeoutTimer"] = Client_Timeout_Limit
				
				return
		
		var Client_To_Register : Dictionary = {}
		
		Client_To_Register = {
			
			&"Peer": Peer,
			&"PeerIP": Packet_IP,
			&"IsPaired": false,
			&"TimeoutTimer": Client_Timeout_Limit
			
		}
		
		Registered_Relay_Clients.append(Client_To_Register)
		
		Peer.put_packet("Confirm_Registration".to_utf8_buffer())
		
		print("Client Registered")
		
		print(Registered_Relay_Clients)
		
		return
	
	if Command == "Unregister":
		
		var Client_To_Unregister : Dictionary
		var Safe_To_Unregister : bool = false
		
		for registered_client in Registered_Relay_Clients:
			if registered_client[&"Peer"] == Peer:
				
				Client_To_Unregister = registered_client
				
				Peer.put_packet("Confirm_Unregistration".to_utf8_buffer())
				
				Safe_To_Unregister = true
		
		if Safe_To_Unregister == true:
			
			Registered_Relay_Clients.erase(Client_To_Unregister)
			
			Client_To_Unregister[&"Peer"].close()
		
		print(Registered_Relay_Clients)
		
		return

func pair_lobby() -> void:
	
	if Registered_Relay_Clients.size() <= 0: 
		return
	
	var Unpaired_Client_Count : int = 0
	
	for client in Registered_Relay_Clients:
		if client[&"IsPaired"] == false:
			Unpaired_Client_Count = Unpaired_Client_Count + 1
	
	print(Unpaired_Client_Count)
	
	if Unpaired_Client_Count >= 1:
		
		pass
		
		#TODO Start Game Session
	
	if Unpaired_Client_Count >= 2:
		
		pass
		
		#TODO Join Game Session
		
		#var Lobby_To_Pair : Dictionary = {}
		#
		#for client_to_pair in Registered_Relay_Clients:
			#
			#if client_to_pair[&"IsPaired"] == true: 
				#continue
			

func tick_client_timeout_timers(Time_Passed:float) -> void:
	
	if Registered_Relay_Clients.size() <= 0: return
	
	for client in Registered_Relay_Clients:
		
		client[&"TimeoutTimer"] = client[&"TimeoutTimer"] - Time_Passed
		
		if client[&"TimeoutTimer"] <= END_TIMEOUT_TIMER:
			
			trigger_server_command("Unregister", client[&"Peer"], client[&"PeerIP"])
