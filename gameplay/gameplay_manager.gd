extends Node

@onready var Main_Scene : Node = $"."
var Main_Menu_Scene : PackedScene = preload("uid://cuetqgx13tv6s")
var Server_Browser_Scene : PackedScene = preload("uid://cltyu1oqpw1v4")
var Gameplay_Scene : PackedScene = preload("uid://f11ymr6ma2f7")

func _ready() -> void:
	
	if OS.has_feature("dedicated_server") \
	or OS.has_feature("ingest") \
	or OS.has_feature("relay"):
		
		queue_free()
		
	else:
		
		load_main_menu()

func load_main_menu() -> void:
	
	var Main_Menu_To_Load := Main_Menu_Scene.instantiate()
	
	Main_Scene.add_child(Main_Menu_To_Load)

func load_game() -> void:
	
	pass
