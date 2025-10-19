extends CharacterBody2D

# --- Node-Verbindungen ---
# @onready: Lädt diese Variablen erst, wenn die Szene komplett instanziiert wurde
# Damit wird verhindert, dass Nodes noch nicht existieren, wenn der Code sie benutzt
@onready var ray_cast_right: RayCast2D = $RayCast_right          # RayCast nach rechts, um Hindernisse zu erkennen
@onready var ray_cast_left: RayCast2D = $RayCast_left            # RayCast nach links, um Hindernisse zu erkennen
@onready var animation: AnimatedSprite2D = $Animation           # Animations-Node
@onready var vision_hitbox: CollisionShape2D = $vision/vision_hitbox   # Hitbox für die Spielererkennung
@onready var hitbox: CollisionShape2D = $Hitbox                 # Normale Kollisionshitbox des Zombies
@onready var bite_timer: Timer = $bite_timer                    # Timer für Biss-Angriff
@onready var ray_cast_bite_player: RayCast2D = $RayCast_bite_player   # RayCast für Spieler-Biss

# --- Variablen ---
var is_alive := true                      # Lebendig / tot
var health := 100                         # Leben
var damage := 50                          # Schaden, den der Zombie verursacht
var random_movement_cooldown := 0         # Cooldown für zufällige Bewegungen
var is_walking := true                     # Ob der Zombie gerade läuft
var direction := 1                         # Bewegungsrichtung: 1 = rechts, -1 = links
var speed := 50                            # Bewegungsgeschwindigkeit
var player_visible := false                # Wird aktuell nicht benutzt, könnte für Line-of-Sight sein
var chase_player := false                  # Ob der Zombie gerade den Spieler verfolgt
var remove_object_timer := 0               # Timer, um Zombie nach Tod zu entfernen
var player_in_hitbox := false              # Spieler im Nahbereich (nicht aktuell benutzt)
var attack_animation_cooldown := 0         # Timer, um Angriffanimationen zu limitieren
var bite_cooldown := 0                     # Cooldown, damit nicht sofort mehrfach Schaden verursacht wird

var target: Player                         # Referenz auf den Spieler, der verfolgt wird
var player_in_hitbox_body: Node = null     # Node-Referenz für Spieler, der in Nahbereich ist

# --- READY-Funktion ---
# Wird einmal beim Start der Szene aufgerufen
func _ready() -> void:
	# Verbinden der Signale für die Vision-Hitbox
	# Wenn ein Körper die Hitbox betritt oder verlässt, werden die entsprechenden Funktionen aufgerufen
	$vision.connect("body_entered", Callable(self, "_on_vision_body_entered"))
	$vision.connect("body_exited", Callable(self, "_on_vision_body_exited"))

# --- PHYSICS_PROCESS ---
# Wird 60x pro Sekunde aufgerufen, ideal für Bewegung & Physik
func _physics_process(delta: float) -> void:
	if not is_alive: return    # Stoppt alle Physik-Updates, wenn der Zombie tot ist

# --- PROCESS ---
# Wird pro Frame aufgerufen, für Animationen, KI etc.
func _process(delta: float) -> void:
	if not is_alive: return    # Stoppt alles, wenn tot

	_idle_and_move()           # Zufällige Bewegungen oder Idle
	_walking()                 # Bewegt den Zombie, wenn is_walking = true
	_chasing_player()          # Spieler verfolgen, wenn erkannt
	_handle_direction()        # Richtung anpassen und Animation flippen
	_check_for_bite()          # Prüft, ob der Spieler gebissen wird

	move_and_slide()           # Godot-Funktion, die Bewegungen umsetzt (Velocity auf Collider anwenden)

# --- ZUFÄLLIGE BEWEGUNG / IDLE ---
func _idle_and_move():
	if attack_animation_cooldown > Time.get_ticks_msec(): return   # Stoppt Bewegung während Angriff
	if chase_player: return                                        # Stoppt Zufallsbewegung, wenn Spieler verfolgt wird

	# Animation auswählen
	if velocity.x > 0:
		animation.play("Walk")
	elif velocity.x == 0:
		animation.play("Idle")

	# Prüft, ob Cooldown für neue Zufallsbewegung vorbei ist
	if random_movement_cooldown < Time.get_ticks_msec():
		random_movement_cooldown += 5000  # Setzt Cooldown auf 5 Sekunden
		var random_number := randf()       # Zufällige Zahl zwischen 0.0 und 1.0
		if random_number >= 0.5:
			animation.play("Walk")
			is_walking = true
		else:
			animation.play("Idle")
			is_walking = false

# --- ZOMBIE BEWEGUNG ---
func _walking():
	if not is_walking: return                   # Nur bewegen, wenn Zombie laufen soll
	if attack_animation_cooldown > Time.get_ticks_msec(): return   # Nicht während Angriff

	velocity.x = direction * speed              # Geschwindigkeit setzen, je nach Richtung

# --- RICHTUNG HANDHABEN ---
func _handle_direction():
	# RayCasts prüfen, ob Hindernisse da sind
	if ray_cast_left.is_colliding():
		direction = 1   # Hindernis links, nach rechts drehen
	elif ray_cast_right.is_colliding():
		direction = -1  # Hindernis rechts, nach links drehen

	# Position der Hitboxen anpassen und Animation spiegeln
	if direction < 0:
		vision_hitbox.position.x = -100
		ray_cast_bite_player.target_position = Vector2(-20, 0)
		animation.flip_h = true
	elif direction > 0:
		vision_hitbox.position.x = 100
		ray_cast_bite_player.target_position = Vector2(20, 0)
		animation.flip_h = false

# --- VISION SIGNALE ---
func _on_vision_body_entered(body):
	if not is_alive: return
	if body.is_in_group("Player"):
		chase_player = true       # Spieler verfolgen
		target = body             # Referenz auf Spieler speichern

func _on_vision_body_exited(body):
	if not is_alive: return
	if body.is_in_group("Player"):
		chase_player = false      # Spieler nicht mehr verfolgen
		target = null
		direction *= 1            # keine Richtungsänderung
		animation.play("Idle")    # Idle Animation

# --- SPIELER VERFOLGEN ---
func _chasing_player():
	if attack_animation_cooldown > Time.get_ticks_msec(): return
	if not chase_player: return

	var direction_to_player = sign(target.global_position.x - global_position.x)  # Richtung zum Spieler
	direction = direction_to_player
	velocity.x = direction * speed * 1.5   # Etwas schneller als normale Bewegung
	animation.flip_h = direction_to_player > 0
	animation.play("Walk")

# --- TOD ---
func die():
	is_alive = false
	animation.play("Dead")
	hitbox.position.y = 35  # Optional: Kollisionshitbox verschieben
	print("zombie is dead")

func take_damage(amount: int):
	if not is_alive: return
	health -= amount
	print("Zombie hit! Health:", health)
	if health <= 0:
		die()

# --- BISS / RAYCAST ---
func _check_for_bite():
	if not is_alive: return
	if ray_cast_bite_player.is_colliding():                    # Prüft, ob RayCast etwas trifft
		var collider = ray_cast_bite_player.get_collider()    # Get Collider Node
		# Wenn Spieler getroffen und Cooldown vorbei ist
		if collider.is_in_group("Player") and bite_cooldown <= Time.get_ticks_msec():
			animation.play("Attack")                          # Angriff-Animation
			collider.take_damage(25)                          # Schaden anwenden
			bite_cooldown = Time.get_ticks_msec() + 1000      # 1 Sekunde Biss-Cooldown
			attack_animation_cooldown = Time.get_ticks_msec() + 200  # Animation kurz blocken
