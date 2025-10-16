extends CharacterBody2D
class_name Enemy

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player_hitbox: Area2D = $player_hitbox
@onready var enviroment_hitbox: CollisionShape2D = $Enviroment_Hitbox
@onready var detection: CollisionShape2D = $vision/CollisionShape2D
@onready var damage_timer: Timer = $damage_timer

var target: Player
var direction := 0
var player_in_range := false
var player_in_hitbox := false
var player_in_hitbox_body: Node = null
var health := 50
var is_alive := true
var cooldown := 0.0
var remove_object_timer := 0.0
const SPEED := 75.0

func _ready():
	player_hitbox.connect("body_entered", Callable(self, "_on_attack_area_body_entered"))
	player_hitbox.connect("body_exited", Callable(self, "_on_attack_area_body_exited"))
	$vision.connect("body_entered", Callable(self, "_on_vision_body_entered"))
	$vision.connect("body_exited", Callable(self, "_on_vision_body_exited"))
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
		animated_sprite.position.y = -8
		animated_sprite.play("Idle")
	
	move_and_slide()

func _move_towards_player(delta):
	var direction_to_player = sign(target.global_position.x - global_position.x)
	velocity.x = direction_to_player * SPEED
	animated_sprite.flip_h = direction_to_player < 0
	animated_sprite.position.y = -19
	animated_sprite.play("Walk")


# --- Spieler Schaden zufügen ---

func _on_attack_area_body_entered(body):
	if not is_alive: return
	if not body.is_in_group("Player"):
		return
	
	player_in_hitbox = true
	player_in_hitbox_body = body
	
	if body.has_method("take_damage"):
		body.take_damage(25)
	
	
	damage_timer.start()  # starte den Schadenstimer
	
	

func _on_attack_area_body_exited(body):
	if body == player_in_hitbox_body:
		player_in_hitbox = false
		player_in_hitbox_body = null
		damage_timer.stop()  # kein Schaden mehr, wenn Spieler draußen

func _on_damage_timer_timeout():
	if player_in_hitbox and player_in_hitbox_body and player_in_hitbox_body.has_method("take_damage"):
		player_in_hitbox_body.take_damage(25)


# --- Spielererkennung (Vision) ---

func _on_vision_body_entered(body):
	if body.is_in_group("Player"):
		target = body
		player_in_range = true

func _on_vision_body_exited(body):
	if body == target:
		player_in_range = false
		target = null


# --- Leben & Tod ---

func take_damage(amount: int):
	health -= amount
	print("Enemy hit! Health:", health)
	if health <= 0:
		die()

func die():
	is_alive = false
	animated_sprite.position.y = -27
	animated_sprite.play("death")
	cooldown += Time.get_ticks_msec() + 100000
	remove_object_timer += Time.get_ticks_msec() + 1100
	enviroment_hitbox.position.y = 15
	print("slime is dead")
