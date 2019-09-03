extends Node2D

var player
var feet
export var next_level = ""
var jump_height = 600
var move_speed = 300
var coins = 0 setget set_coins
var lives = 5 setget set_lives
var left = false setget set_left
var crate
var timer
var time = 0 setget set_time
var last_level = false

var can_attack = true
var enemies setget set_enemies

onready var root = get_tree().get_root()
onready var fall_line = get_node("Fall line")
onready var target = get_node("Target")
onready var target_pos = target.get_global_pos()
var interface = preload("res://Scenes/Interface.tscn").instance()
var crate_scene = preload("res://Scenes/Crate.tscn")
var trump_scene = preload("res://Scenes/Trump.tscn")
var target_scene = preload("res://Scenes/Target.tscn")

#empty variables
var trump
var highscores = {}

func _ready():
	highscores = Scene_switcher.load_game()
	
	timer = Timer.new()
	timer.set_wait_time(1)
	timer.connect("timeout", self, "on_timeout")
	add_child(timer)
	timer.start()
	
	remove_child(target)
	
	if Scene_switcher.get_param("coins"): self.coins = Scene_switcher.get_param("coins")
	if Scene_switcher.get_param("time"): self.time = Scene_switcher.get_param("time")
	if Scene_switcher.get_param("lives"): self.lives = Scene_switcher.get_param("lives")
	
	add_child(interface)
	player = get_node("Player")
	set_fixed_process(true)
	set_process_input(true)
	feet = get_node("Player/feet")
	get_node("Player/left_side").add_exception(player)
	get_node("Player/right_side").add_exception(player)
	player.set_mode(2)
	player.set_contact_monitor(true)
	player.set_max_contacts_reported(1)
	var moving_objects = get_tree().get_nodes_in_group("Moving")
	for object in moving_objects:
		for raycast in [object.get_node("Left_down"), object.get_node("Left_side"), object.get_node("Right_down"), object.get_node("Right_side")]:
			raycast.add_exception(object)
	self.enemies = get_tree().get_nodes_in_group("Enemy").size()
	
	if next_level == "Final": last_level = true
	interface.get_node("End/AddToHighscore").connect("pressed", self, "add_to_highscore")
	

func _fixed_process(delta):
	var colliding_bodies = player.get_colliding_bodies()
	var feet_collider = null
	if feet.is_colliding(): feet_collider = feet.get_collider()
	
	# Direction
	if Input.is_action_pressed("ui_right"):
		player.set_axis_velocity(Vector2(move_speed, 0))
		self.left = false
	if Input.is_action_pressed("ui_left"):
		player.set_axis_velocity(Vector2(-move_speed, 0))
		self.left = true
	
	# Jumping
	if feet_collider and feet_collider.is_in_group("Jumpable"):
		if Input.is_action_pressed("ui_up"):
			player.set_axis_velocity(Vector2(0, -jump_height))
	
	if target in colliding_bodies:
		if last_level:
			end()
			return
		reset()
		Scene_switcher.change_scene(next_level, {"coins":coins, "time":time, "lives":lives})
	
	if feet_collider and feet_collider.is_in_group("Trampoline"):
		player.set_axis_velocity(Vector2(0, -jump_height*feet_collider.jump_modifier))
		if feet_collider.is_in_group("Enemy") and can_attack: 
			feet_collider.lives -= 1
			can_attack = false
	elif not feet_collider: can_attack = true
	
	for body in colliding_bodies:
		if body.is_in_group("Harmful"):
			body.queue_free()
			self.lives -= 1
			if lives <= 0: reset()
	
	var moving_objects = get_tree().get_nodes_in_group("Moving")
	for object in moving_objects:
		if !object.moving: continue
		var left_side = object.get_node("Left_side")
		var left_down = object.get_node("Left_down")
		var right_side = object.get_node("Right_side")
		var right_down = object.get_node("Right_down")
		
		if (left_side.is_colliding() and left_side.get_collider() and !left_side.get_collider().is_in_group("Bullet") and left_side.get_collider() != player) or !left_down.is_colliding():
			object.right = true
			object.left = false 
		elif !right_down.is_colliding() or (right_side.is_colliding() and right_side.get_collider() and !right_side.get_collider().is_in_group("Bullet") and right_side.get_collider() != player):
			object.right = false
			object.left = true
		
		if object.left:
			object.set_axis_velocity(Vector2(-75, 0))
		elif object.right:
			object.set_axis_velocity(Vector2(75, 0))
	
	# Falling
	for object in fall_line.get_overlapping_bodies():
		if object == player: reset()
		else:
			object.queue_free()
	
	if player.get_node("Crates/crate_area").get_overlapping_bodies() != []:
		player.get_node("Crates/crate_sprite").set_modulate(Color(0.629, 0.14, 0.14, 1))
	else:
		player.get_node("Crates/crate_sprite").set_modulate(Color(0.173, 0.148, 0.95, 1))
		

