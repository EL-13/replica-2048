extends Node2D


# ========== VARIABLES (TILES) ==========
# tile scenes
@export var scene_1: PackedScene
@export var scene_2: PackedScene
@export var scene_3: PackedScene
@export var scene_4: PackedScene
@export var scene_5: PackedScene
@export var scene_6: PackedScene
@export var scene_7: PackedScene
@export var scene_8: PackedScene
@export var scene_9: PackedScene
@export var scene_10: PackedScene
@export var scene_11: PackedScene
@export var scene_12: PackedScene
@export var scene_13: PackedScene
@export var scene_14: PackedScene
@export var scene_15: PackedScene
@export var scene_16: PackedScene

# dictionary for scenes numbering
@onready var scenes_dict: Dictionary = {1:scene_1, 2:scene_2, 3:scene_3, 4:scene_4, \
										5:scene_5, 6:scene_6, 7:scene_7, 8:scene_8, \
										9:scene_9, 10:scene_10, 11:scene_11, 12:scene_12, \
										13:scene_13, 14:scene_14, 15:scene_15, 16:scene_16}

# dictionary for tile backgrounds numbering
@onready var tile_backgrounds: Dictionary = {0:"TB0", 1:"TB1", 2:"TB2", 3:"TB3", \
											 4:"TB4", 5:"TB5", 6:"TB6", 7:"TB7", \
											 8:"TB8", 9:"TB9", 10:"TB10", 11:"TB11", \
											 12:"TB12", 13:"TB13", 14:"TB14", 15:"TB15"}

var new_tile_pool: Array = [1, 2]		# pool for random selection of new tile
# ========================================


# ========== VARIABLES (BOARD) ==========
# current board status
# used to check if any of the cells are occupied with tile
var board_status: Array = [0, 0, 0, 0, \
						   0, 0, 0, 0, \
						   0, 0, 0, 0, \
						   0, 0, 0, 0]

var prev_board_status: Array			# previous board status
var empty_cells: Array = []				# array of empty cells on board
# ========================================


# ========== CONSTANTS ==========
const UP: Array = [0, 1, 2, 3]			# array of the top row indices in board_status
const DOWN: Array = [12, 13, 14, 15]	# array of the bottom row indices in board_status
const LEFT: Array = [0, 4, 8, 12]		# array of the left column indices in board_status
const RIGHT: Array = [3, 7, 11, 15]		# array of the right column indices in board_status

const DEFAULT_X: float = 576.0			# default window size (horizontal)
const DEFAULT_Y: float = 1024.0			# default window size (vertical)
# ========================================


# ========== VARIABLES (WINDOW / VIEWPORT) ==========
var screen_x: int						# viewport size (horizontal)
var screen_y: int						# viewport size (vertical)
var scale_x: float						# scale in x-direction
var scale_y: float						# scale in y-direction
var scale_final: Vector2				# scale vector
# ========================================


# ========== VARIABLES (GAME) ==========
var score: int							# game score
var anc: int = 0						# anchor, index for comparison of tile status
var can_move: bool						# used to determine whether an user input can be registered
var game_over: bool						# indicates if the game is playable
# ========================================


# ========== VARIABLES (CONTROLS) ==========
var length: int = 50					# threshold to determine if the player is swiping
var swiping: bool = false				# indicates if the player is swiping
var startPos: Vector2					# start position of which the player pressed to swipe
var curPos: Vector2						# current position of which the player is pressing
var threshold: int = 25					# distance threshold to determine swipe direction
# ========================================


# ========== SETUP ==========
# run once whenever the game is loaded
# setup the game
func _ready():
	get_tree().set_auto_accept_quit(false)
	get_tree().get_root().size_changed.connect(resize)
	new_game()

# run once whenever a new game is started
# setup the game board for a new game
func new_game():
	$InstructionsMenu.hide()
	$CreditsMenu.hide()
	$GameOverMenu.hide()
	$ExitMenu.hide()
	calculate_scale()
	adjust_scale()
	reset()
	pick_new_tile()
	pick_new_tile()

