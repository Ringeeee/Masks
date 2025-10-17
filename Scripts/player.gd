extends CharacterBody2D
class_name Player
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var sword_hitbox: CollisionShape2D = $AttackArea/sword_hitbox
@onready var health_bar: ProgressBar = $HealthBar
@onready var timer: Timer = $Timer



const SPEED := 200.0
const JUMP_VELOCITY := -300.0
const active_mask := 1 #0 = nothing, 1 = sword, 2 = ? 

var health := 100	#to be changed 
var cooldown_time := 0.4 # Sekunden
var last_action_time := -cooldown_time
var is_alive := true
var cooldown := 0.0
var attack_direction := 1

#Wird einmal am Anfang aufgerufen
func _ready():
	attack_area.connect("body_entered", Callable(self, "_on_attack_area_body_entered"))
	health_bar.max_value = health

#Läuft (normalerweise) 60x die Sekunde
func _physics_process(delta: float) -> void:
	health_bar.value = health
	var direction := Input.get_axis("left", "right")
	if not is_alive : return
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide() #idk was das macht 
	
		#flip the sprite and Hitbox wenn noetig
	if direction > 0:
		sword_hitbox.position.x = 17
		animated_sprite.flip_h = false
	elif direction < 0:
		sword_hitbox.position.x = -17
		animated_sprite.flip_h = true
	
	if not animated_sprite.is_playing() or animated_sprite.animation != "attack":
		sword_hitbox.position.x = 17 if not animated_sprite.flip_h else -17
	

#Läuft FPS abhänig
func _process(delta):
	var direction := Input.get_axis("left", "right")
	_basic_animation(direction)

	if Input.is_action_just_pressed("attack"):
		var current_time = Time.get_ticks_msec() / 1000.0
		if current_time - last_action_time >= cooldown_time:
			if active_mask == 0:
				print("nothing")
			elif active_mask == 1:
				print("sword")
				_do_attack()
			elif active_mask == 2:
				print("dash")
				_do_dash()
			last_action_time = current_time
	
	if Input.is_action_just_pressed("pickup"):
		print("pickup")

#Selbst eingebaute Functionen

func _do_dash():
	print("_do_dash")

func _do_attack():
	if cooldown > Time.get_ticks_msec():		
		return #beendendet die Funktion frühzeitig 
	attack_direction = 1 if not animated_sprite.flip_h else -1 #Richtung beim Start des Angriffs merken
	animated_sprite.play("attack")
	cooldown = Time.get_ticks_msec() + 400 #abhänig von der animations zeit
	sword_hitbox.position.x = 17 * attack_direction #Hitbox-Position *fixieren* basierend auf gemerkter Richtung
	# Hitbox aktivieren
	attack_area.monitoring = true	
	# Deaktiviere sie nach kurzer Zeit (z. B. nach 0.2 Sekunden)
	await get_tree().create_timer(0.2).timeout
	attack_area.monitoring = false
	
func _on_attack_area_body_entered(body):
	if not body.is_in_group("Enemy"):
		return
		
	if not body.has_method("take_damage"):
		return
		
	body.take_damage(25)

func _basic_animation(direction):	
	if cooldown > Time.get_ticks_msec():		
		return #beendendet die Funktion frühzeitig 

	if is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")	


func take_damage(amount: int):
	if not is_alive : return
	health -= amount
	print("Player hit! Health:", health)
	if health <= 0:
		die()
		
func die():
	timer.start()
	Engine.time_scale = 0.5
	if not is_alive : return
	is_alive = false
	animated_sprite.play("death")
	cooldown += Time.get_ticks_msec() + 100000
	print("you are dead")

func _on_timer_timeout():
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
