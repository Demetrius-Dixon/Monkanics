extends Node3D

@onready var Spawn_Point_Container : Node = $PlayerSpawnPoints

@onready var Spawn_Points : Array[Vector3] = [
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
	
	return Spawn_Points.pick_random()
