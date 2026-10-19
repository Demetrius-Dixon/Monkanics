extends Node

var relay_manager_tcp : TCPServer
var relay_manager_udp : UDPServer
var relay_manager_ordered_udp : UDPServer

var relay_to_lobby_manager_tcp : StreamPeerTCP
var tcp_data_buffer : PackedByteArray = PackedByteArray()

var connected_clients : Array[Dictionary] = []
var relay_sessions : Array[Dictionary] = []

func _ready() -> void:
	
	if not OS.has_feature("dedicated_server") \
	or not OS.has_feature("relay_manager"): 
		
		queue_free()
	
	if OS.has_feature("relay_manager"):
		
		create_relay()
		
	else: 
		
		queue_free()

func _process(_delta: float) -> void:
	
	poll_relay_manager_tcp()
	decode_tcp_stream()
	
	poll_relay_manager_udp()
	poll_relay_manager_ordered_udp()
	
	poll_relay_to_lobby_manager_tcp()

func create_relay() -> void:
	
	relay_manager_tcp = TCPServer.new()
	relay_manager_tcp.listen(
		EndpointManager.RELAY_MANAGER_TCP_PORT, 
		EndpointManager.relay_regions[&"NA"])
	print("Relay TCP Created")
	
	relay_manager_udp = UDPServer.new()
	relay_manager_udp.listen(
		EndpointManager.RELAY_MANAGER_UDP_PORT, 
		EndpointManager.relay_regions[&"NA"])
	print("Relay UDP Created")
	
	relay_manager_ordered_udp = UDPServer.new()
	relay_manager_ordered_udp.listen(
		EndpointManager.RELAY_MANAGER_ORDERED_UDP_PORT, 
		EndpointManager.relay_regions[&"NA"])
	print("Relay Ordered UDP Created")
	
	relay_to_lobby_manager_tcp = StreamPeerTCP.new()
	relay_to_lobby_manager_tcp.connect_to_host(
		EndpointManager.LOBBY_MANAGER_IPV4, 
		EndpointManager.LOBBY_MANAGER_TCP_PORT)
	print("Relay -> Lobby TCP Created")
	
	await get_tree().create_timer(1).timeout
	
	connect_to_lobby_manager()

func connect_to_lobby_manager() -> void:
	
	var relay_registration_info : Dictionary = {
		
		&"region": "US",
		&"key": SecretManager.TEST_KEY
		
	}
	
	send_tcp_data_to_lobby_manager("register_official_relay_server", relay_registration_info)







func poll_relay_manager_tcp() -> void:
	
	# Register new clients
	if relay_manager_tcp.is_connection_available():
		
		var client : Dictionary = {
			
			&"username": "",
			&"tcp_peer": relay_manager_tcp.take_connection(),
			&"tcp_data_buffer": PackedByteArray(),
			&"udp_peer": null,
			&"ordered_udp_peer": null,
			&"last_sequence_number": 0,
			&"ip_address": 0,
			&"game_id": -1,
			&"current_lobby": null,
			&"is_host": null,
			&"host_tcp_peer": null,
			&"host_udp_peer": null,
			&"host_ordered_udp_peer": null
			
		}
		
		var peer : Variant = client[&"tcp_peer"]
		
		client[&"ip_address"] = peer.get_connected_host()
		
		connected_clients.append(client)
		
		send_tcp_data_to_client("confirm_relay_manager_tcp_registration", 
		EndpointManager.relay_regions[&"NA"], peer)
		
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

func poll_relay_to_lobby_manager_tcp() -> void:
	
	relay_to_lobby_manager_tcp.poll()
	
	var lobby_manager_bytes : Variant = relay_to_lobby_manager_tcp.get_available_bytes()
	
	if lobby_manager_bytes > 0:
		
		var data : Variant = relay_to_lobby_manager_tcp.get_data(
		lobby_manager_bytes)[1]
		
		#print(data)
		
		tcp_data_buffer.append_array(data)

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
			
			print(packet)
			
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

func send_tcp_data_to_lobby_manager(command:String, info:Variant) -> void:
	
	var packet : Dictionary = {
	&"command": command,
	&"info": info
	}
	
	var data := JSON.stringify(packet).to_utf8_buffer()
	
	relay_to_lobby_manager_tcp.put_u32(data.size())
	relay_to_lobby_manager_tcp.put_data(data)

#func forward_tcp_data_to_specific_client(data:Variant, recipient:StreamPeerTCP) -> void:
	#
	#var command : String = data[&"command"]
	#var info : Dictionary = data[&"info"]
	#
	#send_tcp_data_to_client(command, info, recipient)
