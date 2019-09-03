extends Node

var _params

func change_scene(next_scene, params=null):
	_params = params
	get_tree().change_scene(next_scene)

func get_param(name):
	if _params != null and _params.has(name):
		return _params[name]
	return null

func save_game(highscores):
	var save_file = File.new()
	save_file.open("Highscores/table.sav", File.WRITE)
	for name in highscores:
		save_file.store_line(name + "," + str(highscores[name]))
	save_file.close()

func load_game():
	var highscores = {}
	var load_file = File.new()
	if !load_file.file_exists("Highscores/table.sav"): return highscores
	load_file.open("Highscores/table.sav", File.READ)
	
	var current_line = load_file.get_line().split(",")
	while (current_line.size() > 1 and not load_file.eof_reached()):
		highscores[current_line[0]] = int(current_line[1])
		current_line = load_file.get_line().split(",")
	load_file.close()
	return highscores