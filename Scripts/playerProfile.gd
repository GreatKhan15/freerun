extends Node

var player_nick = "Me"
var profile_pic : int = 1
var profile_frame : int = 1
var selected_character = 1
var selected_hair = 1
var selected_top = 1
var selected_pants = 1
var selected_shoes = 1
var hair_color
var top_color
var pants_color
var shoes_color
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

func change_nick(in_name):
	player_nick = in_name
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
func set_hair(index):
	selected_hair = index
	save_profile()
func set_top(index):
	selected_top = index
	save_profile()
func set_pants(index):
	selected_pants = index
	save_profile()
func set_shoes(index):
	selected_shoes = index
	save_profile()
	
	
func set_hair_color(color):
	hair_color = color
	save_profile()
func set_top_color(color):
	top_color = color
	save_profile()
func set_pants_color(color):
	pants_color = color
	save_profile()
func set_shoes_color(color):
	shoes_color = color
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
func get_hair(): return selected_hair
func get_top(): return selected_top
func get_pants(): return selected_pants
func get_shoes(): return selected_shoes

func get_hair_color(): return hair_color
func get_top_color(): return top_color
func get_pants_color(): return pants_color
func get_shoes_color(): return shoes_color

func save_profile():
	var data = {
		"name": player_nick,
		"pic": profile_pic,
		"frame": profile_frame,
		"char": selected_character,
		"hair": selected_hair,
		"top": selected_top,
		"pants": selected_pants,
		"shoes": selected_shoes,
		"haircolor": hair_color,
		"topcolor": top_color,
		"pantscolor": pants_color,
		"shoescolor": shoes_color,
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
			selected_hair = data.get("hair", selected_hair)
			selected_top = data.get("top", selected_top)
			selected_pants = data.get("pants", selected_pants)
			selected_shoes = data.get("shoes", selected_shoes)
			hair_color = data.get("haircolor", hair_color)
			top_color = data.get("topcolor", top_color)
			pants_color = data.get("pantscolor", pants_color)
			shoes_color = data.get("shoescolor", shoes_color)
			matches = data.get("matches", matches)
			settings = data.get("settings", settings)
			hair_color = colorfix(hair_color)
			top_color = colorfix(top_color)
			pants_color = colorfix(pants_color)
			shoes_color = colorfix(shoes_color)

func colorfix(inc):
	var colo = Color.GRAY
	if typeof(inc) == TYPE_STRING:
		# Remove parentheses and split
		var stripped = inc.strip_edges().replace("(", "").replace(")", "")
		var parts = stripped.split(",")

		if parts.size() >= 3:
			var r = float(parts[0])
			var g = float(parts[1])
			var b = float(parts[2])
			var a = float(parts[3])
			colo = Color(r, g, b, a)
		else:
			push_error("Invalid color string: " + inc)

	elif typeof(inc) == TYPE_COLOR:
		colo = inc
	else:
		push_error("Unsupported color type: " + str(inc))
	
	return colo
