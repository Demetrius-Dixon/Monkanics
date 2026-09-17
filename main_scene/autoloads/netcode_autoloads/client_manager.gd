extends Node

var relay_client : PacketPeerUDP
var relay_client_tcp : StreamPeerTCP

var is_registered_with_relay : bool = false

func _ready() -> void:
	
	if OS.has_feature("dedicated_server"): 
		queue_free()
	else: 
		create_client()

func _process(_delta: float) -> void:
	
	poll_client()
	
	poll_client_tcp()
	
	if Input.is_action_just_pressed("ui_cancel"):
		
		#pass
		
		#print(relay_client_tcp.get_status())
		
		#relay_client_tcp.poll()
		#
		#print("TCP Status: ", relay_client_tcp.get_status())
		
		#send_packet_to_relay("forward_all", {&"Example:": "Nose"})
		
		send_tcp_data_to_relay()

func create_client() -> void:
	
	if OS.has_feature("dedicated_server"): return
	
	relay_client = PacketPeerUDP.new()
	relay_client.connect_to_host(EndpointManager.RELAY_SERVER_NA_IPV4, EndpointManager.RELAY_SERVER_PORT)
	
	relay_client_tcp = StreamPeerTCP.new()
	relay_client_tcp.connect_to_host(EndpointManager.RELAY_SERVER_NA_IPV4, EndpointManager.RELAY_TCP_PORT)
	
	#register_to_relay_server()
	
	print("Client Created")
	
	
	#await get_tree().create_timer(1).timeout
	#
	#SpawnManager.spawn_local("player", 0,0,0)

func register_to_relay_server() -> void:
	
	send_packet_to_relay("register", null)
	
	confirm_registration_to_relay_server()

func confirm_registration_to_relay_server() -> void:
	
	await get_tree().create_timer(1.0).timeout
	
	if is_registered_with_relay == true:
		return
	
	register_to_relay_server()
	
	#print("Confirmed")

#func unregister_from_relay_server() -> void:
	#ClientManager.put_packet("unregister".to_utf8_buffer())

func poll_client() -> void:
	
	if relay_client.get_available_packet_count() > 0:
		
		var packet : Variant = relay_client.get_packet()
		var packet_string : Variant = packet.get_string_from_utf8()
		
		#print("Client Recieved Packet: ", packet)
		
		var json_translation : Variant = JSON.new()
		json_translation = JSON.parse_string(packet_string)
		packet = json_translation
		
		var command : String = json_translation[&"command"]
		var info : Variant = json_translation[&"info"]
		
		#print("Client Recieved Packet: ", packet)
		
		trigger_client_command(command, info)

func poll_client_tcp() -> void:
	
	relay_client_tcp.poll()
	
	

func send_tcp_data_to_relay() -> void:
	
	var packet : Dictionary = {
	&"command": "test",
	&"info": "Hello from client!"
	}
	
	var data := JSON.stringify(packet).to_utf8_buffer()
	
	relay_client_tcp.put_u32(data.size())
	relay_client_tcp.put_data(data)
	
	
	#relay_client_tcp.put_var("Hello from the client!")
	
	#if relay_client_tcp.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		#relay_client_tcp.put_var("Hello from the client!")
	#else:
		#print("Cannot send; not connected.")

func send_packet_to_relay(command:String, info:Variant) -> void:
	
	var packet : Dictionary = {&"command": command, &"info": info}
	
	var packet_to_send : Variant = JSON.stringify(packet)
	
	relay_client.put_packet(packet_to_send.to_utf8_buffer())

func trigger_client_command(command:String, info:Variant) -> void:
	
	if command == "confirm_registration":
		is_registered_with_relay = true
		
		#print("CLIENT IS REGISTERED")
	
	if command == "load_map":
		MapManager.load_map(info)



func confirm_spawn() -> void:
	pass

func confirm_despawn() -> void:
	pass
