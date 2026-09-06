extends Node

#var ClientManager : PacketPeerUDP

var relay_client : PacketPeerUDP

@onready var network_info : Node = $"../NetworkInfo"

var is_connected_to_relay : bool = false
var is_registered_with_relay : bool = false

## Universal Packet Functions
#
#var packets_to_be_auto_resent : Array = []
#
## Admin Packet Functions
### Always reliable, system admin packets between the client and central server
#var next_admin_packet_id : int = 0
#const ADMIN_PACKET_RESEND_TIME : float = 0.25
#const MAX_ADMIN_PACKET_RESEND_ATTEMPTS : int = 5
#var admin_packets_in_transit : Array = []
#
#var reliable_packets_received : Array = []
#
#var current_packet_sequence_number : int = 0
#
#var is_authority : bool = false
#var current_client_authority : PacketPeerUDP
#var other_clients_in_lobby : Array[PacketPeerUDP] = []

#var is_registered_with_ingest_server : bool = false
#var confirm_registration_delay : float = 5.0
#
#var is_in_lobby : bool = false
#var is_host : bool = false

func _ready() -> void:
	
	if OS.has_feature("dedicated_server"): 
		queue_free()
	else: 
		create_client()

func _process(delta: float) -> void:
	
	poll_client()
	
	#tick_admin_packet_resend_timer(delta)
	
	if Input.is_action_just_pressed("ui_cancel"):
		#pass
		send_packet_to_relay("forward_all", {&"Example:": "Nose"})

func create_client() -> void:
	
	if OS.has_feature("dedicated_server"): return
	
	relay_client = PacketPeerUDP.new()
	
	relay_client.connect_to_host(network_info.RELAY_SERVER_NA_IPV4, network_info.RELAY_SERVER_PORT)
	
	is_connected_to_relay = true
	
	register_to_relay_server()
	
	print("Client Created")

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
		
		var json_translation : Variant = JSON.new()
		json_translation = JSON.parse_string(packet_string)
		packet = json_translation
		
		var command : String = json_translation[&"command"]
		var info : Variant = json_translation[&"info"]
		
		print("Client Recieved Packet: ", packet)
		
		#if command == "ack":
			#
			#for reliable_packet:Variant in admin_packets_in_transit:
				#
				#if reliable_packet[&"packet_id"] == dictonary[&"packet_id"]:
					#
					#admin_packets_in_transit.erase(reliable_packet)
			#
			#return
		
		trigger_client_command(command, info)

func send_packet_to_relay(command:String, info:Variant) -> void:
	
	var packet : Dictionary = {&"command": command, &"info": info}
	
	var packet_to_send : Variant = JSON.stringify(packet)
	
	relay_client.put_packet(packet_to_send.to_utf8_buffer())

func trigger_client_command(command:String, info:Variant) -> void:
	
	if command == "confirm_registration":
		is_registered_with_relay = true
		
		print("CLIENT IS REGISTERED")
	
	










#func send_packet_to_relay(command:String, info:Dictionary) -> void:
	#
	#var packet : Dictionary = {}
	#
	#next_admin_packet_id = \
	#next_admin_packet_id + 1
	#
	#print(current_packet_sequence_number)
	#
	#packet = {
		#
		#&"packet_type": "admin",
		#&"command": command,
		#&"packet_id": next_admin_packet_id,
		#
	#}
	#
	#var packet_to_send : Variant = JSON.stringify(packet)
	#relay_client.put_packet(packet_to_send.to_utf8_buffer())
	#
	#packet.get_or_add(&"resend_timer", ADMIN_PACKET_RESEND_TIME)
	#packet.get_or_add(&"max_resend_retries", MAX_ADMIN_PACKET_RESEND_ATTEMPTS)
	#
	#admin_packets_in_transit.append(packet)
#
#@warning_ignore("unused_parameter")
#func trigger_client_admin_command(command:String, dictionary:Dictionary) -> void:
	#
	#if command == "print_text":
		#pass
		##print(dictionary)
	#
	##if command == "add_lobby_to_dictionary":
		##ServerBrowser.add_lobby_to_dictionary(dictionary)
#
#func tick_admin_packet_resend_timer(delta:float) -> void:
	#
	#if admin_packets_in_transit.is_empty(): return
	#
	#for reliable_packet:Variant in admin_packets_in_transit:
		#
		#reliable_packet[&"resend_timer"] = reliable_packet[&"resend_timer"] - delta
		#
		#if reliable_packet[&"resend_timer"] <= 0.0:
			#
			#send_admin_command_to_relay(reliable_packet[&"command"], 
			#reliable_packet[&"info"])
		#
		#reliable_packet[&"max_resend_retries"] = \
		#reliable_packet[&"max_resend_retries"] -1
		#
		#if reliable_packet[&"max_resend_retries"] <= 0:
			#
			#admin_packets_in_transit.erase(reliable_packet)
			#
			#return

#func trigger_client_string_command(command:String) -> void:
	#
	#pass
	#
	#if command == "confirm_registration":
		#is_registered_with_ingest_server = true
	#
	#if command == "confirm_unregistration":
		#is_registered_with_ingest_server = false
	#
	#if command == "confirm_is_in_lobby":
		#is_in_lobby = true

#func load_game() -> void:
	#
	#UiManager.unload_main_menu()
	#
	#MapManager.load_map("bnza_zoolag")
	#
	#ServerBrowser.hide()
	#
	#MouseManager.hide_mouse()

#func register_to_ingest_server() -> void:
	#
	#ClientManager.put_packet("register".to_utf8_buffer())
	#
	#confirm_registration_to_ingest_server()
#
#func confirm_registration_to_ingest_server() -> void:
	#
	#await get_tree().create_timer(confirm_registration_delay).timeout
	#
	#if is_registered_with_ingest_server == false:
		#return
	#
	#register_to_ingest_server()
	#
	##print("Confirmed")
#
#func unregister_from_ingest_server() -> void:
	#ClientManager.put_packet("unregister".to_utf8_buffer())
#
#func create_lobby() -> void:
	#
	#ClientManager.put_packet("create_lobby".to_utf8_buffer())
	#
	#await get_tree().create_timer(1).timeout
	#
	#if is_in_lobby == false:
		#ClientManager.put_packet("create_lobby".to_utf8_buffer())
	#
	#if is_in_lobby == true:
		#
		#is_host = true
		#
		#load_game()
#
#func request_active_lobbies() -> void:
	#ClientManager.put_packet("request_active_lobbies".to_utf8_buffer())
