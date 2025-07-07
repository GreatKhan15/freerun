extends Node

@export var playerScene : PackedScene
@export var map : PackedScene

var spawnPosition : Vector3
var racePosition : Vector3

var port = 12345

const SERVER_PORT = 8080
var SERVER_IP = "127.0.0.1"
var map_instance
var my_player
var raceStarted = false
var editingName = false
var holdChat = false

@onready var profilePicCont = %ProfilePicContainer
@onready var profileFrameCont = %ProfileFrameContainer

func _input(event):
	if event is InputEventKey:
		if event.is_action_pressed("ui_q"):
			if Input.is_key_pressed(KEY_ALT):
				get_tree().quit()
		elif event.is_action_pressed("ui_startrace"):
			if multiplayer.is_server():
				#Start Race
				if not raceStarted:
					start_race()
		elif event.is_action_pressed("ui_enter"):
			if editingName:
				editingName = false
				%NameEdit.editable = false
				$CanvasLayer/TopRight/ProfilePanel/Panel/VBoxContainer/HBoxContainer3/EditName.text = "Edit"
				PlayerProfile.change_nick(%NameEdit.text)
			else:
				if %Say.text != "" and %Say.visible:
					send_message.rpc(multiplayer.get_unique_id(), %Say.text)
					%Say.text = ""
					if not holdChat:
						%Say.visible = !%Say.visible
						if my_player:
							my_player.in_menu = false
							Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
					await get_tree().process_frame
					%ScrollContainer.scroll_vertical = %ScrollContainer.get_v_scroll_bar().max_value
				elif %Say.visible and %Say.text == "":
					holdChat = false
					%Say.visible = false
					if my_player:
						my_player.in_menu = false
						Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				else:
					%Say.visible = !%Say.visible
					if %Say.visible:
						if my_player:
							my_player.in_menu = true
							Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
						if Input.is_key_pressed(KEY_CTRL):
							holdChat = true
						%Say.grab_focus()
						%MessagesBox.show()
						%MessagesDisapearTimer.stop()
					else:
						%MessagesDisapearTimer.start()
		elif event.is_action_pressed("ui_escape"):
			if %Say.visible:
				%Say.visible = false
				%Say.text = ""
				holdChat = false
			else:
				toggle_esc_menu()
		