# reset the game status and clear the game board 
func reset():
	game_over = false
	score = 0
	update_score()
	
	get_tree().call_group("Tiles", "queue_free")
	board_status = [0, 0, 0, 0, \
					0, 0, 0, 0, \
					0, 0, 0, 0, \
					0, 0, 0, 0]

# resize the game board and assets whenever the game window or viewport size is changed
func resize():
	calculate_scale()
	adjust_scale()
	get_tree().call_group("Tiles", "queue_free")
	for i in range(board_status.size()):
		if board_status[i] != 0:
			var resized_tile = board_status[i]
			var resized_tile_scene = scenes_dict[resized_tile].instantiate()
			place_tile(i, resized_tile_scene, NAN, "sum")
		else: pass

# calculate the scale of which the game board needed to be resized to
func calculate_scale():
	screen_x = get_viewport_rect().size.x
	screen_y = get_viewport_rect().size.y
	scale_x = screen_x / DEFAULT_X
	scale_y = screen_y / DEFAULT_Y
	scale_final = Vector2(min(scale_x, scale_y), min(scale_x, scale_y))

# apply the change in size onto the game board and assets
func adjust_scale():
	var scaled_pos_x = (screen_x - (DEFAULT_X * scale_final.x)) / 2
	var scaled_pos_y = (screen_y - (DEFAULT_Y * scale_final.y)) / 2
	
	$Background.scale = scale_final
	$Background.position.x = scaled_pos_x
	$Background.position.y = scaled_pos_y
	
	var scale_scenes = get_tree().get_nodes_in_group("Scale2")
	for i in scale_scenes:
		var scene_panel = i.get_node("Panel")
		scene_panel.scale = scale_final
		scene_panel.position.x = scaled_pos_x
		scene_panel.position.y = scaled_pos_y
# ========================================


# ========== RECURRING PROCESS ==========
# listens for user input
# if the game is playable, proceed to check the type of input
func _process(_delta):
	if game_over == false and can_move == true:
		check_input()
	else: pass

# checks the type of input and call functions accordingly
func check_input():
	if Input.is_action_just_pressed("up"):
		move_up()
		move_and_add()
	elif Input.is_action_just_pressed("down"):
		move_down()
		move_and_add()
	elif Input.is_action_just_pressed("left"):
		move_left()
		move_and_add()
	elif Input.is_action_just_pressed("right"):
		move_right()
		move_and_add()
	elif Input.is_action_just_pressed("press"):
		if swiping == false:
			swiping = true
			startPos = get_global_mouse_position()
		else: pass
	elif Input.is_action_pressed("press"):
		if swiping == true:
			curPos = get_global_mouse_position()
			if startPos.distance_to(curPos) >= length:
				check_swipe_direction()
			else: pass
		else: pass
	else:
		swiping = false
# ========================================


# ========== TILE PLACEMENTS ==========
# randomly pick a new tile from the new_tile_pool
func pick_new_tile():
	var i_new_tile = randi() % new_tile_pool.size()
	var new_tile_value = new_tile_pool[i_new_tile]
	generate_tile(NAN, new_tile_value, "new")

# instantiate scene of a tile
func generate_tile(tile_pos, tile_value, tile_type):
	var scene_name = scenes_dict[tile_value]
	var tile_scene = scene_name.instantiate()
	place_tile(tile_pos, tile_scene, tile_value, tile_type)

