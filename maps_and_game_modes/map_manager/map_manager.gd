extends Node

var Current_Map : Node
var Next_Map_To_Load : PackedScene

var Beanaza_Maps : Dictionary = {
	
	&"Zoolag": "uid://b1vrb25aej0x1"
	
}

func _ready() -> void:
	
	if OS.has_feature("dedicated_server"):
		queue_free()
	else:
		pass

func load_map() -> void:
	pass
	
	

func unload_map() -> void:
	pass
	
