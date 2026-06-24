extends Node

var Relay_Server : UDPServer

var Registered_Relay_Clients : Array[Dictionary] = []
var Paired_Lobbies : Array[Dictionary] = []

@onready var Gameplay_Nodes : Node 

func _ready() -> void:
	
	if not OS.has_feature("dedicated_server"): 
		queue_free()
	if not OS.has_feature("relay"):
		queue_free()
	else: 
		create_relay_server()

func _process(_delta: float) -> void:
	
	poll_udp_server()
	
	pair_lobby()

func create_relay_server() -> void:
	
	if not OS.has_feature("dedicated_server"): 
		return
	
	Relay_Server = UDPServer.new()
	
	Relay_Server.listen(RelayInfo.RELAY_ROUTER_PORT, RelayInfo.RELAY_ROUTER_IPV4)
	
	print("Server Created")

func poll_udp_server() -> void:
	
	Relay_Server.poll()
	
	if Relay_Server.is_connection_available():
		
		var Peer : Variant = Relay_Server.take_connection()
		
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
				return
		
		var Client_To_Register : Dictionary = {}
		
		Client_To_Register = {
			
			&"Peer": Peer,
			&"PeerIP": Packet_IP,
			&"IsPaired": false
			
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
	
	if Registered_Relay_Clients.size() <= 1: 
		return
	
	var Unpaired_Client_Count : int = 0
	
	for client in Registered_Relay_Clients:
		if client[&"IsPaired"] == false:
			Unpaired_Client_Count = Unpaired_Client_Count + 1
	
	print(Unpaired_Client_Count)
	
	if Unpaired_Client_Count >= 2:
		
		var Lobby_To_Pair : Dictionary = {}
		
		for client_to_pair in Registered_Relay_Clients:
			
			if client_to_pair[&"IsPaired"] == true: continue
			
			

func forward_client_game_packet() -> void:
	
	pass
	
