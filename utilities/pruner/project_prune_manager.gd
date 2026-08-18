extends Node

func _ready() -> void:
	prune_project()

func prune_project() -> void:
	
	if OS.has_feature("dedicated_server"):
		ClientManager.queue_free()
		MapManager.queue_free()
		PlayerMasterManager.queue_free()
		UiManager.queue_free()
		GameQuitterManager.queue_free()
		MathManager.queue_free()
		MouseManager.queue_free()
		ServerBrowser.queue_free()
	
	elif OS.has_feature("ingest"):
		RelayServer.queue_free()
	
	elif OS.has_feature("relay"):
		IngestServer.queue_free()
	
	else:
		pass
	
	queue_free()
