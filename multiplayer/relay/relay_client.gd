extends Node

var Relay_Client : PacketPeerUDP

var Is_Registered_With_Relay : bool = false
var Confirm_Registration_Delay : float = 15.0

func _ready() -> void:
	
	if OS.has_feature("dedicated_server"):
		queue_free()
	else:
		create_relay_client()

func _process(_delta: float) -> void:
	
	
	
	if Input.is_action_just_pressed("ui_cancel"):
		
		if Is_Registered_With_Relay == false:
			
			register_to_relay_server()
			
		if Is_Registered_With_Relay == true:
			
			unregister_from_relay_server()
	
	poll_relay_client()

func create_relay_client() -> void:
	
	if OS.has_feature("dedicated_server"): 
		return
	
	Relay_Client = PacketPeerUDP.new()
	
	Relay_Client.connect_to_host(RelayInfo.RELAY_ROUTER_IPV4, RelayInfo.RELAY_ROUTER_PORT)
	
	set_physics_process(false)
	
	print("Client Created")

func poll_relay_client() -> void:
	
	if Relay_Client.get_available_packet_count() > 0:
		
		var Packet : Variant = Relay_Client.get_packet()
		
		var Packet_String : Variant = Packet.get_string_from_utf8()
		
		print("Client Recieved Packet: ", Packet_String)
		
		trigger_client_command(Packet_String)

func trigger_client_command(Command:String) -> void:
	
	if Command == "Confirm_Registration":
		Is_Registered_With_Relay = true
	
	if Command == "Confirm_Unregistration":
		Is_Registered_With_Relay = false
	
	if Command == "Start_Game_As_Host":
		
		pass

func register_to_relay_server() -> void:
	
	Relay_Client.put_packet("Register".to_utf8_buffer())
	
	#confirm_registration_to_relay_server()

func confirm_registration_to_relay_server() -> void:
	
	await get_tree().create_timer(Confirm_Registration_Delay).timeout
	
	if Is_Registered_With_Relay == false:
		return
	
	register_to_relay_server()
	
	print("Confirmed")

func unregister_from_relay_server() -> void:
	Relay_Client.put_packet("Unregister".to_utf8_buffer())
