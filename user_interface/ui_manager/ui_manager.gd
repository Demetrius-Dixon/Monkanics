extends Node

var Main_Menu : Node
var Main_Menu_Preload : PackedScene = preload("uid://cuetqgx13tv6s")

func _ready() -> void:
	
	if OS.has_feature("dedicated_server"):
		queue_free()
	else:
		load_main_menu()

func load_main_menu() -> void:
	
	var Main_Menu_To_Load := Main_Menu_Preload.instantiate()
	
	Main_Menu = Main_Menu_To_Load
	
	add_child(Main_Menu)

func unload_main_menu() -> void:
	Main_Menu.queue_free()
