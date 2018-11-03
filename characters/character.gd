extends KinematicBody2D

var movespeed = 20
var direction = 0
var velocity = Vector2()

func _ready():
	velocity = Vector2(1, 0)

func _physics_process(delta):
	horizontal = Input.is_action_pressed("ui_right") - Input.is_action_pressed("ui_left")
	move_and_slide(velocity * movespeed)