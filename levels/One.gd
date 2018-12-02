extends Node2D

onready var player1 = $Player1
onready var player2 = $Player2

var front = load("res://birdb_bar1.png")
var back = load("res://birdb_bar2.png")

var p1_bar = []
var p2_bar = []

func _ready():
	for x in range(player1.max_health):
		var inst = Sprite.new()
		inst.scale = Vector2(0.25, 0.25)
		inst.texture = back
		add_child(inst)
		inst.position = Vector2(16 + 16 * x, 16)
		p1_bar.append(inst)
	
	for x in range(player2.max_health):
		var inst = Sprite.new()
		inst.scale = Vector2(0.25, 0.25)
		inst.texture = back
		add_child(inst)
		inst.position = Vector2(512 - (16 + 16 * x), 16)
		p2_bar.append(inst)
	update_gui()
		
func update_gui():
	for x in range(player1.max_health):
		if x < player1.health:
			p1_bar[x].texture = front
		else:
			p1_bar[x].texture = back
			
	for x in range(player2.max_health):
		if x < player2.health:
			p2_bar[x].texture = front
		else:
			p2_bar[x].texture = back
			
func reset():
	for x in Controllers.characters:
		player1.health = player1.max_health
		player2.health = player2.max_health
		update_gui()
		player1.state = player1.states.NORMAL
		player2.state = player2.states.NORMAL
		x.position = x.start_pos
		x.direction = x.start_dir