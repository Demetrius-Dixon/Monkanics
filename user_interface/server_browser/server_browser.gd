extends Control

@onready var server_list : Node = $"TabContainer/Join Lobby"

var received_active_lobbies : Array[Dictionary] = []

func _ready() -> void:
	hide()

func _on_create_lobby_pressed() -> void:
	ClientManager.create_lobby()

func add_lobby_to_dictionary(lobby:Dictionary) -> void:
	
	received_active_lobbies.append(lobby)
	
	var lobby_name_string : String = lobby[&"host"]
	
	print("LOBBY_NAME_STRING ", lobby_name_string)
	
	#add_lobbies_to_server_list(lobby[&"host"])
	
	#print("SERVER BROWSER: ", received_active_lobbies)

func add_lobbies_to_server_list(lobby_name:String) -> void:
	server_list.add_item(lobby_name)

func clear_server_browser_cache() -> void:
	received_active_lobbies.clear()
