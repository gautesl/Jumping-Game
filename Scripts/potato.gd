extends RigidBody2D

var attack_timer
export var lives = 3 setget set_lives
var max_lives
export var left = true
export var right = false
export var shooting_rate = 50
var max_shooting_rate
export var moving = true
export var jump_modifier = 1
var up = -300
var retaliate_mode = false
export var smart = false
var nr = 0
var dir = [-500, 0, 500]

const max_speed = 10
const bullet_scene = preload("res://Scenes/Potato bullet.tscn")
const coin_scene = preload("res://Scenes/Coin.tscn")
var retaliate_timer

func _ready():
	max_lives = lives
	max_shooting_rate = shooting_rate
	attack_timer = get_node("Attack_timer")
	attack_timer.connect("timeout", self, "on_attack_timeout")
	attack_timer.start()
	retaliate_timer = get_node("Retaliate_timer")
	retaliate_timer.connect("timeout", self, "on_retaliate_timeout")
	if not moving: get_node("AnimationPlayer").stop_all()

func on_attack_timeout():
	randomize()
	if not retaliate_mode:
		attack_timer.set_wait_time((randi()%shooting_rate / 10) +1)
	var bullet = bullet_scene.instance()
	if smart and retaliate_mode:
		bullet.set_pos(Vector2(0, -15))
		bullet.set_axis_velocity(Vector2(dir[nr%3], up))
		nr += 1
		add_child(bullet)
		return
	if retaliate_mode:
		right = get_parent().get_node("Player").get_global_pos().x > get_global_pos().x
		left = !right
	if right:
		bullet.set_pos(Vector2(30, -15))
		bullet.set_axis_velocity(Vector2(500, up))
	else:
		bullet.set_pos(Vector2(-30, -15))
		bullet.set_axis_velocity(Vector2(-500, up))
	add_child(bullet)

func set_shooting_rate(value):
	shooting_rate = value

func on_retaliate_timeout():
	retaliate_timer.stop()
	up = -300
	shooting_rate = max_shooting_rate
	retaliate_mode = false

func set_lives(value):
	lives = value
	if lives <= 0:
		queue_free()
		randomize()
		for x in range(int(randi()%2 +1)):
			var coin = coin_scene.instance()
			coin.set_global_pos(get_global_pos() + Vector2(int(randi()%30 -15), int(randi()%30 -15)))
			get_parent().add_child(coin)
			
	if lives != max_lives and retaliate_timer:
		retaliate_timer.start()
		shooting_rate = 1
		up = -1000
		retaliate_mode = true
		attack_timer.set_wait_time(0.4)
		attack_timer.start()

func queue_free():
	.queue_free()
	get_parent().enemies -= 1