extends Area2D

var player
func _ready():
	player = get_node("../Player")
	connect("body_enter", self, "on_body_enter")

func on_body_enter(body):
	if body == player:
		get_parent().coins += 1
		queue_free()
