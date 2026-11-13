extends Node

var is_in_menu: bool = false

var is_holding_walk_forward_input: bool = false
var is_holding_walk_backward_input: bool = false
var is_holding_walk_left_input: bool = false
var is_holding_walk_right_input: bool = false

var is_pressing_jump_input: bool = false
var is_pressing_operate_input: bool = false

func _ready() -> void:
	
	if OS.has_feature(FeatureManager.DEDICATED_SERVER): 
		queue_free()

func _process(_delta: float) -> void:
	
	if is_in_menu == false:
		
		track_movement_input()
		track_jump_input()
		track_operate_input()

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
	and is_pressing_jump_input == true: # Checks if the input was held
		
		 # I don't know exactly what this is going to be used for, but it seems like all inputs that last longer than a single
		 # frame are going to be counted as "holding". I don't know if that's the intention or not, but maybe it would be best
		 # to track if it was held for longer than x seconds or something?
		is_pressing_jump_input = false

func track_operate_input() -> void:
	
	if Input.is_action_just_pressed("operate"):
		
		is_pressing_operate_input = true
	
	if Input.is_action_just_released("operate") \
	and is_pressing_operate_input == true: # Checks if the input was held
		
		is_pressing_operate_input = false
