extends KinematicBody2D

enum {MODE_DEFEND, MODE_ATTACK}
enum states {NORMAL, PECK, STUNNED, KICK, ATTACK}

var state = states.NORMAL

var mode = MODE_DEFEND setget set_mode

var mode_maxspeeds = [150, 200]
var mode_animspeeds = [5, 8]

var health = 10
var max_health = 10

var acceleration = 15
var deceleration = 20

var movespeed = 0.0
var maxspeed = mode_maxspeeds[mode]
export var direction = 1
export(SpriteFrames) var frames

onready var start_pos = position
onready var start_dir = direction

var velocity = Vector2()
var gravity = 15  # Subtracted from the vertical velocity every step
var drop_speed = 20  # Extra gravity that the player can add
var jumpspeed = 425
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
var attack_velocity = Vector2(400, -100)

onready var attack_timer = $Attack

func _ready():
	attack_up.connect("body_entered", self, "body_event", ['up', true])
	attack_up.connect("body_exited", self, "body_event", ['up', false])
	attack_down.connect("body_entered", self, "body_event", ['down', true])
	attack_down.connect("body_exited", self, "body_event", ['down', false])
	asprite.connect("animation_finished", self, "anim_finished")
	asprite.connect("frame_changed", self, "anim_frame_change")
	attack_timer.connect("timeout", self, "attack_timeout")
	asprite.frames = frames

func body_event(body, dir, entered):
	if body != self and filename == body.filename:
		if dir == 'up':
			enemy_up = body if entered else null
		if dir == 'down':
			enemy_down = body if entered else null
			
func _input(event):
	if state == states.NORMAL:
		if mode == 0 and event.is_action_pressed(Controllers.get_key(self, Controllers.MODE_SWAP)):
			set_mode(1)
		elif event.is_action_pressed(Controllers.get_key(self, Controllers.BASIC_ATTACK)):
			asprite.playing = true
			if on_ground and mode == 0:
				state = states.PECK
				velocity.x = 0
				h_input = 0
				asprite.animation = 'peck'
			elif mode == 0:
				state = states.KICK
				asprite.animation = 'kick'
				
func _physics_process(delta):
	if health <= 0:
		get_parent().reset()
	on_ground = false
	if position.y > 650:
		get_parent().reset()
	if state == states.NORMAL:
		_movement_input()
		_movement()
		_animate()
	elif state == states.STUNNED:
		if mode == 0:
			asprite.animation = 'defendhurt'
		else:
			asprite.animation = 'attackhurt'
		_movement()
		if on_ground:
			state = states.NORMAL
		_flip()
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
	elif state == states.ATTACK:
		_movement()
		_flip()
		if asprite.frame > 4 and enemy_up != null:
			hit_enemy(enemy_up)
			state = states.NORMAL
			set_mode(0)
			attack_timer.stop()
	
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
	if state != states.STUNNED and state != states.ATTACK:
		if h_input:
			direction = h_input
			# Accelerate
			if movespeed < maxspeed:
				movespeed = min(maxspeed, movespeed + deceleration)
		else:
			# Decelerate
			if movespeed > 0:
				movespeed = max(0, movespeed - deceleration)
		
	velocity.x = movespeed * (h_input if state != states.STUNNED and state != states.ATTACK else stun_direction)
	if state != states.STUNNED and state != states.ATTACK:
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
			if mode == 0:
				asprite.animation = 'defendwalk'
			else:
				asprite.animation = 'attackwalk'
	else:
		if on_ground:
			if mode == 0:
				asprite.animation = 'defendidle'
			else:
				asprite.animation = 'attackidle'
			
	if not on_ground:
		if velocity.y > 0:
			if mode == 0:
				asprite.animation = 'defenddown'
			else:
				asprite.animation = 'attackdown'
		else:
			if mode == 0:
				asprite.animation = 'defendup'
			else:
				asprite.animation = 'attackup'
			
	_flip()
			
func _flip():
	asprite.offset.x = asprite_offset * direction
	asprite.flip_h = direction == -1
	attack_up.position.x = up_offset * direction
	attack_down.position.x = down_offset * direction
					
func set_mode(m):
	mode = m
	maxspeed = mode_maxspeeds[mode]
	if mode == 1:
		state = states.ATTACK
		attack_timer.start()
		movespeed = 0
		asprite.playing = true
		asprite.animation = 'attack'
	
func anim_finished():
	if asprite.animation == 'peck':
		state = states.NORMAL
	elif asprite.animation == 'kick':
		state = states.NORMAL
	elif asprite.animation == 'attack':
		state = states.NORMAL
		
func anim_frame_change():
	if state == states.ATTACK and asprite.frame == 4:
		movespeed = attack_velocity.x
		velocity.y = attack_velocity.y
		stun_direction = direction
		
func hit_enemy(enemy):
	if mode == 0:
		enemy.health -= 1 if enemy.mode == 0 else 2
	else:
		enemy.health -= 2 if enemy.mode == 0 else 4
	get_parent().update_gui()
	enemy.movespeed = knockback.x
	enemy.stun_direction = direction
	enemy.direction = -direction
	enemy.velocity.y = knockback.y
	enemy.state = states.STUNNED
		
func attack_timeout():
	state = states.NORMAL
	set_mode(0)