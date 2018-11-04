extends KinematicBody2D

enum {MODE_DEFEND, MODE_ATTACK}
enum states {NORMAL, PECK, STUNNED, KICK}

var state = states.NORMAL

var mode = MODE_DEFEND setget set_mode

var mode_maxspeeds = [150, 200]
var mode_animspeeds = [5, 8]

var acceleration = 15
var deceleration = 20

var movespeed = 0.0
var maxspeed = mode_maxspeeds[mode]
export var direction = 1

onready var start_pos = position
onready var start_dir = direction

var velocity = Vector2()
var gravity = 15  # Subtracted from the vertical velocity every step
var drop_speed = 20  # Extra gravity that the player can add
var jumpspeed = 475
var on_ground = false

onready var asprite = $AnimatedSprite
onready var attack_up = $AttackDown
onready var attack_down = $AttackUp
onready var up_offset = attack_up.position.x
onready var down_offset = attack_down.position.x
onready var asprite_offset = asprite.offset.x
var can_hit_up = false
var can_hit_down = false
var enemy_up = null
var enemy_down = null
var knockback = Vector2(220, -150)
var h_input = 0
var stun_direction = 1

func _ready():
	attack_up.connect("body_entered", self, "body_event", ['up', true])
	attack_up.connect("body_exited", self, "body_event", ['up', false])
	attack_down.connect("body_entered", self, "body_event", ['down', true])
	attack_down.connect("body_exited", self, "body_event", ['down', false])
	asprite.connect("animation_finished", self, "anim_finished")

func body_event(body, dir, entered):
	if body != self and filename == body.filename:
		if dir == 'up':
			enemy_up = body if entered else null
		if dir == 'down':
			enemy_down = body if entered else null
			
func _input(event):
	if state == states.NORMAL:
		if event.is_action_pressed(Controllers.get_key(self, Controllers.MODE_SWAP)):
			set_mode(1 - mode)
		elif event.is_action_pressed(Controllers.get_key(self, Controllers.BASIC_ATTACK)):
			asprite.playing = true
			if on_ground:
				state = states.PECK
				velocity.x = 0
				h_input = 0
				asprite.animation = 'peck'
			else:
				state = states.KICK
				asprite.animation = 'kick'
				

func _physics_process(delta):
	on_ground = false
	if position.y > 650:
		reset()
	if state == states.NORMAL:
		_movement_input()
		_movement()
		_animate()
	elif state == states.STUNNED:
		_movement()
		if on_ground:
			state = states.NORMAL
		_animate()
	elif state == states.PECK:
		_movement()
		if asprite.frame > 1 and enemy_up != null:
			hit_enemy(enemy_up)
			state = states.NORMAL
	elif state == states.KICK:
		_movement()
		if asprite.frame > 1 and enemy_down != null:
			hit_enemy(enemy_down)
			state = states.NORMAL
	
func _movement_input():
	h_input = (int(Input.is_action_pressed(Controllers.get_key(self, Controllers.MOVE_RIGHT))) 
		- int(Input.is_action_pressed(Controllers.get_key(self, Controllers.MOVE_LEFT))))
		
	asprite.playing = h_input
	
	if Input.is_action_pressed(Controllers.get_key(self, Controllers.DROP)):
		velocity.y += drop_speed
		
	if Input.is_action_just_released(Controllers.get_key(self, Controllers.JUMP)):
		if velocity.y < -jumpspeed / 2:
			velocity.y = -jumpspeed / 2
		
func _movement():
	if state != states.STUNNED:
		if h_input:
			direction = h_input
			# Accelerate
			if movespeed < maxspeed:
				movespeed = min(maxspeed, movespeed + deceleration)
		else:
			# Decelerate
			if movespeed > 0:
				movespeed = max(0, movespeed - deceleration)
		
	velocity.x = movespeed * (h_input if state != states.STUNNED else stun_direction)
	if state != states.STUNNED:
		velocity.x = clamp(velocity.x, -maxspeed, maxspeed)
	velocity.y += gravity
	
	move_and_slide(velocity)
	
	if get_slide_count():
		var collision = get_slide_collision(get_slide_count() - 1)
		
		if collision:
			if collision.normal == Vector2(0, -1):
				velocity.y = 0
				on_ground = true
				
				if Input.is_action_just_pressed(Controllers.get_key(self, Controllers.JUMP)):
					velocity.y = -jumpspeed
					
			elif collision.normal == Vector2(0, 1):
				velocity.y = 0
	
func _animate():
	if velocity.x != 0:
		if on_ground:
			asprite.animation = 'walk'
	else:
		if on_ground:
			asprite.animation = 'idle'
			
	if not on_ground:
		if velocity.y > 0:
			asprite.animation = 'down'
		else:
			asprite.animation = 'up'
			
	asprite.offset.x = asprite_offset * direction
	asprite.flip_h = direction == -1
	attack_up.position.x = up_offset * direction
	attack_down.position.x = down_offset * direction
					
func set_mode(m):
	mode = m
	maxspeed = mode_maxspeeds[mode]
	asprite.frames.set_animation_speed('walk', mode_animspeeds[mode])
	
func anim_finished():
	if asprite.animation == 'peck':
		state = states.NORMAL
	elif asprite.animation == 'kick':
		state = states.NORMAL
		
func hit_enemy(enemy):
	enemy.movespeed = knockback.x
	enemy.stun_direction = direction
	enemy.direction = -direction
	enemy.velocity.y = knockback.y
	enemy.state = states.STUNNED
	
func reset():
	for x in Controllers.characters:
		x.position = x.start_pos
		x.direction = x.start_dir