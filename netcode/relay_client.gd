extends Node

var relay_client : PacketPeerUDP

@onready var monkanics : Node = $".."
@onready var spawned_object_container : Node = $"../SpawnedObjects"

var is_connected_to_relay : bool = false
var is_registered_with_relay : bool = false

var spawned_objects : Array = []

var current_map : Node = null
var next_map_to_load : PackedScene = null
@onready var map_list : Dictionary = $"../MapList".map_list


func _ready() -> void:
	
	if OS.has_feature("dedicated_server"): 
		queue_free()
	else: 
		create_client()

func _process(_delta: float) -> void:
	
	poll_client()
	
	if Input.is_action_just_pressed("ui_cancel"):
		
		pass
		
		#send_packet_to_relay("forward_all", {&"Example:": "Nose"})

func create_client() -> void:
	
	if OS.has_feature("dedicated_server"): return
	
	relay_client = PacketPeerUDP.new()
	
	relay_client.connect_to_host(monkanics.RELAY_SERVER_NA_IPV4, monkanics.RELAY_SERVER_PORT)
	
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
		
		#print("Client Recieved Packet: ", packet)
		
		var json_translation : Variant = JSON.new()
		json_translation = JSON.parse_string(packet_string)
		packet = json_translation
		
		var command : String = json_translation[&"command"]
		var info : Variant = json_translation[&"info"]
		
		print("Client Recieved Packet: ", packet)
		
		trigger_client_command(command, info)

func send_packet_to_relay(command:String, info:Variant) -> void:
	
	var packet : Dictionary = {&"command": command, &"info": info}
	
	var packet_to_send : Variant = JSON.stringify(packet)
	
	relay_client.put_packet(packet_to_send.to_utf8_buffer())

func trigger_client_command(command:String, info:Variant) -> void:
	
	if command == "confirm_registration":
		is_registered_with_relay = true
		
		print("CLIENT IS REGISTERED")
	
	if command == "load_map":
		load_map(info)
	

func spawn(spawnable:String, spawn_position:Vector3) -> void:
	
	
	
	
	var command : String = "spawn"
	
	var info : Dictionary = {
		
		&"spawnable": spawnable,
		&"spawn_position": spawn_position
		
	}
	
	var packet : Dictionary = {&"command": command, &"info": info}
	
	#forward_packet_to_all_clients(packet, dummy_relay_client)

func confirm_spawn() -> void:
	pass

func despawn() -> void:
	pass

func confirm_despawn() -> void:
	pass

func load_map(map_to_load:String) -> void:
	
	if current_map != null:
		unload_map()
	
	if map_list[map_to_load] == current_map:
		return
	
	map_to_load = map_list[map_to_load]
	
	next_map_to_load = load(map_to_load)
	
	var map_instantiation := next_map_to_load.instantiate()
	
	current_map = map_instantiation
	
	spawned_object_container.add_child(map_instantiation)
	
	next_map_to_load = null

func unload_map() -> void:
	
	if current_map == null:
		return
	
	current_map.queue_free()
	current_map = null
