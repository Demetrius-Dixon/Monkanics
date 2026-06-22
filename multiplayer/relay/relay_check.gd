extends Node

@onready var Relay_Router : Node = $"../RelayRouter"
@onready var Relay_Client : Node = $"../RelayClient"

func _ready() -> void:
	
	# If the file is a dedicated server:
	if OS.has_feature("dedicated_server"):
		delete_for_server()
		queue_free()
	
	# If the file isn't a dedicated server:
	if not OS.has_feature("dedicated_server"):
		delete_for_client()
		queue_free()
	
	queue_free()

func delete_for_client() -> void:
	Relay_Router.queue_free()

func delete_for_server() -> void:
	Relay_Client.queue_free()
	$"../NetworkManager".queue_free()
