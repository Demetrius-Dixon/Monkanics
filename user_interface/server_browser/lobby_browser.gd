extends Control

@onready var lobby_list : Node = $"TabContainer/Join Lobby"
var lobby_selection_button := "uid://ibl4vlin44xa"

var new_lobby_name : String = ""
var lobby_map_selection : String = ""
var lobby_game_mode_selection : String = ""

var lobby_entries : Array[Node] = []

func _ready() -> void:
	
	add_entry_to_lobby_list()

func _on_create_lobby_pressed() -> void:
	
	ClientManager.create_lobby(new_lobby_name)
	
	UiManager.unload_ui_element("server_browser")

func _on_text_edit_text_changed() -> void:
	new_lobby_name = $"TabContainer/Create Lobby/TextEdit".text

func add_entry_to_lobby_list() -> void:
	
	remove_entries_from_lobby_list()
	
	await get_tree().create_timer(0.01).timeout
	
	ClientManager.request_active_lobbies_from_server()
	
	await get_tree().create_timer(1).timeout
	
	#print("Lobby Browser Lobbies: ", ClientManager.received_active_lobbies)
	
	for lobby:Variant in ClientManager.received_active_lobbies:
		
		var new_lobby_selection_button := load(lobby_selection_button)
		
		var new_lobby_selection_button_instantiation : Variant = new_lobby_selection_button.instantiate()
		
		lobby_list.add_child(new_lobby_selection_button_instantiation)
		
		new_lobby_selection_button_instantiation.lobby_name_label.text = lobby[&"lobby_name"]
		
		new_lobby_selection_button_instantiation.lobby_id = lobby[&"lobby_id"]
		
		new_lobby_selection_button_instantiation.custom_minimum_size = Vector2(0, 100)
		
		lobby_entries.append(new_lobby_selection_button_instantiation)

func remove_entries_from_lobby_list() -> void:
	
	if lobby_entries.is_empty(): return
	
	for lobby_entry in lobby_entries:
		
		lobby_entry.queue_free()

func _on_button_pressed() -> void:
	add_entry_to_lobby_list()


func _on_back_button_pressed() -> void:
	
	UiManager.load_ui_element("main_menu")
	
	UiManager.unload_ui_element("server_browser")