#
#func forward_tcp_data_to_all_clients(data:Variant, sender:StreamPeerTCP) -> void:
	#
	#var command : String = data[&"command"]
	#var info : Dictionary = data[&"info"]
	#
	#for client in connected_clients:
		#
		#if sender == client[&"peer"]: 
			#pass
			#continue
		#
		#send_tcp_data_to_client(command, info, client[&"peer"])

func trigger_tcp_server_command(command:String, info:Variant, 
peer:Variant, all_data:Variant, current_lobby:Variant, is_host:Variant)-> void:
	
	#if command == "forward_tcp_to":
		#forward_tcp_data_to_specific_client(all_data, info)
	#
	#if command == "forward_tcp_to_all":
		#forward_tcp_data_to_all_clients(all_data, peer)
	
	pass
	
	if command == "create_new_lobby_instance":
		pass
		
		






func poll_relay_manager_udp() -> void:
	
	relay_manager_udp.poll()
	
	if relay_manager_udp.is_connection_available():
		
		var peer : Variant = relay_manager_udp.take_connection()
		var packet : Variant = peer.get_packet().get_string_from_utf8()
		
		#print("Server Received Packet: ", packet)
		
		var json_translation : Variant = JSON.new()
		json_translation = JSON.parse_string(packet)
		packet = json_translation
		
		var command : String = json_translation[&"command"]
		var info : Variant = json_translation[&"info"]
		
		for client in connected_clients:
			
			if client[&"udp_peer"] == peer:
				
				send_tcp_data_to_client("confirm_relay_manager_udp_registration", 
				EndpointManager.relay_regions[&"NA"], client[&"udp_peer"])
				
				return
			
			if command == "register_to_relay_manager_udp":
				
				client[&"udp_peer"] = peer
				
				send_tcp_data_to_client("confirm_relay_manager_udp_registration", 
				null, client[&"tcp_peer"])
	
	for client in connected_clients:
		
		if client[&"udp_peer"] == null: continue
		
		if client[&"udp_peer"].get_available_packet_count() > 0:
			
			var peer : PacketPeerUDP = client[&"udp_peer"]
			var packet : Variant = client[&"udp_peer"].get_packet().get_string_from_utf8()
			var current_lobby : Variant = client[&"current_lobby"]
			var is_host : Variant = client[&"is_host"]
			
			#print("Server Received Packet: ", packet)
			
			var json_translation : Variant = JSON.new()
			json_translation = JSON.parse_string(packet)
			packet = json_translation
			
			var command : String = json_translation[&"command"]
			var info : Variant = json_translation[&"info"]
			
			#print("Server Received Packet: ", packet)
			
			trigger_udp_server_command(command, info, peer, packet, current_lobby, is_host)

func send_udp_packet_to_client(command:String, info:Variant, recipient:PacketPeerUDP) -> void:
	
	var packet : Dictionary = {}
	
	packet = {&"command": command, &"info": info}
	
	var packet_to_send : Variant = JSON.stringify(packet)
	
	recipient.put_packet(packet_to_send.to_utf8_buffer())

#func forward_udp_packet_to_specific_client(packet:Dictionary, recipient:PacketPeerUDP) -> void:
	#
	#var packet_to_forward : Variant = JSON.stringify(packet)
	#
	#recipient.put_packet(packet_to_forward.to_utf8_buffer())
#
#func forward_udp_packet_to_all_clients(packet:Dictionary, sender:PacketPeerUDP) -> void:
	#
	#var packet_to_forward : Variant = JSON.stringify(packet)
	#
	#for client in connected_clients:
		#
		#if sender == client[&"udp_peer"]: 
			#pass
			#continue
		#
		#client[&"udp_peer"].put_packet(packet_to_forward.to_utf8_buffer())

func trigger_udp_server_command(command:String, info:Variant, 
peer:Variant, whole_packet:Variant, current_lobby:Variant, is_host:Variant)-> void:
	
	pass
	
	#if command == "forward_udp_to":
		#forward_udp_packet_to_specific_client(whole_packet, info)
	#
	#if command == "forward_udp_to_all":
		#forward_udp_packet_to_all_clients(whole_packet, peer)







