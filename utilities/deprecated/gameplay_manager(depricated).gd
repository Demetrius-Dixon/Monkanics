extends Node

@onready var Main_Scene : Node = $"."

var main_menu : Node
var main_menu_preload : PackedScene = preload("uid://cuetqgx13tv6s")

var Gameplay_Scene : PackedScene = preload("uid://f11ymr6ma2f7")

var current_map : Variant

func _ready() -> void:
	
	if OS.has_feature("dedicated_server") \
	or OS.has_feature("ingest") \
	or OS.has_feature("relay"):
		
		queue_free()
		
	else:
		
		load_main_menu()

func load_main_menu() -> void:
	
	var main_menu_to_load := main_menu_preload.instantiate()
	
	main_menu = main_menu_to_load
	
	Main_Scene.add_child(main_menu)

func unload_main_menu() -> void:
	main_menu.queue_free()

func load_current_map() -> void:
	
	var map_to_load := preload("uid://b1vrb25aej0x1")
	
	current_map = map_to_load
	
	Main_Scene.add_child(current_map)

func load_game() -> void:
	
	unload_main_menu()
	
	load_current_map()
	
	pass