func _input(event):
	if event.is_action_pressed("ui_select"):
		if !player.get_node("Crates").is_visible():
			player.get_node("Crates").set_hidden(false)
		elif player.get_node("Crates/crate_area").get_overlapping_bodies() == []: 
			if crate and weakref(crate).get_ref():
				root.remove_child(crate)
			crate = crate_scene.instance()
			crate.set_global_pos(player.get_node("Crates/crate_sprite").get_global_pos())
			root.add_child(crate)
			player.get_node("Crates").set_hidden(true)
	elif event.is_action_pressed("ui_cancel"):
		player.get_node("Crates").set_hidden(true)
	elif event.is_action_pressed("ui_attack") and coins >= 3:
		trump = trump_scene.instance()
		var pos = Vector2(50, 0)
		if left:
			pos = Vector2(-50, 0)
			trump.right = false
		trump.set_global_pos(player.get_global_pos() + pos)
		add_child(trump)
		self.coins -= 3
	elif event.is_action_pressed("ui_heal") and coins >= 2:
		self.lives += 1
		self.coins -= 2
	elif event.is_action_pressed("ui_cheat"):
		self.lives += 10
		self.coins += 10
		end()

func set_coins(value):
	coins = value
	interface.get_node("coins").set_text("Coins: " + str(coins))

func set_lives(value):
	lives = value
	interface.get_node("lives").set_text("Lives: " + str(lives))

func set_left(b):
	left = b
	if left:
		player.get_node("Crates").set_pos(Vector2(120, -31))
	else:
		player.get_node("Crates").set_pos(Vector2(346, -31))

func set_enemies(value):
	enemies = value
	interface.get_node("enemies").set_text("Enemies: " + str(enemies))
	if enemies == 0:
		target = target_scene.instance()
		target.set_global_pos(target_pos)
		root.add_child(target)
		target.set_owner(root)

func reset():
	if crate and weakref(crate).get_ref(): root.remove_child(crate)
	if weakref(target).get_ref(): root.remove_child(target)
	Scene_switcher.change_scene("res://Scenes/Levels/Level1.tscn")
	enemies = get_tree().get_nodes_in_group("Enemy").size()

func on_timeout():
	self.time += 1

func set_time(value):
	time = value
	interface.get_node("time").set_text("Time: %02d:%02d" % [int(time/60), time%60])

func end():
	interface.get_node("End").set_hidden(false)
	interface.get_node("End/Time").set_text(str(time))

func add_to_highscore():
	var name = interface.get_node("End/Name").get_text()
	if name == "" or name in highscores: return
	highscores[name] = time
	Scene_switcher.save_game(highscores)
	interface.get_node("End").set_hidden(true)
	display_highscore()

func display_highscore():
	var panel = interface.get_node("Highscore")
	for child in panel.get_children(): child.queue_free()
	panel.set_hidden(false)
	var y = 10
	var sorted_scores = highscores.values()
	sorted_scores.sort()
	while sorted_scores.size() > 5: sorted_scores.pop_back()
	var i = 1
	while i < sorted_scores.size():
		if sorted_scores[i] == sorted_scores[i-1]:
			sorted_scores.remove(i)
			i -= 1
		i += 1
	i = 0
	for player_time in sorted_scores:
		for name in highscores:
			if highscores[name] == player_time:
				var label = Label.new()
				label.set_text("%-20s %02d:%02d" % [name, int(player_time/60), player_time%60])
				label.set_pos(Vector2(10, y))
				panel.add_child(label)
				y += 20
				i += 1
			if i == 5: break
		if i == 5: break
	var restart_button = Button.new()
	restart_button.set_pos(Vector2(30, y))
	restart_button.connect("pressed", self, "restart")
	restart_button.set_text("Restart")
	panel.set_size(Vector2(panel.get_size().x, y + 30))
	panel.add_child(restart_button)

func restart():
	interface.get_node("Highscore").set_hidden(true)
	Scene_switcher.change_scene("res://Scenes/Levels/Level1.tscn")
	reset()
