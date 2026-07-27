extends Node

var ClientManager : PacketPeerUDP

var is_registered_with_ingest_server : bool = false
var confirm_registration_delay : float = 5.0

var is_in_lobby : bool = false
var is_host : bool = false

func _ready() -> void:
	create_client()

func _process(_delta: float) -> void:
	
	poll_client()
	
	if Input.is_action_just_pressed("ui_cancel"):
		
		MouseManager.toggle_mouse()

func create_client() -> void:
	
	if OS.has_feature("dedicated_server"): return
	
	ClientManager = PacketPeerUDP.new()
	
	ClientManager.connect_to_host(ServerInfo.INGEST_SERVER_IPV4, ServerInfo.INGEST_SERVER_PORT)
	
	set_physics_process(false)
	
	print("Client Created")

func poll_client() -> void:
	
	if ClientManager.get_available_packet_count() > 0:
		
		var packet : Variant = ClientManager.get_packet()
		
		var packet_string : Variant = packet.get_string_from_utf8()
		
		#print("Client Recieved packet: ", packet_string)
		
		trigger_client_command(packet_string)

func trigger_client_command(command:String) -> void:
	
	if command == "confirm_registration":
		is_registered_with_ingest_server = true
	
	if command == "confirm_unregistration":
		is_registered_with_ingest_server = false
	
	if command == "confirm_is_in_lobby":
		is_in_lobby = true

func register_to_ingest_server() -> void:
	
	ClientManager.put_packet("register".to_utf8_buffer())
	
	confirm_registration_to_ingest_server()

func confirm_registration_to_ingest_server() -> void:
	
	await get_tree().create_timer(confirm_registration_delay).timeout
	
	if is_registered_with_ingest_server == false:
		return
	
	register_to_ingest_server()
	
	print("Confirmed")

func unregister_from_ingest_server() -> void:
	ClientManager.put_packet("unregister".to_utf8_buffer())

func create_lobby() -> void:
	
	ClientManager.put_packet("create_lobby".to_utf8_buffer())
	
	await get_tree().create_timer(1).timeout
	
	if is_in_lobby == false:
		ClientManager.put_packet("create_lobby".to_utf8_buffer())
	
	if is_in_lobby == true:
		
		is_host = true
		
		load_game()

func load_game() -> void:
	
	UiManager.unload_main_menu()
	
	MapManager.load_map("bnza_zoolag")
	
	MouseManager.hide_mouse()

func request_active_lobbies() -> void:

	var active_lobbies : Array = []

	ClientManager.put_packet("request_active_lobbies".to_utf8_buffer())

	


