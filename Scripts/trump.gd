extends RigidBody2D

onready var timer = get_node("Explosion_timer")
onready var cd_timer = get_node("Countdown_timer")
onready var explosion_area = get_node("Explosion_area")
onready var time = get_node("Explosion_timer").get_wait_time()
var right = true

func _ready():
	set_fixed_process(true)
	get_node("AnimationPlayer").connect("finished", self, "on_finished")
	timer.connect("timeout", self, "on_timeout")
	cd_timer.connect("timeout", self, "on_cd_timeout")
	cd_timer.start()
	timer.start()

func _fixed_process(delta):
	if right: set_axis_velocity(Vector2(100, 0))
	else: set_axis_velocity(Vector2(-100, 0))

func on_timeout():
	explode()
	timer.stop()

func explode():
	get_node("AnimationPlayer").play("Explotion")
	for body in explosion_area.get_overlapping_bodies():
		if body.is_in_group("Enemy"):
			body.lives -= 5
		elif body.is_in_group("Crate"):
			body.queue_free()
		elif body.is_in_group("Player"):
			if body.get_node("feet").is_colliding() and body.get_node("feet").get_collider() == self:
				body.set_axis_velocity(Vector2(0, -1000))
			elif body.get_node("left_side").is_colliding() and body.get_node("left_side").get_collider() == self:
				body.set_axis_velocity(Vector2(1000, 0))
			elif body.get_node("right_side").is_colliding() and body.get_node("right_side").get_collider() == self:
				body.set_axis_velocity(Vector2(-1000, 0))

func on_cd_timeout():
	time -= 1
	get_node("Countdown").set_text(str(time))

func on_finished():
	queue_free()
