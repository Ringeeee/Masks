extends CharacterBody2D
class_name Slime


@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $Area2D


var target: Player
var direction := 0
var player_in_range := false
const SPEED := 100.0

var health := 100

func _physics_process(delta: float) -> void:


	# Add the gravity.
	if not is_on_floor():	
		
		velocity += get_gravity() * delta
	
	#play animations
	if is_on_floor():
		if direction == 0:
			animated_sprite.play("Idle")
			
	move_and_slide()
