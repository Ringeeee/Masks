extends CharacterBody2D
class_name Enemy


@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player_hitbox: Area2D = $player_hitbox


var target: Player
var direction := 0
var player_in_range := false
var health := 100
const SPEED := 100.0

func _ready():
	player_hitbox.connect("body_entered", Callable(self, "_on_attack_area_body_entered"))

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():	
		
		velocity += get_gravity() * delta
	
	#play animations
	if is_on_floor():
		if direction == 0:
			animated_sprite.play("Idle")
			
	move_and_slide()
	
func _on_attack_area_body_entered(body):
	if not body.is_in_group("Player"):
		return
	print("idk")
	if not body.has_method("take_damage"):
		return
		
	body.take_damage(25)
	
	
func take_damage(amount: int):
	health -= amount
	print("Enemy hit! Health:", health)
	if health <= 0:
		die()

	
func die():
	queue_free()
