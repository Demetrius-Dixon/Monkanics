extends Node

func _ready() -> void:
	
	if OS.has_feature("dedicated_server"):
		queue_free()
	else:
		pass

func quit_monkanics() -> void:
	
	if Client.Is_Registered_With_Ingest_Server == true:
		Client.unregister_from_ingest_server()
	
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	
	get_tree().quit()
