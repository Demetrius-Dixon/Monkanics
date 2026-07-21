extends Node

var Current_Map : Node
var Next_Map_To_Load : Node

func _ready() -> void:
	
	if OS.has_feature("dedicated_server"):
		queue_free()
	else:
		pass
