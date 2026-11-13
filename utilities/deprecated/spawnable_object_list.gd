extends Node

var spawnable_objects : Dictionary = {
	
	&"player": "uid://bv5ucnu7shjsd",
	&"dummy_player": "uid://byomjy8wiwd5j"
	
}

func spawn_local(spawnable:String, 
spawn_x:float, spawn_y:float, spawn_z:float) -> void:
	
	var object : String = spawnable_objects[spawnable]
	
	var object_to_spawn := load(object)
	
	var object_instantiation : Variant = object_to_spawn.instantiate()
	
	add_child(object_instantiation)
	
	object_instantiation.position = Vector3(spawn_x, spawn_y, spawn_z)

func despawn_local() -> void:
	
	pass