func toggle_esc_menu():
	var menu = %ESCMenu

	var menu2 = %ProfilePanel
	var end_pos = Vector2(-menu2.size.x, 160)  # Where it should appear
	var start_pos = Vector2(0,160 )
	
	if menu.visible:
		if my_player:
			my_player.in_menu = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		var tween = create_tween()
		tween.tween_property(menu, "modulate:a", 0.0, 0.1)
		tween.tween_property(menu, "scale", Vector2(0.9, 0.9), 0.1)
		tween.connect("finished", Callable(self, "_on_menu_hidden"))
		var tween2 = create_tween()
		tween2.tween_property(menu2, "position", start_pos, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	else:
		if my_player:
			my_player.in_menu = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		menu.modulate.a = 0.0
		menu.scale = Vector2(0.9, 0.9)
		menu.visible = true

		var tween = create_tween()
		tween.tween_property(menu, "modulate:a", 1.0, 0.1)
		tween.tween_property(menu, "scale", Vector2(1, 1), 0.1)
		
		menu2.position = start_pos
		menu2.visible = true
		var tween2 = create_tween()
		tween2.tween_property(menu2, "position", end_pos, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_menu_hidden():
	%ESCMenu.visible = false
	%ProfilePanel.visible = false

func _ready() -> void:

	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()
	
	PlayerProfile.matches_updated.connect(_on_matches_updated)
	PlayerProfile.pic_updated.connect(_on_profile_pic_updated)
	
	%NameEdit.text = PlayerProfile.get_nick()
	%ProfilePicContainer.texture = load("res://Textures/ProfilePics/ProfilePic%s.png"%PlayerProfile.get_profile_pic())
	%ProfileFrameContainer.texture = load("res://Textures/ProfileFrames/Frame%s.png"%PlayerProfile.get_profile_frame())
	%MatchesCounter.text = str(PlayerProfile.get_matches())

func _on_viewport_size_changed():
	%Say.size.x = get_viewport().size.x / 3
	%Say.position.x = get_viewport().size.x / 3
	%Say.position.y = (get_viewport().size.y / 4) * 3

func _on_matches_updated():
	%MatchesCounter.text = str(PlayerProfile.get_matches())
func _on_profile_pic_updated():
	%ProfilePicContainer.texture = load("res://Textures/ProfilePics/ProfilePic%s.png"%PlayerProfile.get_profile_pic())
	%ProfileFrameContainer.texture = load("res://Textures/ProfileFrames/Frame%s.png"%PlayerProfile.get_profile_frame())

func _process(delta: float) -> void:
	pass


func _on_host_button_pressed() -> void:
	var server_peer = ENetMultiplayerPeer.new()
	server_peer.create_server(SERVER_PORT)
	multiplayer.multiplayer_peer = server_peer
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(del_player)
	load_game()

func _on_join_button_pressed() -> void:	
	var client_peer = ENetMultiplayerPeer.new()
	client_peer.create_client(SERVER_IP,SERVER_PORT)
	
	multiplayer.multiplayer_peer = client_peer
	multiplayer.connected_to_server.connect(load_game)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.connection_failed.connect(_on_connection_failed)

func _on_to_text_submitted(new_text: String) -> void:
	_on_join_button_pressed() 

func _peer_connected(id: int):
	print("peer %s connected" % id)


func del_player(id):
	_del_player.rpc(id)
	_del_player(id)

@rpc("call_local")
func _del_player(id):
	if not $Players.has_node(str(id)):
		return
	$Players.get_node(str(id)).queue_free()
	map_instance.remove_marker(id)
	

func load_game():	
	%Lobby.hide()
	%ConnectMenu.hide()
	map_instance = map.instantiate()
	%Map.add_child(map_instance)
	%EditName.disabled = true
	%ChangeProfilePic.disabled = true
	
	for child in map_instance.get_children():
		if child.name.begins_with("Spawn"):
			spawnPosition = child.global_position
		elif child.name.begins_with("RaceStart"):
			racePosition = child.global_position
	
	if multiplayer.is_server():
		_spawn_this(1)
	else:
		spawn_request.rpc_id(1,multiplayer.get_unique_id())
	
	
@rpc("any_peer")
func spawn_request(id):
	_spawn_this.rpc(id)

@rpc("call_local")
func _spawn_this(id):
	var playerToAdd = playerScene.instantiate()
	playerToAdd.name = str(id)
	playerToAdd.player_id = id
	if raceStarted:
		playerToAdd.raceStarted = true
		map_instance.position_start.rpc_id(id,spawnPosition)
		map_instance.setup_race(playerToAdd)
	playerToAdd.set_multiplayer_authority(id)
	$Players.add_child(playerToAdd)
	playerToAdd.global_position = spawnPosition
	if multiplayer.get_unique_id() == id:
		my_player = playerToAdd
		my_player.player_nick = PlayerProfile.get_nick()
		map_instance.my_player = my_player
	map_instance.add_marker(id)

func start_race():
	raceStarted = true
	var spacing = 0
	for players in %Players.get_children():
		var spawnSpotperPlayer = racePosition + (Vector3(0,0,1)*spacing)
		map_instance.setup_race(players)
		if players.player_id == 1:
			map_instance.position_start(spawnSpotperPlayer)
		else:
			map_instance.position_start.rpc_id(players.player_id,spawnSpotperPlayer)
		spacing += 2

func _on_connection_failed():
	print("Connection failed")


func _on_server_disconnected():
	print("Server DC %s" % multiplayer.get_unique_id())	
	%ConnectMenu.show()

	for child in %Map.get_children():
		child.queue_free()
	for child in %Players.get_children():
		child.queue_free()
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE	


@rpc("call_local", "any_peer")
func send_message(id, message):
	%MessagesBox.show()
	var label = Label.new()
	label.modulate = Color(1, 1, 1)
	if my_player:
		if id == my_player.player_id:
			label.modulate = Color.CYAN
			label.text = "%s : %s" %[PlayerProfile.player_nick, message]
		else:
			label.text = str(id) + " : " + message
	elif multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		label.text = "Offline : " + message
	else:
		label.text = str(id) + " : " + message
	%Messages.add_child(label)
	%MessagesDisapearTimer.start()

func _on_messages_disapear_timer_timeout() -> void:
	%MessagesBox.hide()


func _on_edit_name_pressed():
	if editingName:
		editingName = false
		%NameEdit.editable = false
		$CanvasLayer/TopRight/ProfilePanel/Panel/VBoxContainer/HBoxContainer3/EditName.text = "Edit"
		PlayerProfile.change_nick(%NameEdit.text)
	else:
		editingName = true
		%NameEdit.editable = true
		%NameEdit.grab_focus()
		$CanvasLayer/TopRight/ProfilePanel/Panel/VBoxContainer/HBoxContainer3/EditName.text = "Confirm"


func _on_resume_button_pressed():
	toggle_esc_menu()

func _on_options_button_pressed():
	pass

func _on_exit_button_pressed():
	get_tree().quit()


func _on_change_profile_pic_pressed():
	%ProfilePicEditPanel.visible = true
	%TestPic.visible = true
	%TestFrame.visible = true
