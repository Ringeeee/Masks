extends Area2D
@onready var timer: Timer = $Timer
@onready var character_body_2d: CharacterBody2D = $"."


func _on_body_entered(body: Node2D) -> void:
	
	print ("you are dead")
	timer.start()


func _on_timer_timeout() -> void:
	get_tree().reload_current_scene()
