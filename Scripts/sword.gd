extends Area2D

@onready var label: Label = $Label

@export var item_value := 1  # Wert, den es erhöht
var player_inside := false
var current_player: Player = null

func _ready():
	connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body):
	if body.is_in_group("Player"):
		player_inside = true
		current_player = body

func _on_body_exited(body):
	if body.is_in_group("Player"):
		player_inside = false
		current_player = null

func _process(delta):
	
	if player_inside:
		label.text = "Press: E"
	else:
		label.text = " "
			
	if player_inside and Input.is_action_just_pressed("pickup"):  # z. B. Taste E
		_pickup()

func _pickup():
	if current_player and current_player.has_method("take_mask"):
		current_player.take_mask()  # Player-Methode aufrufen

	queue_free()  # Item entfernen
