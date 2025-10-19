extends CharacterBody2D

#Ich konnte nicht wirklich alles komentieren, weil ich auch viel trial and error hatte
#also habe ich Chat GPT den code kommentieren lassen du findest es under Script/Zombie - Chat-gpt

#@onrady läde diese [var] erst wenn alles geladen hat um zu verhindern das etwas übersehen wird
#was genau die [var]'s speichern habe ich auch noch nicht ganz verstanden 
#print(ray_cast_left) hat diesen output RayCast_left:<RayCast2D#53066336358> 
@onready var ray_cast_right: RayCast2D = $RayCast_right
@onready var ray_cast_left: RayCast2D = $RayCast_left
@onready var animation: AnimatedSprite2D = $Animation
@onready var vision_hitbox: CollisionShape2D = $vision/vision_hitbox
@onready var hitbox: CollisionShape2D = $Hitbox
@onready var bite_timer: Timer = $bite_timer
@onready var ray_cast_bite_player: RayCast2D = $RayCast_bite_player
@onready var health_bar: ProgressBar = $HealthBar


#Zum start werden Variablen [var], Constanten [const], und ? betimmt
#diese können von überall im code angesprochen werden und verwendet werden. 
#Bedeutung von [:] & [=], 
#[=] weist einer Variablen einen Wert zu.
#var x = 10 <--- diesem fall wäre x eine int 
#print(x) ---> output ist 10
#nur kann ich jetzt auch sagen 
# x = true nun wäre x ein bool der nur 0 oder 1 bzw. wahr [true] oder falsch [false] annehmen kann. 
# um dass zu verhindern schreiben wir [var x := 10] das ist kurz für [var x :int = 10] Godot findet selber herraus um welche art es sich handelt. 
# [:] und [=] haben auch noch andere anwendungen auf die ich später zurück kommen werde


var is_alive := true 
var health := 100
var damage := 50
var random_movement_cooldown: = 0			#diese var wird in _idle_and_move() verwendet 
var is_walking := true
var direction := 1
var speed := 50
var player_visible := false
var chase_player := false
var remove_object_timer := 0 
var player_in_hitbox := false
var attack_animation_cooldown := 0
var bite_cooldown := 0
# die habe ich auch noch nicht 100% verstanden
var target: Player
var player_in_hitbox_body: Node = null

#Aufbau einer Funktion
#func _ready() -> void:
	#pass	<--- bedutete das es nichts macht 
#Es gibt eingebaute und Selbst bestimmte Funktionen
#Wenn die Funktion nur von der Klasse aufgerufen werden soll (privat) packen wir ein[_]
#an den anfang [ready()] -> [_ready()]
#die () ist dafür das werte an die Funktion zu übergeben, Funktionen können nur mir dem am Anfang bestimten 
#und übergebenden werten Arbeiten. Wenn ich also in _ready() _do_whatever() aufrufe und in _ready() habe ich 
#var do_that := "whatever" und damit soll _do_whatever() arbeiten muss es so [_do_whatever(do_that)] übergeben werden. 
#
#das []-> void] zeigt welchen output eine Funktion hat. [void,int,bool,string,float,double,etc.], [void] bedeutet hierbei das es keinen Output hat

# wird ein mal aufgerufen wenn die Szene geladen wird. 
func _ready() -> void:
	#auch hier bin ich noch nicht 100% aber im grunde verbinden wir hier eigenschaften von Klassen/Objekten mit unserem code
	#wenn ein körper in [vision] kommt oder verläst wird die jeweilige funktion aufgerufen "_on_vision_body_entered" oder "_on_vision_body_exited"
	# der Grund warum bei dir Vision nicht ging, ist ein wenig Komplex aber im grunde ist es auf eine schlechte Struktur in unserem Projekt zurück zu führen 
	$vision.connect("body_entered", Callable(self, "_on_vision_body_entered"))
	$vision.connect("body_exited", Callable(self, "_on_vision_body_exited"))
	health_bar.max_value = health