# position the instantiated tile scene accordingly
# if the tile is a new tile, position it on any slot which is empty and update board_status
# if the tile is not a new tile, position it on the predefined slot
# restrict input registration for the duration set in Timer
func place_tile(tile_pos, tile_scene, tile_value, tile_type):
	if tile_type == "new":
		for i in range(board_status.size()):
			if board_status[i] == 0:
				empty_cells.append(i)
			else:
				i += 1
		
		var i_empty = randi() % empty_cells.size()
		var empty_cell = empty_cells[i_empty]
		var gp_tile_background = $Background/TileBackground.get_node(tile_backgrounds[empty_cell]).global_position
		tile_scene.global_position = gp_tile_background
		add_child(tile_scene)
		
		board_status[empty_cell] += tile_value
		empty_cells.clear()
	
	elif tile_type == "sum":
		var gp_tile_background = $Background/TileBackground.get_node(tile_backgrounds[tile_pos]).global_position
		tile_scene.global_position = gp_tile_background
		add_child(tile_scene)
	else: pass
	
	can_move = false
	$Timer.start()
# ========================================


# ========== INPUT REGISTRATION ==========
# check swipe direction and call function accordingly
func check_swipe_direction():
	if abs(startPos.y - curPos.y) <= threshold:
		swiping = false
		horizontal_swipe()
	elif abs(startPos.x - curPos.x) <= threshold:
		swiping = false
		vertical_swipe()
	else: pass

# check if the swipe direction is left or right and call function accordingly
func horizontal_swipe():
	if startPos.x > curPos.x:
		move_left()
		move_and_add()
	elif startPos.x < curPos.x:
		move_right()
		move_and_add()
	else: pass

# check if the swipe direction is up or down and call function accordingly
func vertical_swipe():
	if startPos.y > curPos.y:
		move_up()
		move_and_add()
	elif startPos.y < curPos.y:
		move_down()
		move_and_add()
	else: pass
# ========================================


# ========== INPUT EXECUTION ==========
# called when "up" was input
# for each element in the UP array, initiate the check_first function
func move_up():
	for i in UP:
		var i_temp = i
		var diff = 4
		check_first(i_temp, anc, diff)

# called when "down" was input
# for each element in the DOWN array, initiate the check_first function
func move_down():
	for i in DOWN:
		var i_temp = i
		var diff = -4
		check_first(i_temp, anc, diff)

# called when "left" was input
# for each element in the LEFT array, initiate the check_first function
func move_left():
	for i in LEFT:
		var i_temp = i
		var diff = 1
		check_first(i_temp, anc, diff)

# called when "right" was input
# for each element in the RIGHT array, initiate the check_first function
func move_right():
	for i in RIGHT:
		var i_temp = i
		var diff = -1
		check_first(i_temp, anc, diff)

# called after the whole board was checked
# moves the tiles according to the updated board_status
# if the board status changed,
# clears the board and add tiles accordingly
# else if board status remain unchanged, and no more empty cell on the board,
# calls game_over function
func move_and_add():
	if board_status != prev_board_status:
		get_tree().call_group("Tiles", "queue_free")
		for i in range(board_status.size()):
			if board_status[i] > 0:
				generate_tile(i, board_status[i], "sum")
			else: pass
		pick_new_tile()
		prev_board_status = board_status.duplicate()
		score += 10
	elif board_status == prev_board_status:
		if board_status.find(0) == -1:
#			end_game()
			check_game_over()
		else: pass
	else: pass
	update_score()
# ========================================


# ========== BOARD STATUS ==========
# checks the first element of the row or column
# moves and updates board_status if necessary
func check_first(i_temp, anc, diff):
	if board_status[i_temp] == 0:																	# 0xxx ----- 1
		check_second(i_temp, anc, diff)
	elif board_status[i_temp] > 0:																	# axxx ----- 2
		anc += 1
		check_second(i_temp, anc, diff)
	else: pass

# checks the second element of the row or column
# moves and updates board_status if necessary
func check_second(i_temp, anc, diff):
	if board_status[i_temp + diff] == 0:															# x0xx ----- 1, 2
		check_third(i_temp, anc, diff)
	elif board_status[i_temp + diff] > 0:															# xaxx
		if anc == 0:																				# 0axx ----- 3
			board_status[i_temp] = board_status[i_temp + diff]
			board_status[i_temp + diff] = 0
			anc += 1
			check_third(i_temp, anc, diff)
		elif anc == 1:																				# ayxx
			if board_status[i_temp + diff] != board_status[i_temp]:									# abxx ----- 4
				anc += 1
				check_third(i_temp, anc, diff)
			elif board_status[i_temp + diff] == board_status[i_temp]:								# aaxx ----- 5
				board_status[i_temp] += 1
				board_status[i_temp + diff] = 0
				anc += 1
				check_third(i_temp, anc, diff)
			else: pass
		else: pass
	else: pass

