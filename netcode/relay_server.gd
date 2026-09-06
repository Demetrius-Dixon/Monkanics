extends Node

var relay_server : UDPServer

@onready var network_info : Node = $"../NetworkInfo"

var connected_clients : Array[Dictionary] = []
var next_client_id_to_assign : int = 0

#var reliable_packets_received : Array = []
#const RELIABLE_PACKET_RETENTION_TIME : float = 30.0

func _ready() -> void:
	
	if not OS.has_feature("dedicated_server"): 
		queue_free()
	else: 
		create_relay_server()

func _process(_delta: float) -> void:
	
	poll_relay_server()
	
	#tick_reliable_packet_retention_timers(delta)

func create_relay_server() -> void:
	
	relay_server = UDPServer.new()
	
	relay_server.listen(network_info.RELAY_SERVER_PORT, network_info.RELAY_SERVER_NA_IPV4)
	
	print("Relay Server Created")

func poll_relay_server() -> void:
	
	relay_server.poll()
	
	if relay_server.is_connection_available():
		
		var peer : Variant = relay_server.take_connection()
		var packet : Variant = peer.get_packet().get_string_from_utf8()
		
		#print("Server Received Packet: ", packet)
		
		var json_translation : Variant = JSON.new()
		json_translation = JSON.parse_string(packet)
		
		var command : String = json_translation[&"command"]
		var info : Variant = json_translation[&"info"]
		
		#print("Server Received Packet: ", packet)
		
		#if json_translation.has(&"reliable"):
			#
			#acknowledge_reliable_client_packet(json_translation, peer)
			#
			#for reliable_packet:Variant in reliable_packets_received:
				#
				#if json_translation[&"packet_id"] == reliable_packet[&"packet_id"]:
					#return
				#else:
					#continue
			#
			#json_translation.get_or_add(&"packet_retention_time", RELIABLE_PACKET_RETENTION_TIME)
			#
			#reliable_packets_received.append(json_translation)
		
		trigger_server_command(command, info, peer, peer.get_packet_ip())
	
	for client in connected_clients:
		
		if client[&"peer"].get_available_packet_count() > 0:
			
			var peer : PacketPeerUDP = client[&"peer"]
			var packet : Variant = client[&"peer"].get_packet().get_string_from_utf8()
			
			#print("Server Received Packet: ", packet)
			
			var json_translation : Variant = JSON.new()
			json_translation = JSON.parse_string(packet)
			
			var command : String = json_translation[&"command"]
			var info : Variant = json_translation[&"info"]
			
			print("Server Received Packet: ", json_translation)
			
			#if json_translation.has(&"reliable"):
				#
				#acknowledge_reliable_client_packet(json_translation, peer)
				#
				#for reliable_packet:Variant in reliable_packets_received:
					#
					#if json_translation[&"packet_id"] == reliable_packet[&"packet_id"]:
						#return
					#else:
						#continue
				#
				#json_translation.get_or_add(&"packet_retention_time", RELIABLE_PACKET_RETENTION_TIME)
				#
				#reliable_packets_received.append(json_translation)
			
			trigger_server_command(command, info, peer, peer.get_packet_ip())
			
			#send_command_to_client("SERVER COMMAND", {&"Example:": "Beans"}, peer)

func trigger_server_command(command:String, info:Variant, 
peer:PacketPeerUDP, packet_ip:String)-> void:
	
	if command == "register":
		connect_client(peer, packet_ip, assign_client_id())
	
	
	#if command == "forward":
		#
		#for client in connected_clients:
			#
			#send_command_to_client("print_text", dictionary, client[&"peer"])

func connect_client(peer:PacketPeerUDP, ip:Variant, id:int) -> void:
	
	for registered_client in connected_clients:
		
		if peer == registered_client[&"peer"]:
			
			send_packet_to_client("confirm_registration", null, registered_client[&"peer"])
			
			var registration_post_confirmation_packet : Dictionary = \
			{&"command": "confirm_registration", &"info": null}
			
			var pre_packet_to_send : Variant = JSON.stringify(registration_post_confirmation_packet)
			
			registered_client[&"peer"].put_packet(pre_packet_to_send.to_utf8_buffer())
			
			return
	
	var client_to_save : Dictionary = {
			&"peer": peer,
			&"ip": ip,
			&"id": id
		}
	
	connected_clients.append(client_to_save)
	
	#print(connected_clients)
	
	var registration_confirmation_packet : Dictionary = \
	{&"command": "confirm_registration", &"info": null}
	
	var packet_to_send : Variant = JSON.stringify(registration_confirmation_packet)
	
	peer.put_packet(packet_to_send.to_utf8_buffer())

func assign_client_id() -> int:
	
	next_client_id_to_assign = next_client_id_to_assign + 1
	
	return next_client_id_to_assign

func disconnect_client(client_to_disconnect:Variant) -> void:
	
	client_to_disconnect[&"peer"].close()
	
	connected_clients.erase(client_to_disconnect)

func send_packet_to_client(command:String, info:Variant, recipient:PacketPeerUDP) -> void:
	
	var packet : Dictionary = {}
	
	packet = {&"command": command, &"info": info}
	
	var packet_to_send : Variant = JSON.stringify(packet)
	
	recipient.put_packet(packet_to_send.to_utf8_buffer())

#func acknowledge_reliable_client_packet(packet:Dictionary, recipient:PacketPeerUDP) -> void:
	#
	#var ack_packet : Dictionary = {}
	#
	#ack_packet = {
		#
		#&"command": "ack",
		#&"info": packet
		#
	#}
	#
	#var ack_packet_to_send : Variant = JSON.stringify(ack_packet)
	#
	#print(ack_packet)
	#
	#recipient.put_packet(ack_packet_to_send.to_utf8_buffer())
#
#func tick_reliable_packet_retention_timers(delta:float) -> void:
	#
	#if reliable_packets_received.is_empty(): return
	#
	#for reliable_packet:Variant in reliable_packets_received:
		#
		#reliable_packet[&"packet_retention_time"] = \
		#reliable_packet[&"packet_retention_time"] - delta
		#
		#if reliable_packet[&"packet_retention_time"] <= 0.0:
			#
			#reliable_packets_received.erase(reliable_packet)



func forward_client_packet() -> void:
	
	pass
	
