extends Node

func _ready() -> void:
	
	if OS.has_feature(FeatureManager.DEDICATED_SERVER): 
		queue_free()

func quit_monkanics() -> void:
	
	get_tree().root.\
	propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	
	get_tree().quit()
