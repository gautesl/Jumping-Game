extends RigidBody2D

func _ready():
	var timer = get_node("Timer")
	timer.connect("timeout", self, "on_timeout")
	timer.set_wait_time(5)
	timer.start()
	set_fixed_process(true)
	set_contact_monitor(true)
	set_max_contacts_reported(1)

func on_timeout():
	queue_free()

func _fixed_process(delta):
	if not get_parent() in get_colliding_bodies() and get_colliding_bodies() != []:
		queue_free()
