extends Node

var player_sub_managers : Array[String] = [
	
	"uid://oylpkixktb7v", # Spawn
	
]

func _ready() -> void:
	load_player_sub_managers()

func load_player_sub_managers() -> void:
	
	for manager in player_sub_managers:
		load(manager)
