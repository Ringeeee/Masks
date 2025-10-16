extends Node2D


@onready var player: Player = %Player
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


@export var target_path: NodePath
@export var follow_speed: float = 200.0
@export var follow_smoothness: float = 4.0
@export var follow_offset: Vector2 = Vector2(0, -50)

var target: Node2D
var anim: AnimatedSprite2D
var last_position: Vector2

func _ready():
	target = get_node_or_null(target_path)
	anim = $AnimatedSprite2D
	last_position = global_position

func _process(delta):
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
	
func _basic_animation(direction):	


	if direction == 0:
		animated_sprite.play("Idle")
	else:
		animated_sprite.play("Move")
