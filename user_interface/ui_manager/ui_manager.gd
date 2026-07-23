extends Node

var main_menu : Node
var main_menu_preload : PackedScene = preload("uid://cuetqgx13tv6s")

func _ready() -> void:
	
	if OS.has_feature("dedicated_server"):
		queue_free()
	else:
		load_main_menu()

func load_main_menu() -> void:
	
	var main_menu_to_load := main_menu_preload.instantiate()
	
	main_menu = main_menu_to_load
	
	add_child(main_menu)

func unload_main_menu() -> void:
	main_menu.queue_free()
