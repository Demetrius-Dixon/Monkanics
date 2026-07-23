extends Node

func _ready() -> void:
	queue_free()

## For clarification, this "main scene" is only a dummy placeholder- 
## -to satisfy Godot’s requirement for a main scene to be set in the project. 
##
## But in reality, this node does absolutely nothing. 
##
## In Monkanics, all game/map/player/etc instances are loaded by a bunch of- 
## -extremely lightweight singleton autoloads and all instantiated nodes/scenes are- 
## -children of the client autoload. 
##
## Then, the ingest + relay server instances-
## -DO NOT load graphics or other nodes. Period.
##
## This is why this script + scene is in the utility folder- 
## -and why it immediately deletes itself upon startup.
