extends Node

var Client : PacketPeerUDP

var Is_Registered_With_Ingest_Server : bool = false
var Confirm_Registration_Delay : float = 15.0

func _ready() -> void:
	
	if OS.has_feature("dedicated_server"):
		queue_free()
	else:
		create_client()

func _process(_delta: float) -> void:
	
	poll_client()

func create_client() -> void:
	
	Client = PacketPeerUDP.new()
	
	Client.connect_to_host(RelayInfo.INGEST_SERVER_IPV4, RelayInfo.INGEST_SERVER_PORT)
	
	set_physics_process(false)
	
	print("Client Created")

func poll_client() -> void:
	
	if Client.get_available_packet_count() > 0:
		
		var Packet : Variant = Client.get_packet()
		
		var Packet_String : Variant = Packet.get_string_from_utf8()
		
		print("Client Recieved Packet: ", Packet_String)
		
		trigger_client_command(Packet_String)

func trigger_client_command(Command:String) -> void:
	
	if Command == "Confirm_Registration":
		Is_Registered_With_Ingest_Server = true
	
	if Command == "Confirm_Unregistration":
		Is_Registered_With_Ingest_Server = false
	
	if Command == "Start_Game_As_Host":
		
		pass

func register_to_ingest_server() -> void:
	
	Client.put_packet("Register".to_utf8_buffer())
	
	#confirm_registration_to_ingest_server()

func confirm_registration_to_ingest_server() -> void:
	
	await get_tree().create_timer(Confirm_Registration_Delay).timeout
	
	if Is_Registered_With_Ingest_Server == false:
		return
	
	register_to_ingest_server()
	
	print("Confirmed")

func unregister_from_ingest_server() -> void:
	Client.put_packet("Unregister".to_utf8_buffer())
