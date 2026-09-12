extends Node

var client_player : Node = null
var player_preload : PackedScene = preload("uid://bv5ucnu7shjsd")

func _ready() -> void:
	
	if OS.has_feature("dedicated_server"):
		queue_free()
	else:
		pass

func spawn_your_player() -> void:
	
	var player_ref : Node = player_preload.instantiate()
	
	add_child(player_ref)

func despawn_your_player() -> void:
	pass
	

func spawn_other_players() -> void:
	pass
	

func despawn_other_players() -> void:
	pass
	
