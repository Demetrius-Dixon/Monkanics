extends Node

var loaded_ui_elements : Array[Dictionary] = []
var ui_scenes : Dictionary = {
	
	&"main_menu": "uid://cuetqgx13tv6s",
	&"server_browser": "uid://cltyu1oqpw1v4"
	
}

func load_ui_element(ui_element_to_load:String) -> void:
	
	var ui_element : String = ui_scenes[ui_element_to_load]
	
	var preloaded_ui_element := load(ui_element)
	
	var ui_element_instantiation : Variant = preloaded_ui_element.instantiate()
	
	add_child(ui_element_instantiation)
	
	ui_element_instantiation.show() 
	
	loaded_ui_elements.append(
		
		{
			&"ui_element": ui_element_to_load,
			&"ui_node": ui_element_instantiation
		}
	)
	
	#print(loaded_ui_elements)

func unload_ui_element(ui_element_to_unload:String) -> void:
	
	for ui_element in loaded_ui_elements:
		
		if ui_element[&"ui_element"] == ui_element_to_unload:
			
			ui_element[&"ui_node"].queue_free()
			
			loaded_ui_elements.erase(ui_element)

func unload_all_ui_elements() -> void:
	
	if loaded_ui_elements.is_empty(): return
	
	for ui_element in loaded_ui_elements:
		
		ui_element[&"ui_node"].queue_free()
		
		loaded_ui_elements.erase(ui_element)