# checks the third element of the row or column
# moves and updates board_status if necessary
func check_third(i_temp, anc, diff):
	if board_status[i_temp + (2 * diff)] == 0:														# xx0x
		check_fourth(i_temp, anc, diff)
	elif board_status[i_temp + (2 * diff)] > 0:														# xxax
		if anc == 0:																				# 00ax
			board_status[i_temp] = board_status[i_temp + (2 * diff)]
			board_status[i_temp + (2 * diff)] = 0
			anc += 1
			check_fourth(i_temp, anc, diff)
		elif anc == 1:																				# 0ayx or a0yx
			if board_status[i_temp + (2 * diff)] != board_status[i_temp]:							# 0abx or a0bx
				board_status[i_temp + (anc * diff)] = board_status[i_temp + (2 * diff)]
				board_status[i_temp + (2 * diff)] = 0
				anc += 1
				check_fourth(i_temp, anc, diff)
			elif board_status[i_temp + (2 * diff)] == board_status[i_temp]:							# 0aax or a0ax
				board_status[i_temp] += 1
				board_status[i_temp + (2 * diff)] = 0
				anc += 1
				check_fourth(i_temp, anc, diff)
			else: pass
		elif anc == 2:																				# abyx or aayx
			if board_status[i_temp + ((anc - 1) * diff)] == 0:										# aayx
				board_status[i_temp + ((anc - 1) * diff)] = board_status[i_temp + (2 * diff)]
				board_status[i_temp + (2 * diff)] = 0
				check_fourth(i_temp, anc, diff)
			elif board_status[i_temp + ((anc - 1) * diff)] > 0:										# abyx
				if board_status[i_temp + (2 * diff)] != board_status[i_temp + ((anc - 1) * diff)]:	# abcx
					anc += 1
					check_fourth(i_temp, anc, diff)
				elif board_status[i_temp + (2 * diff)] == board_status[i_temp + ((anc - 1) * diff)]:# abbx
					board_status[i_temp + ((anc - 1) * diff)] += 1
					board_status[i_temp + (2 * diff)] = 0
					anc += 1
					check_fourth(i_temp, anc, diff)
				else: pass
			else: pass
		else: pass
	else: pass

