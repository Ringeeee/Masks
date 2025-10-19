class_name Player
extends CharacterBody2D



@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var sword_hitbox: CollisionShape2D = $AttackArea/sword_hitbox
@onready var health_bar: ProgressBar = $HealthBar
@onready var timer: Timer = $Timer
@onready var active_mask_symbol: Sprite2D = $active_mask_symbol
@onready var sword_sprite: Sprite2D = $sword_sprite
@onready var dash_sprite: Sprite2D = $dash_sprite
@onready var heal_sprite: Sprite2D = $heal_sprite








const SPEED := 200.0
const JUMP_VELOCITY := -300.0

var max_masks = 0
@export var active_mask := 0 #0 = nothing, 1 = sword, 2 = healing = 3, 
@export var health := 100.0	#to be changed 
var cooldown_time := 0.4 # Sekunden
var last_action_time := -cooldown_time
var is_alive := true
var cooldown := 0.0
var attack_direction := 1
var heal_player = false

# --- Dash Variablen ---
var dash_speed := 600.0
var dash_time := 0.2          # wie lange der Dash dauert (Sekunden)
var dash_cooldown := 1.0       # Pause bis zum nächsten Dash
var is_dashing := false
var dash_timer := 0.0
var dash_cooldown_timer := 0.0
var heal_cooldown := 0.0


#Wird einmal am Anfang aufgerufen
func _ready():
	attack_area.connect("body_entered", Callable(self, "_on_attack_area_body_entered"))
	health_bar.max_value = health
	_hide_all()

#Läuft (normalerweise) 60x die Sekunde
func _physics_process(delta: float) -> void:
	health_bar.value = health
	var direction := Input.get_axis("left", "right")
	if not is_alive:
		return
	
	if heal_player:
		_heal_player()
	# Dash-Cooldown aktualisieren
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	# --- DASH aktiv ---
	if is_dashing:
		dash_timer -= delta
		velocity.x = attack_direction * dash_speed
		velocity.y = 0  # optional: kein Einfluss von Schwerkraft während Dash
		move_and_slide()

		if dash_timer <= 0:
			is_dashing = false
			dash_cooldown_timer = dash_cooldown
		return  # ← Dieses return nur INNERHALB des Dash-Blocks!
	# --- ENDE DASH ---

	# --- normale Steuerung ---
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

	_handle_direction(direction)

#Läuft FPS abhänig
func _process(delta):
	var direction := Input.get_axis("left", "right")
	_basic_animation(direction)
	
	if Input.is_action_just_pressed("change_mask"):
		_change_mask()
		_change_mask_symbol_to(active_mask)
		
		print(active_mask)
		
	if active_mask == 2:
		heal_player = true
	else:
		heal_player = false

	if Input.is_action_just_pressed("attack"):
		var current_time = Time.get_ticks_msec() / 1000.0
		if current_time - last_action_time >= cooldown_time:
			if active_mask == 0:
				print("nothing")
				heal_player = false
			elif active_mask == 1:
				print("sword")
				heal_player = false
				_do_attack()
			elif active_mask == 2:
				print("healing")
			elif active_mask == 3:
				print("dash")
				heal_player = false
				_do_dash()
			last_action_time = current_time
	
	if Input.is_action_just_pressed("pickup"):
		print("pickup")

#Selbst eingebaute Functionen
func _handle_direction(direction):
	if direction > 0 and animated_sprite.animation != "attack":
		sword_hitbox.position.x = 17
		animated_sprite.flip_h = false
	elif direction < 0 and animated_sprite.animation != "attack":
		sword_hitbox.position.x = -17
		animated_sprite.flip_h = true
	
	if not animated_sprite.is_playing() or animated_sprite.animation != "attack":
		sword_hitbox.position.x = 17 if not animated_sprite.flip_h else -17

func _do_dash():
	if is_dashing or dash_cooldown_timer > 0:
		return
	
	print("Dash!")
	is_dashing = true
	dash_timer = dash_time
	attack_direction = 1 if not animated_sprite.flip_h else -1

	animated_sprite.play("bat_dash")
	cooldown = Time.get_ticks_msec() + 300

func _do_attack():
	if cooldown > Time.get_ticks_msec():		
		return #beendendet die Funktion frühzeitig 
	attack_direction = 1 if not animated_sprite.flip_h else -1 #Richtung beim Start des Angriffs merken
	animated_sprite.play("alt_attack")	
	cooldown = Time.get_ticks_msec() + 200 #abhänig von der animations zeit
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

func _change_mask():
	if active_mask >= max_masks:
		active_mask = 0
		return
	active_mask += 1

func _change_mask_symbol_to(mask):
	match mask:
		0:	#nothing
			active_mask_symbol.modulate = Color(1.0, 1.0, 1.0, 0.0)
			_hide_all()
		1:	#sword
			#active_mask_symbol.modulate = Color(0.0, 0.0, 0.0, 1.0)
			active_mask_symbol.modulate = Color(0.0, 0.0, 0.0, 0)
			_hide_all()
			sword_sprite.show()
		2:	#Healing
			_hide_all()
			active_mask_symbol.modulate = Color(0.306, 0.725, 0.0, 0.0)
			heal_sprite.show()
		3:	#dash
			active_mask_symbol.modulate = Color(0.0, 0.0, 0.0, 0.0)
			_hide_all()
			dash_sprite.show()



		_:	#defalt
			active_mask_symbol.modulate = Color(1.0, 1.0, 1.0, 1.0)
			_hide_all()

func _heal_player():
	if health >= 100: return
	if heal_cooldown >= Time.get_ticks_msec(): return
	health += 5
	heal_cooldown = Time.get_ticks_msec() + 1000

func take_mask():
	if Input.is_action_just_pressed("pickup"):
		max_masks += 1
		
func _hide_all():
	sword_sprite.hide()
	dash_sprite.hide()
	heal_sprite.hide()
