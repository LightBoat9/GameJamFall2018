extends Node

enum {MOVE_RIGHT, MOVE_LEFT, DROP, JUMP, BASIC_ATTACK, MODE_SWAP}

var keyboard_1 = ['k1_move_right', 'k1_move_left', 'k1_drop', 'k1_jump', 'k1_basic_attack', 'k1_mode_swap']
var keyboard_2 = ['c1_move_right', 'c1_move_left', 'c1_drop', 'c1_jump', 'c1_basic_attack', 'c1_mode_swap']

var binds = [keyboard_1, keyboard_2]
var characters = []

func get_key(character, index):
	if not character in characters:
		characters.append(character)
	return binds[characters.find(character)][index]
	
func reset():
	characters.clear()