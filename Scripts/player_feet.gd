extends RayCast2D

onready var feet = [get_node("../feet1"), get_node("../feet2")]

func _ready():
	add_exception(get_parent())
	for foot in feet:
		foot.add_exception(get_parent())

func is_colliding():
	if .is_colliding(): return true
	for foot in feet:
		if foot.is_colliding(): return true
	return false

func get_collider():
	if .is_colliding(): return .get_collider()
	for foot in feet:
		if foot.is_colliding(): return foot.get_collider()
	return null
