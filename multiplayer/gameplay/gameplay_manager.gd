extends Node

var Main_Menu_Scene : PackedScene = preload("uid://cuetqgx13tv6s")
var Gameplay_Scene : PackedScene = preload("uid://f11ymr6ma2f7")

func _ready() -> void:
	
	if OS.has_feature("dedicated_server") \
	or OS.has_feature("ingest") \
	or OS.has_feature("relay"):
		
		queue_free()
		
	else:
		
		load_main_menu()

func load_main_menu() -> void:
	
	pass
