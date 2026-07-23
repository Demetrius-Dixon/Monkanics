extends Node3D

@onready var spawn_point_container : Node = $PlayerSpawnPoints

@onready var spawn_points : Array[Vector3] = [
	$"PlayerSpawnPoints/1".global_position,
	$"PlayerSpawnPoints/2".global_position,
	$"PlayerSpawnPoints/3".global_position,
	$"PlayerSpawnPoints/4".global_position,
	$"PlayerSpawnPoints/5".global_position,
	$"PlayerSpawnPoints/6".global_position,
	$"PlayerSpawnPoints/7".global_position,
	$"PlayerSpawnPoints/8".global_position,
	$"PlayerSpawnPoints/9".global_position
	]

func select_spawn_point() -> Vector3:
	
	return spawn_points.pick_random()
