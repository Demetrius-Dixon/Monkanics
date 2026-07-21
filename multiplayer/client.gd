extends Node

var Client : PacketPeerUDP

var Is_Registered_With_Ingest_Server : bool = false
var Confirm_Registration_Delay : float = 5.0

var Is_In_Lobby : bool = false
var Is_Host : bool = false

@onready var Main_Scene : Node = $"."

var Main_Menu : Node
var Main_Menu_Preload : PackedScene = preload("uid://cuetqgx13tv6s")

func _ready() -> void:
	
	if OS.has_feature("dedicated_server"):
		queue_free()
	else:
		load_main_menu()
		create_client()

func _process(_delta: float) -> void:
	
	poll_client()

func create_client() -> void:
	
	Client = PacketPeerUDP.new()
	
	Client.connect_to_host(ServerInfo.INGEST_SERVER_IPV4, ServerInfo.INGEST_SERVER_PORT)
	
	set_physics_process(false)
	
	print("Client Created")

func poll_client() -> void:
	
	if Client.get_available_packet_count() > 0:
		
		var Packet : Variant = Client.get_packet()
		
		var Packet_String : Variant = Packet.get_string_from_utf8()
		
		#print("Client Recieved Packet: ", Packet_String)
		
		trigger_client_command(Packet_String)

func trigger_client_command(Command:String) -> void:
	
	if Command == "Confirm_Registration":
		Is_Registered_With_Ingest_Server = true
	
	if Command == "Confirm_Unregistration":
		Is_Registered_With_Ingest_Server = false
	
	if Command == "Confirm_Is_In_Lobby":
		Is_In_Lobby = true

func register_to_ingest_server() -> void:
	
	Client.put_packet("Register".to_utf8_buffer())
	
	confirm_registration_to_ingest_server()

func confirm_registration_to_ingest_server() -> void:
	
	await get_tree().create_timer(Confirm_Registration_Delay).timeout
	
	if Is_Registered_With_Ingest_Server == false:
		return
	
	register_to_ingest_server()
	
	print("Confirmed")

func unregister_from_ingest_server() -> void:
	Client.put_packet("Unregister".to_utf8_buffer())

func create_lobby() -> void:
	
	Client.put_packet("Create_Lobby".to_utf8_buffer())
	
	await get_tree().create_timer(1).timeout
	
	if Is_In_Lobby == false:
		Client.put_packet("Create_Lobby".to_utf8_buffer())
	
	if Is_In_Lobby == true:
		
		Is_Host = true
		
		load_game()

func load_main_menu() -> void:
	
	var Main_Menu_To_Load := Main_Menu_Preload.instantiate()
	
	Main_Menu = Main_Menu_To_Load
	
	Main_Scene.add_child(Main_Menu)

func unload_main_menu() -> void:
	Main_Menu.queue_free()

func load_game() -> void:
	
	unload_main_menu()
	
	pass
