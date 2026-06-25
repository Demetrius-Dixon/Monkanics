extends Node

func quit_monkanics() -> void:
	
	Client.unregister_from_ingest_server()
	
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()
