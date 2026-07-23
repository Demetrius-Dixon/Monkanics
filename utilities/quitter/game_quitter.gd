extends Node

func quit_monkanics() -> void:
	
	if Client.is_registered_with_ingest_server == true:
		Client.unregister_from_ingest_server()
	
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	
	get_tree().quit()
