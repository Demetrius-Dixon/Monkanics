extends Control

#@onready var ping_label : Node = $HBoxContainer/Ping
@onready var lobby_name_label : Node = $HBoxContainer/LobbyName
#@onready var map_label : Node = $HBoxContainer/Map
#@onready var player_count_label : Node = $HBoxContainer/PlayerCount

@onready var join_button : Node = $HBoxContainer/Button

var lobby_id : int

func _ready() -> void:
	join_button.pressed.connect(_on_join_pressed)

func _on_join_pressed() -> void:
	ClientManager.request_to_join_lobby(lobby_id)
