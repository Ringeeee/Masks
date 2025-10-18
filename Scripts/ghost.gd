extends Node2D


@onready var player: Player = %Player
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var speak_bubble: Label = $SpeakBubble



@export var target_path: NodePath
@export var follow_speed: float = 200.0
@export var follow_smoothness: float = 4.0
@export var follow_offset: Vector2 = Vector2(0, -50)


var velocity := Vector2.ZERO

var wobble_time := 0.0
var target: Node2D
var anim: AnimatedSprite2D
var last_position: Vector2


func _ready():
	target = get_node_or_null(target_path)
	anim = $AnimatedSprite2D
	last_position = global_position
	speak_bubble.text = "Hello, little prisoner. 
	Do not be afraid. 
	I am here to help you. 
	But first things first. 
	Please press Q and I will explain further."

func _process(delta):
	wobble_time += delta
	var direction := Input.get_axis("left", "right")
	_basic_animation(direction)
	
	if direction > 0:
		animated_sprite.flip_h = false 
		if position.x != -22 :
				position.x -= 1
	elif direction < 0:
		animated_sprite.flip_h = true
		if position.x != 22 : 
			position.x += 1

			
				# --- 🌀 Zufälliges Wobbeln ---
	# 🌊 Sanftes Wobbeln (langsamer)
	var wobble_speed := 2  # <--- kleiner = langsamer (z. B. 1.0 oder 0.5)
	var wobble_amount := 0.15  # <--- wie stark es kippt (z. B. 0.02 für weniger)
	
	animated_sprite.rotation = sin(wobble_time * wobble_speed) * wobble_amount
	
	if Input.is_action_just_pressed("Dialog"):
		speak_bubble.text = ("I will help you")
func _basic_animation(direction):	


	if direction == 0:
		animated_sprite.play("Idle")
	else:
		animated_sprite.play("Move")
