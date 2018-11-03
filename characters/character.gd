extends KinematicBody2D

enum {MODE_DEFEND, MODE_ATTACK}

var mode = MODE_DEFEND setget set_mode

var mode_speeds = [10, 15]
var mode_animations = ['defend', 'attack']

var movespeed = mode_speeds[mode]
var direction = 0

var velocity = Vector2()
var gravity = 1
var jumpspeed = 20

onready var asprite = $AnimatedSprite

func _physics_process(delta):
	if Input.is_action_just_pressed("mode_attack"):
		set_mode(1 - mode)
		
	var direction = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	
	velocity.x = direction * movespeed
	velocity.y = velocity.y + gravity
	move_and_slide(velocity * movespeed)
	
	# Update sprites flip when direction is not 0
	if direction:
		asprite.flip_h = direction == -1
	
	if get_slide_count():
		var collision = get_slide_collision(get_slide_count() - 1)
		
		if collision and collision.normal == Vector2(0, -1):
			velocity.y = 0
			
			if Input.is_action_just_pressed("jump"):
				velocity.y = -jumpspeed
				
func set_mode(m):
	mode = m
	movespeed = mode_speeds[mode]
	asprite.animation = mode_animations[mode]