extends Node

var relay_server : UDPServer

func _ready() -> void:
	
	if not OS.has_feature("dedicated_server"): 
		queue_free()
	if not OS.has_feature("relay"):
		queue_free()
	else: 
		pass
		#create_relay_server()

func _process(_delta: float) -> void:
	
	pass
	
	#poll_udp_server()
	#
	#pair_lobby()

#func create_relay_server() -> void:
	#
	#relay_server = UDPServer.new()
	#
	#relay_server.listen(RelayInfo.INGEST_SERVER_PORT, RelayInfo.INGEST_SERVER_IPV4)
	#
	#print("Relay Server Created")
#
#func poll_udp_server() -> void:
	#
	#relay_server.poll()
	#
	#if relay_server.is_connection_available():
		#
		#var peer : Variant = relay_server.take_connection()
		#
		#var packet : Variant = peer.get_packet()
		#
		#print("Server received data: ", packet.get_string_from_utf8())
		#
		#trigger_server_command(packet.get_string_from_utf8(), peer, peer.get_packet_ip())
	#
	#for registered_client in registered_clients:
		#
		#if registered_client[&"peer"].get_available_packet_count() > 0:
			#
			#var packet : Variant = registered_client[&"peer"].get_packet()
			#
			#print("Server received data: ", packet.get_string_from_utf8())
			#
			#trigger_server_command(packet.get_string_from_utf8(), registered_client[&"peer"], registered_client[&"peer"].get_packet_ip())
#
#func trigger_server_command(command:StringName, peer:Variant, packet_ip:String) -> void:
	#
	#if command == "register":
		#
		#for registered_client in registered_clients:
			#if registered_client[&"peer"] == peer: 
				#return
		#
		#var client_to_register : Dictionary = {}
		#
		#client_to_register = {
			#
			#&"peer": peer,
			#&"PeerIP": packet_ip,
			#&"IsPaired": false
			#
		#}
		#
		#registered_clients.append(client_to_register)
		#
		#peer.put_packet("confirm_registration".to_utf8_buffer())
		#
		#print("Client Registered")
		#
		#print(registered_clients)
		#
		#return
	#
	#if command == "unregister":
		#
		#var client_to_unregister : Dictionary
		#var safe_to_unregister : bool = false
		#
		#for registered_client in registered_clients:
			#if registered_client[&"peer"] == peer:
				#
				#client_to_unregister = registered_client
				#
				#peer.put_packet("confirm_unregistration".to_utf8_buffer())
				#
				#safe_to_unregister = true
		#
		#if safe_to_unregister == true:
			#
			#registered_clients.erase(client_to_unregister)
			#
			#client_to_unregister[&"peer"].close()
		#
		#print(registered_clients)
		#
		#return
	#
	#
#
#func pair_lobby() -> void:
	#
	#if registered_clients.size() <= 1: 
		#return
	#
	#var Unpaired_Client_Count : int = 0
	#
	#for client in registered_clients:
		#if client[&"IsPaired"] == false:
			#Unpaired_Client_Count = Unpaired_Client_Count + 1
	#
	#print(Unpaired_Client_Count)
	#
	#if Unpaired_Client_Count >= 2:
		#
		#var Lobby_To_Pair : Dictionary = {}
		#
		#for client_to_pair in registered_clients:
			#
			#if client_to_pair[&"IsPaired"] == true: continue
			#
			#
#
#func forward_client_game_packet() -> void:
	#
	#pass
	#
