extends Node

var is_holding_walk_forward_input : bool = false
var is_holding_walk_backward_input : bool = false
var is_holding_walk_left_input : bool = false
var is_holding_walk_right_input : bool = false

var is_pressing_jump_input : bool = false
var is_pressing_operate_input : bool = false

func _process(_delta:float) -> void:
	
	track_movement_input()
	track_jump_input()
	track_operate_input()
	
	if Input.is_action_just_pressed("ui_cancel"):
		
		MouseManager.toggle_mouse()

func track_movement_input() -> void:
	
	if Input.is_action_pressed("walk_forward"):
		is_holding_walk_forward_input = true
	else: 
		is_holding_walk_forward_input = false
	
	if Input.is_action_pressed("walk_backward"):
		is_holding_walk_backward_input = true
	else: 
		is_holding_walk_backward_input = false
	
	if Input.is_action_pressed("walk_left"):
		is_holding_walk_left_input = true
	else: 
		is_holding_walk_left_input = false
	
	if Input.is_action_pressed("walk_right"):
		is_holding_walk_right_input = true
	else: 
		is_holding_walk_right_input = false

func track_jump_input() -> void:
	
	if Input.is_action_just_pressed("jump"):
		
		is_pressing_jump_input = true
	
	if Input.is_action_just_released("jump") \
	and is_pressing_jump_input == true: # <- Checks if the input was held
		
		is_pressing_jump_input = false

func track_operate_input() -> void:
	
	if Input.is_action_just_pressed("operate"):
		
		is_pressing_operate_input = true
	
	if Input.is_action_just_released("operate") \
	and is_pressing_operate_input == true: # <- Checks if the input was held
		
		is_pressing_operate_input = false
