extends CharacterBody2D
class_name Player
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sword_hitbox: CollisionShape2D = $sword_hitbox
@onready var visible_hitbox: Sprite2D = $sword_hitbox/Visible_hitbox


const SPEED := 200.0
const JUMP_VELOCITY := -300.0
const active_mask := 0 #0 = nothing, 1 = sword, 2 = ? 

var health := 100	#to be changed 

var cooldown_time := 0.5 # Sekunden
var last_action_time := -cooldown_time
var is_allive := true


#Ich weiß noch nicht was der Spieler geanau machen soll also ist das erst mal so 


#wählt welche maske ist aktive


func _physics_process(delta: float) -> void:
	if not is_allive:	#idk if it works 
		return
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
		#flip the sprite
	if direction > 0:
		animated_sprite.flip_h = false	
	elif direction < 0:
		animated_sprite.flip_h = true
	
	#play animations
	if is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")
		
		


# merkt sich einen Zeitpunkt wenn eine Attacke ausgeführt wurde, 
# wenn diese in dem Zeitraum von cooldown_timer passiert
# wird diese ignoriert FUCK CHAT GPT 

func _process(delta):
	if Input.is_action_just_pressed("attack"):
		var current_time = Time.get_ticks_msec() / 1000.0
		if current_time - last_action_time >= cooldown_time:
			do_action()
			last_action_time = current_time
	
	if Input.is_action_just_pressed("pickup"):
		print("pickup")


func do_action():
	sword_hitbox.disabled = false 
	visible_hitbox.disable = false
	print("Attack!")
	
# hier deine Aktion z. B. Animation abspielen, Projektil schießen usw.

	
	
	
	
