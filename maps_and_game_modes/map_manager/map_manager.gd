extends Node

var current_map : Node = null
var next_map_to_load : PackedScene = null

var map_list : Dictionary = {
	
	&"bnza_zoolag": "uid://b1vrb25aej0x1"
	
}

func load_map(map_to_load:String) -> void:
	
	if current_map != null:
		unload_map()
	
	map_to_load = map_list[map_to_load]
	
	next_map_to_load = load(map_to_load)
	
	var map_instantiation := next_map_to_load.instantiate()
	
	current_map = map_instantiation
	
	add_child(map_instantiation)
	
	next_map_to_load = null

func unload_map() -> void:
	
	if current_map == null:
		return
	
	current_map.queue_free()
	current_map = null