# checks the last element of the row or column
# moves and updates board_status if necessary
func check_fourth(i_temp, anc, diff):
	if board_status[i_temp + (3 * diff)] == 0:														# xxx0
		pass
	elif board_status[i_temp + (3 * diff)] > 0:														# xxxy
		if anc == 0:																				# 000a
			board_status[i_temp] = board_status[i_temp + (3 * diff)]
			board_status[i_temp + (3 * diff)] = 0
		elif anc == 1:																				# a00y, 0a0y, 00ay
			if board_status[i_temp + (3 * diff)] != board_status[i_temp]:							# a00b, 0a0b, 00ab
				board_status[i_temp + (anc * diff)] = board_status[i_temp + (3 * diff)]
				board_status[i_temp + (3 * diff)] = 0
			elif board_status[i_temp + (3 * diff)] == board_status[i_temp]:							# a00a, 0a0a, 00aa
				board_status[i_temp] += 1
				board_status[i_temp + (3 * diff)] = 0
			else: pass
		elif anc == 2:																				# 0aby, a0by, 0aay, a0ay, aaby
			if board_status[i_temp + ((anc - 1) * diff)] == 0:										# 0aay, a0ay
				board_status[i_temp + ((anc - 1) * diff)] = board_status[i_temp + (3 * diff)]
				board_status[i_temp + (3 * diff)] = 0
			elif board_status[i_temp + ((anc - 1) * diff)] > 0 :									# 0aby, a0by, aaby
				if board_status[i_temp + (3 * diff)] != board_status[i_temp + ((anc - 1) * diff)]:	# 0abc, a0bc, aabc
					board_status[i_temp + (anc * diff)] = board_status[i_temp + (3 * diff)]
					board_status[i_temp + (3 * diff)] = 0
				elif board_status[i_temp + (3 * diff)] == board_status[i_temp + ((anc - 1) * diff)]:# 0abb, a0bb, aabb
					board_status[i_temp + ((anc - 1) * diff)] += 1
					board_status[i_temp + (3 * diff)] = 0
				else: pass
			else: pass
		elif anc == 3:																				# abcy, abby
			if board_status[i_temp + ((anc - 1) * diff)] == 0:										# abby
				board_status[i_temp + ((anc - 1) * diff)] = board_status[i_temp + (2 * diff)]
				board_status[i_temp + (2 * diff)] = 0
			elif board_status[i_temp + ((anc - 1) * diff)] > 0:										# abcc, abcd
				if board_status[i_temp + (3 * diff)] != board_status[i_temp + ((anc - 1) * diff)]:	# abcd
					pass
				elif board_status[i_temp + (3 * diff)] == board_status[i_temp + ((anc - 1) * diff)]:# abcc
					board_status[i_temp + ((anc - 1) * diff)] += 1
					board_status[i_temp + (3 * diff)] = 0
				else: pass
		else: pass
	else: pass
	
	anc = 0
# ========================================


# ========== GAME STATUS ==========
# update score labels on HUD and GameOverMenu
func update_score():
	$HUD/Panel/ScoreLabel.text = "Score: " + str(score)
	$GameOverMenu/Panel/ScoreLabel.text = "Score: " + str(score)

# check if any other move could be made
# if no move is possible, end game
func check_game_over():
	var count: int = 0
	move_up()
	if board_status == prev_board_status:
		count += 1
	else:
		board_status = prev_board_status.duplicate()
	move_down()
	if board_status == prev_board_status:
		count += 1
	else:
		board_status = prev_board_status.duplicate()
	move_left()
	if board_status == prev_board_status:
		count += 1
	else:
		board_status = prev_board_status.duplicate()
	move_right()
	if board_status == prev_board_status:
		count += 1
	else:
		board_status = prev_board_status.duplicate()
	
	if count == 4:
		end_game()
	else: pass

# end the game
# show the GameOverMenu
func end_game():
	game_over = true
	$Timer.stop()
	can_move = false
	get_tree().paused = true
	$GameOverMenu.show()
	$HUD.hide()
# ========================================


# ========== CUES / SIGNALS ==========
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().paused = true
		$HUD.hide()
		$InstructionsMenu.hide()
		$CreditsMenu.hide()
		$GameOverMenu.hide()
		$ExitMenu.show()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_tree().paused = true
		$HUD.hide()
		$InstructionsMenu.hide()
		$CreditsMenu.hide()
		$GameOverMenu.hide()
		$ExitMenu.show()
	else: pass

func _on_timer_timeout():
	can_move = true

func _on_hud_credits():
	get_tree().paused = true 
	$CreditsMenu.show()
	$HUD.hide()

func _on_hud_instructions():
	get_tree().paused = true 
	$InstructionsMenu.show()
	$HUD.hide()

func _on_hud_restart():
	new_game()

func _on_instructions_menu_resume():
	get_tree().paused = false 
	$InstructionsMenu.hide()
	$HUD.show()

func _on_credits_menu_close():
	get_tree().paused = false 
	$CreditsMenu.hide()
	$HUD.show()

func _on_game_over_menu_restart():
	get_tree().paused = false
	$HUD.show()
	new_game()

func _on_exit_menu_cancel():
	get_tree().paused = false 
	$ExitMenu.hide()
	$HUD.show()

func _on_exit_menu_exit():
	get_tree().quit()
# ========================================