func poll_relay_manager_ordered_udp() -> void:
	
	relay_manager_ordered_udp.poll()
	
	if relay_manager_ordered_udp.is_connection_available():
		
		var peer : Variant = relay_manager_ordered_udp.take_connection()
		var packet : Variant = peer.get_packet().get_string_from_utf8()
		
		#print("Server Received Ordered Packet: ", packet)
		
		var json_translation : Variant = JSON.new()
		json_translation = JSON.parse_string(packet)
		packet = json_translation
		
		var command : String = json_translation[&"command"]
		var info : Variant = json_translation[&"info"]
		
		#print("Server Received Ordered Packet: ", packet)
		
		for client in connected_clients:
			
			if client[&"ordered_udp_peer"] == peer:
				
				send_tcp_data_to_client("confirm_relay_manager_ordered_udp_registration", 
				EndpointManager.relay_regions[&"NA"], client[&"ordered_udp_peer"])
				
				return
			
			if command == "register_to_relay_manager_ordered_udp":
				
				client[&"ordered_udp_peer"] = peer
				
				send_tcp_data_to_client("confirm_relay_manager_ordered_udp_registration", 
				null, client[&"tcp_peer"])
	
	for client in connected_clients:
		
		if client[&"ordered_udp_peer"] == null: continue
		
		if client[&"ordered_udp_peer"].get_available_packet_count() > 0:
			
			var peer : PacketPeerUDP = client[&"ordered_udp_peer"]
			var packet : Variant = client[&"ordered_udp_peer"].get_packet().get_string_from_utf8()
			
			#print("Server Received Ordered Packet: ", packet)
			
			var json_translation : Variant = JSON.new()
			json_translation = JSON.parse_string(packet)
			packet = json_translation
			
			var command : String = json_translation[&"command"]
			var info : Variant = json_translation[&"info"]
			var current_lobby : Variant = client[&"current_lobby"]
			var is_host : Variant = client[&"is_host"]
			var packet_sequence_number : int = json_translation[&"sequence_number"]
			var expected_sequence_number : int = client[&"last_sequence_number"]
			
			#print("Server Received Ordered Packet: ", packet)
			
			var sequence_difference : int = \
			packet_sequence_number - expected_sequence_number
			
			if sequence_difference <= 0:
				
				continue
				
			else:
				
				trigger_ordered_udp_server_command(command, info, peer, packet, current_lobby, is_host)
				
				client[&"last_sequence_number"] = packet_sequence_number

func send_ordered_udp_packet_to_client(command:String, info:Variant, 
sender:PacketPeerUDP, recipient:PacketPeerUDP) -> void:
	
	var sequence_number : int
	
	for client in connected_clients:
		
		if client[&"ordered_udp_peer"] == sender:
			
			client[&"last_sequence_number"] = \
			client[&"last_sequence_number"] + 1
			
			sequence_number = client[&"last_sequence_number"]
	
	var packet : Dictionary = {}
	
	packet = {&"command": command, 
	&"info": info,
	&"sequence_number": sequence_number
	}
	
	var packet_to_send : Variant = JSON.stringify(packet)
	
	recipient.put_packet(packet_to_send.to_utf8_buffer())

#func forward_ordered_udp_packet_to_specific_client(packet:Dictionary, recipient:PacketPeerUDP) -> void:
	#
	#var packet_to_forward : Variant = JSON.stringify(packet)
	#
	#recipient.put_packet(packet_to_forward.to_utf8_buffer())
#
#func forward_ordered_udp_packet_to_all_clients(packet:Dictionary, sender:PacketPeerUDP) -> void:
	#
	#var packet_to_forward : Variant = JSON.stringify(packet)
	#
	#for client in connected_clients:
		#
		#if sender == client[&"ordered_udp_peer"]: 
			#pass
			#continue
		#
		#client[&"ordered_udp_peer"].put_packet(packet_to_forward.to_utf8_buffer())

func trigger_ordered_udp_server_command(command:String, info:Variant, 
peer:Variant, whole_packet:Variant, current_lobby:Variant, is_host:Variant)-> void:
	
	pass
	
	#if command == "forward_ordered_udp_to":
		#forward_ordered_udp_packet_to_specific_client(whole_packet, info)
	#
	#if command == "forward_ordered_udp_to_all":
		#forward_ordered_udp_packet_to_all_clients(whole_packet, peer)
	
	#if command == "send_untrusted_position_to_server":
		#
		#if current_lobby == 0: return
		#
		#for lobby in active_lobbies:
			#
			#if current_lobby == lobby[&"lobby_id"]:
				#
				#if is_host == true: 
					#return
				#
				#if is_host == false:
					#
					#for client in connected_clients:
						#
						#if client[&"ordered_udp_peer"] == peer:
							#
							#send_ordered_udp_packet_to_client(
							#"send_untrusted_position_to_host", info, 
							#peer, client[&"host_ordered_udp_peer"])
		
		#if is_host == false:
			#
			#send_ordered_udp_packet_to_client("send_untrusted_position", )





func create_relay_session_instance() -> void:
	pass
	
	
