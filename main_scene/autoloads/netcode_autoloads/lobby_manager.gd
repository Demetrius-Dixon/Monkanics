extends Node

var current_authority : StreamPeerTCP
var current_map : String = ""
var players_in_lobby : Dictionary = {}

func _ready() -> void:
	
	#INFO Temp dev code. Clients will be able to host later
	if OS.has_feature("dedicated_server"): 
		queue_free()

func create_lobby() -> void:
	
	MapManager.load_map("bnza_zoolag")
	current_map = "bnza_zoolag"

func player_join(player:PacketPeerUDP) -> void:
	
	pass
	
	

func catchup_new_player(player:PacketPeerUDP) -> void:
	
	var command : String = "catchup"
	
	var state_to_sync : Dictionary = {
		
		&"current_map": current_map,
		&"players_in_lobby": players_in_lobby
		
	}
	
	ServerManager.send_packet_to_client(command, state_to_sync, player)

func get_new_gamestate() -> void:
	
	pass
