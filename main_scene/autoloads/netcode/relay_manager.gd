extends Node

var relay_server : UDPServer
var dummy_relay_client : PacketPeerUDP

@onready var monkanics : Node = $".."

var connected_clients : Array[Dictionary] = []
var next_client_id_to_assign : int = 0

func _ready() -> void:
	
	if not OS.has_feature("dedicated_server"): 
		queue_free()
	else: 
		create_relay_server()

func _process(_delta: float) -> void:
	
	poll_relay_server()
	
	#spawn_synced("Spawn", Vector3(0,0,0))

func create_relay_server() -> void:
	
	relay_server = UDPServer.new()
	
	relay_server.listen(EndpointManager.RELAY_SERVER_PORT, EndpointManager.RELAY_SERVER_NA_IPV4)
	
	print("Relay Server Created")
	
	# Start game on server side:
	
	await get_tree().create_timer(2).timeout
	
	MapManager.load_map(&"bnza_zoolag")

func poll_relay_server() -> void:
	
	relay_server.poll()
	
	if relay_server.is_connection_available():
		
		var peer : Variant = relay_server.take_connection()
		var packet : Variant = peer.get_packet().get_string_from_utf8()
		
		#print("Server Received Packet: ", packet)
		
		var json_translation : Variant = JSON.new()
		json_translation = JSON.parse_string(packet)
		packet = json_translation
		
		var command : String = json_translation[&"command"]
		var info : Variant = json_translation[&"info"]
		
		trigger_server_command(command, info, peer, peer.get_packet_ip(), packet)
	
	for client in connected_clients:
		
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
			
			trigger_server_command(command, info, peer, peer.get_packet_ip(), packet)

func send_packet_to_client(command:String, info:Variant, recipient:PacketPeerUDP) -> void:
	
	var packet : Dictionary = {}
	
	packet = {&"command": command, &"info": info}
	
	var packet_to_send : Variant = JSON.stringify(packet)
	
	recipient.put_packet(packet_to_send.to_utf8_buffer())

func forward_packet_to_specific_client(packet:Dictionary, recipient:PacketPeerUDP) -> void:
	
	var packet_to_forward : Variant = JSON.stringify(packet)
	
	recipient.put_packet(packet_to_forward.to_utf8_buffer())

func forward_packet_to_all_clients(packet:Dictionary, sender:PacketPeerUDP) -> void:
	
	var packet_to_forward : Variant = JSON.stringify(packet)
	
	for client in connected_clients:
		
		if sender == client[&"peer"]: 
			pass
			continue
		
		client[&"peer"].put_packet(packet_to_forward.to_utf8_buffer())

func trigger_server_command(command:String, info:Variant, 
peer:PacketPeerUDP, packet_ip:String, whole_packet:Variant)-> void:
	
	if command == "register":
		register_client(peer, packet_ip, assign_client_id())
	
	if command == "forward_to":
		forward_packet_to_specific_client(whole_packet, info)
	
	if command == "forward_all":
		forward_packet_to_all_clients(whole_packet, peer)

func register_client(peer:PacketPeerUDP, ip:Variant, id:int) -> void:
	
	for registered_client in connected_clients:
		
		if peer == registered_client[&"peer"]:
			
			send_packet_to_client("confirm_registration", null, registered_client[&"peer"])
			
			return
	
	var client_to_save : Dictionary = {
			&"peer": peer,
			&"ip": ip,
			&"id": id
		}
	
	connected_clients.append(client_to_save)
	
	#print(connected_clients)
	
	send_packet_to_client("confirm_registration", null, peer)
	send_packet_to_client("load_map", &"bnza_zoolag", peer)
	send_packet_to_client("spawn", &"", peer)

func assign_client_id() -> int:
	
	next_client_id_to_assign = next_client_id_to_assign + 1
	
	return next_client_id_to_assign

#func unregister_client(client_to_disconnect:Variant) -> void:
	#
	#client_to_disconnect[&"peer"].close()
	#
	#connected_clients.erase(client_to_disconnect)

func spawn_synced(spawnable:String, spawn_position:Vector3) -> void:
	
	var command : String = "spawn"
	
	var info : Dictionary = {
		
		&"spawnable": spawnable,
		&"spawn_position": spawn_position
		
	}
	
	var packet : Dictionary = {&"command": command, &"info": info}
	
	forward_packet_to_all_clients(packet, dummy_relay_client)

func despawn_synced() -> void:
	pass

func get_new_gamestate() -> void:
	
	pass
