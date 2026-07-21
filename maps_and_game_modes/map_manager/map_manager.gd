extends Node

var Current_Map : Node = null
var Next_Map_To_Load : PackedScene = null

var Map_List : Dictionary = {
	
	&"bnza_zoolag": "uid://b1vrb25aej0x1"
	
}

func _ready() -> void:
	
	if OS.has_feature("dedicated_server"):
		queue_free()
	else:
		pass

func load_map(Map_To_Load:String) -> void:
	
	if Current_Map != null:
		unload_map()
	
	Map_To_Load = Map_List[Map_To_Load]
	
	Next_Map_To_Load = load(Map_To_Load)
	
	var Map_Instantiation := Next_Map_To_Load.instantiate()
	
	Current_Map = Map_Instantiation
	
	add_child(Map_Instantiation)
	
	Next_Map_To_Load = null

func unload_map() -> void:
	Current_Map.queue_free()
	Current_Map = null
