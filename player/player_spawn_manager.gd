extends Node

func _ready() -> void:
	
	if OS.has_feature("dedicated_server"):
		queue_free()
	else:
		pass

func spawn_your_player() -> void:
	pass
	

func spawn_other_player() -> void:
	pass
	

func despawn_your_player() -> void:
	pass
	

func despawn_other_player() -> void:
	pass
	
