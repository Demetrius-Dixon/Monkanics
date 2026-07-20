extends Node

@onready var Main_Scene : Node = $"."

var Main_Menu : Node
var Main_Menu_Preload : PackedScene = preload("uid://cuetqgx13tv6s")

var Gameplay_Scene : PackedScene = preload("uid://f11ymr6ma2f7")

var Current_Map : Variant

func _ready() -> void:
	
	if OS.has_feature("dedicated_server") \
	or OS.has_feature("ingest") \
	or OS.has_feature("relay"):
		
		queue_free()
		
	else:
		
		load_main_menu()

func load_main_menu() -> void:
	
	var Main_Menu_To_Load := Main_Menu_Preload.instantiate()
	
	Main_Menu = Main_Menu_To_Load
	
	Main_Scene.add_child(Main_Menu)

func unload_main_menu() -> void:
	Main_Menu.queue_free()

func load_current_map() -> void:
	
	var Map_To_Load := preload("uid://b1vrb25aej0x1")
	
	Current_Map = Map_To_Load
	
	Main_Scene.add_child(Current_Map)

func load_game() -> void:
	
	unload_main_menu()
	
	load_current_map()
	
	pass
