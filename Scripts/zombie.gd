extends CharacterBody2D
class_name Enemy

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection: CollisionShape2D = $Vision/CollisionShape2D
@onready var damage_hitbox: Area2D = $DamageHitbox
@onready var hitbox: CollisionShape2D = $Hitbox
@onready var vision_right: RayCast2D = $VisionRight
@onready var vision_left: RayCast2D = $VisionLeft
@onready var damage_timer: Timer = $damage_timer



var direction = 1
var target = Player
var health = 150
var player_in_range := false
var player_in_hitbox := false
var player_in_hitbox_body: Node = null
var is_alive := true
var remove_object_timer := 0.0
var cooldown := 0.0
const SPEED = 50




#func _process(delta):
	#animated_sprite.play("Walk")
	#if player_in_range and target:
		#_move_towards_player(delta)
	

	#if vision_right.is_colliding():
		#direction = -1
		#animated_sprite.flip_h = true
	#if vision_left.is_colliding():
		#direction = 1
		#animated_sprite.flip_h = false
	

func _ready():
	hitbox.connect("body_entered", Callable(self, "_on_attack_area_body_entered"))
	hitbox.connect("body_exited", Callable(self, "_on_attack_area_body_exited"))
	damage_timer.connect("timeout", Callable(self, "_on_damage_timer_timeout"))

func _physics_process(delta: float) -> void:

	if not is_alive:
		if remove_object_timer < Time.get_ticks_msec():
			queue_free()
		return
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	if player_in_range and target:
		_move_towards_player(delta)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * delta)
		animated_sprite.play("Idle")
	
	move_and_slide()

	

	
func _move_towards_player(delta):
	var direction_to_player = sign(target.global_position.x - global_position.x)
	velocity.x = direction_to_player * SPEED
	animated_sprite.flip_h = direction_to_player < 0
	animated_sprite.play("Walk")
	
func _on_attack_area_body_entered(body):
	if not is_alive: return
	if not body.is_in_group("Player"):
		return
	
	player_in_hitbox = true
	animated_sprite.play("Attack")
	player_in_hitbox_body = body
	

	if body.has_method("take_damage"):
		body.take_damage(50)
		
	damage_timer.start()
func _on_vision_body_entered(body):
	if body.is_in_group("Player"):
		target = body
		player_in_range = true

func _on_vision_body_exited(body):
	if body == target:
		player_in_range = false
		target = null
func take_damage(amount: int):
	health -= amount
	print("Enemy hit! Health:", health)
	if health <= 0:
		die()

func die():
	is_alive = false
	hitbox.position.y = 20
	animated_sprite.play("death")
	cooldown += Time.get_ticks_msec() + 100000
	remove_object_timer += Time.get_ticks_msec() + 1100	
	print("zombie is dead")

func _on_attack_area_body_exited(body):
	if body == player_in_hitbox_body:
		player_in_hitbox = false
		player_in_hitbox_body = null
		damage_timer.stop()
