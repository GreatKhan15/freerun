extends Node

var player_nick = "Me"
var profile_pic : int = 1
var profile_frame : int = 1
var selected_character = 1
var matches = 0

signal matches_updated
signal pic_updated


var settings = {
	"volume": 0.8,
	"show_names": true
}

func on_about_to_quit():
	save_profile()

func _enter_tree():
	load_profile()

func change_nick(name):
	player_nick = name
	save_profile()
func set_profile_pic(pic):
	profile_pic = pic
	save_profile()
	emit_signal("pic_updated")
func set_profile_frame(frame):
	profile_frame = frame
	save_profile()
	emit_signal("pic_updated")
func set_character(index):
	selected_character = index
	save_profile()	
func add_match():
	matches += 1
	save_profile()
	emit_signal("matches_updated")

func get_profile_pic(): return profile_pic
func get_profile_frame(): return profile_frame
func get_matches(): return matches
func get_nick(): return player_nick
func get_character(): return selected_character

func save_profile():
	var data = {
		"name": player_nick,
		"pic": profile_pic,
		"frame": profile_frame,
		"char": selected_character,
		"matches": matches,
		"settings": settings
	}
	var file = FileAccess.open("user://profile.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data))

func load_profile():
	if FileAccess.file_exists("user://profile.json"):
		var file = FileAccess.open("user://profile.json", FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		if typeof(data) == TYPE_DICTIONARY:
			player_nick = data.get("name", player_nick)
			profile_pic = data.get("pic", profile_pic)
			profile_frame = data.get("frame", profile_frame)
			selected_character = data.get("char", selected_character)
			matches = data.get("matches", matches)
			settings = data.get("settings", settings)