# wird normalerweies 60mal pro sekunde aufgerufen, meist für Physik und Movement verwendet. 
func _physics_process(delta: float) -> void:
	health_bar.value = health
	if not is_alive:	# Ein einfacher weg zu verhindern das nach dem Tot noch weitere sachen im code passieren 
		return
	if not is_on_floor():
		velocity += get_gravity() * delta

# wird pro frame aufgerufen, kann für viels verwendet werden. zb. Animation
func _process(delta: float) -> void:
	if not is_alive:	# Ein einfacher weg zu verhindern das nach dem Tot noch weitere sachen im code passieren 
		return
		
	_idle_and_move()
	_walking()
	_chasing_player()
	_handle_direction()
	_check_for_bite()
	
	move_and_slide()		#das ist ein functions aufruf von GoDot, nicht 100% sicher was er macht aber er sollte veränderung in der bewegung übernehmen

#Eigen Definierte Functionen. 

#Diese Funktion soll den Zombie zufälligig entweder bewegen oder idel stehen lassen.
func _idle_and_move():
	if attack_animation_cooldown > Time.get_ticks_msec(): return
	
	if chase_player: return
	if velocity.x > 0:
		animation.play("Walk")
	elif velocity.x == 0:
		animation.play("Idle")
	if random_movement_cooldown < Time.get_ticks_msec():
		random_movement_cooldown += 5000	#setzt 5 sec auf den cooldown, sodas alle 5 sec es erneut per zufall zwischen idel und walk wählt
		var random_number := randf()		#randf() erstellt einen float zwischen 0 und 1 randi_range(1,99) einen zufällige zahl zwischen 1 und 99
		if random_number >= 0.5:
			animation.play("Walk")
			is_walking = true
		else:
			animation.play("Idle")
			is_walking = false

func _walking():
	if not is_walking: return
	if attack_animation_cooldown > Time.get_ticks_msec(): return
	
	# to do chat gpt hat mich dafür geroastet
	# wenn es so implementiert ist kann es fehler geben
	velocity.x = direction * speed
	#if direction == -1:
		#position.x += speed
	#elif direction == 1:
		#position.x -= speed
		
func _handle_direction():
	
	# Ray_cast kümmert sich dadrum dass der Zombie nicht in objekte reinläuft 
	if ray_cast_left.is_colliding():
		direction = 1
	elif ray_cast_right.is_colliding():
		direction = -1
	
	# Verädnert die Richtung der animation bei richtungswechel des Zombies
	# es könnte auch oben eingebaut werden aber so ist es sicher, im falle das etwas anderes die richtung beeinflussen sollte
	if direction < 0:
		vision_hitbox.position.x = -100
		ray_cast_bite_player.target_position = Vector2(-20, 0)
		animation.flip_h = true
	elif direction > 0:
		vision_hitbox.position.x = 100
		ray_cast_bite_player.target_position = Vector2(20, 0)
		animation.flip_h = false

func _on_vision_body_entered(body):
	if not is_alive: return
	if body.is_in_group("Player"):
		chase_player = true
		target = body

func _on_vision_body_exited(body):
	if not is_alive: return
	if body.is_in_group("Player"):
		chase_player = false
		target = null
		direction *= 1
		animation.play("Idle")

func _chasing_player():
	if attack_animation_cooldown > Time.get_ticks_msec(): return
	if not chase_player:
		return
	var direction_to_player = sign(target.global_position.x - global_position.x)	
	direction = direction_to_player
	velocity.x = direction * speed * 1.5
	animation.flip_h = direction_to_player > 0
	animation.play("Walk")

func die():
	is_alive = false
	animation.play("Dead")
	hitbox.position.y = 35
	print("zombie is dead")

func take_damage(amount: int):
	if not is_alive: return
	health -= amount
	print("Zombie hit! Health:", health)
	if health <= 0:
		die()


func _check_for_bite():
	if not is_alive: return
	if  ray_cast_bite_player.is_colliding() :
		var collider =  ray_cast_bite_player.get_collider()
		if collider.is_in_group("Player") and bite_cooldown <= Time.get_ticks_msec():
			animation.play("Attack")
			collider.take_damage(25)
			bite_cooldown = Time.get_ticks_msec() + 1000
			attack_animation_cooldown = Time.get_ticks_msec() + 200
			
