extends CharacterBody2D


const SPEED = 100.0
const JUMP_VELOCITY = -100.0

const active_mask = 0 #0 = nothing, 1 = sword, 2 = ? 

#Ich weiß noch nicht was der Spieler geanau machen soll also ist das erst mal so 


#wählt welche maske ist aktive

func _physics_process(delta: float) -> void:
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
	#attacks 
	if Input.is_action_just_pressed("attack"):
		print("attack")
		
	#pick mask/item up 
	if Input.is_action_just_pressed("pickup"):	#needs a hitbox to pickup 
		print("pickup")
	
	
