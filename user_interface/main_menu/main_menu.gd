extends Control

@onready var Main_Menu : Node = $"."
@onready var Main_Screen_Nodes : Node = $MainScreen
var Server_Browser_Scene : Variant = preload("uid://cltyu1oqpw1v4")

func _ready() -> void:
	
	var Server_Browser_To_Load : Variant = Server_Browser_Scene.instantiate()
	Server_Browser_To_Load.hide()
	Main_Menu.add_child(Server_Browser_To_Load)
	Server_Browser_Scene = Server_Browser_To_Load

func _on_play_pressed() -> void:
	
	Client.register_to_ingest_server()
	
	Main_Screen_Nodes.hide()
	
	Server_Browser_Scene.show()

func _on_quit_game_pressed() -> void:
	GameQuitter.quit_monkanics()
