extends Node

var Client_Player : Node = null
var Player_Preload : PackedScene = preload("uid://bv5ucnu7shjsd")

func _ready() -> void:
	
	if OS.has_feature("dedicated_server"):
		queue_free()
	else:
		pass

func spawn_your_player() -> void:
	
	var Player_Ref : Node = Player_Preload.instantiate()
	
	add_child(Player_Ref)

func despawn_your_player() -> void:
	pass
	

func spawn_other_players() -> void:
	pass
	

func despawn_other_players() -> void:
	pass
	
