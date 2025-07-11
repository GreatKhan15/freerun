extends CharacterBody3D

@onready var camera: Camera3D = $Camera3D
@onready var spring_arm : SpringArm3D = $SpringArm3D
@onready var cameraPositionNode: Node3D = $SpringArm3D/CameraSpringPosition
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var animTree : AnimationTree = $AnimationPlayer/AnimationTree
@onready var obstacleRaycast : RayCast3D = $ObstacleRayCast
@onready var wallLeftRaycast : RayCast3D = $WallLeftRayCast
@onready var wallRightRaycast : RayCast3D = $WallRightRayCast
@onready var wallHangUpperRC : RayCast3D = $WallHangUpperRayCast
@onready var wallHangFrontRC : RayCast3D = $WallHangFrontRayCast
@onready var wallHangUnderRC : RayCast3D = $WallHangUnderRayCast
@onready var skeleton = $Armature/Skeleton3D

@export var player_id : int
@export var player_nick : String

var character_int = 1
var hair_int = 1
var tops_int = 1
var pants_int = 1

var slide_timer: float = 0.0
var wall_normal: Vector3 = Vector3.ZERO
var input_dir : Vector2
var slide_target_scale_y: float = 1.0
var slide_scale_speed: float = 5.0  # larger = faster transition
var target_velocity : Vector3
var target_rotation : Vector3
var forced_rotation : Vector3
var current_trick: int = 0
var trickCheckpointCount : int
var trickCheckpoints : Dictionary = {}
var trickCheckpointTimers : Dictionary = {}
var trickCheckpointCurrent : int = 1
var trickTimer = 0.0
var trickAnimationSpeed = 1
var currentAnimation = "Idle"
var savedCameraPos = Vector3(0,0,0)
var smoothCameraLook = false

var speed: float = 7.0
var jump_strength: float = 8.5
var gravity: float = 20.0
var slide_time: float = 1.3
var DIRECTION_LERP_SPEED = 5.0
var VELOCITY_INTERPOLATION_GROUND = 15.0
var VELOCITY_INTERPOLATION_AIR = 0.5
var WALLRUN_ANTIGRAVITY = 0.1
var SPRINT_MULTIPLIER = 1.3
var KICK_VELOCITY = 22.0
var ROTATION_INTERPOLATION = 3.0
var BOUNCE_STRENGTH = 8.5
var ACCELERATION_RATE = 3.0
var BRAKE_RATE = 6.0
var WALLRUN_SPEED = 9.0
var NORMAL_FOV = 50.0
var SLIDE_FOV = NORMAL_FOV + 20.0
var RUN_FOV = NORMAL_FOV + 15.0
var WIN_FOV = NORMAL_FOV + 25.0
var KICK_FOV = NORMAL_FOV + 40.0
var CAMERA_WIN_DISTANCE = 9.0
var MIN_CAMERA_ZOOM = 1.0
var MAX_CAMERA_ZOOM = 8.0
@export var raceprogress = 0.0
var targetCameraFov = NORMAL_FOV

var cameraControlled = true
@export var is_sliding: bool = false
@export var is_jumping = false
@export var is_hanging = false
@export var is_hang_climbing = false
@export var cancel_hang = false
@export var is_falling = false
@export var is_wall_running_left: bool = false
@export var is_wall_running_right: bool = false
@export var is_wall_running: bool = false
var sprintPressed = false
@export var sprinting = false
@export var jumped = false
@export var vault = false
@export var trick = false
@export var raceStarted = false
@export var raceFinished = false
var kickAttack = false
var kicking = false
var in_menu = false

@export var direction : Vector3
@export var current_direction : Vector2

var obstacle

@export var mouse_sensitivity = 0.002
var rotation_x = 0.0

func _enter_tree():
	set_multiplayer_authority(name.to_int())

func _ready():
	if multiplayer.get_unique_id() != player_id:
		set_process(false)
		set_physics_process(false)
	
	add_to_group("players")
	
	if multiplayer.get_unique_id() == player_id:
		camera.current = true
	else:
		camera.current = false
	
	add_to_group("players")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	spring_arm.add_excluded_object(self)
	animTree.active = true
	
	floor_max_angle= deg_to_rad(60)
	floor_snap_length= 3.0
	
	for area in get_tree().get_nodes_in_group("trick"):
		area.connect("player_entered_trick_area", _on_trick_entered)
		area.connect("player_exited_trick_area", _on_trick_exited)
	

func _input(event):
	if player_id != multiplayer.get_unique_id():
		return
	
	if not in_menu:
		if event.is_action_pressed("ui_jump"):
			jumped = true
		elif event.is_action_pressed("ui_crouch"):
			if is_hanging:
				cancel_hang = true
			if is_on_floor() and input_dir.length() > 0 and not is_sliding:
				is_sliding = true
				slide_timer = slide_time
				slide_target_scale_y = 0.3
		elif event.is_action_pressed("ui_kick") and is_on_floor():
			kickAttack = true
		elif event.is_action_pressed("do_trick") and current_trick != 0 and is_on_floor():
			perform_trick(current_trick)
			
		if event.is_action_pressed("ui_sprint") and not trick:
			sprintPressed = true
		elif event.is_action_released("ui_sprint"):
			sprintPressed = false
		
		if event.is_action_pressed("ui_cameramode"):
			smoothCameraLook = !smoothCameraLook
		
		if event is InputEventMouseMotion:
			target_rotation.x -= event.relative.y * mouse_sensitivity
			target_rotation.x = clamp(target_rotation.x, deg_to_rad(-89), deg_to_rad(70))
			spring_arm.rotation.x = target_rotation.x
			target_rotation.y -= event.relative.x * mouse_sensitivity
		elif event is InputEventMouseButton and Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_DOWN):
			spring_arm.spring_length += 0.2
		elif event is InputEventMouseButton and Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_UP):
			spring_arm.spring_length -= 0.2
	
	spring_arm.spring_length = clamp(spring_arm.spring_length,MIN_CAMERA_ZOOM,MAX_CAMERA_ZOOM)

func perform_trick(trickINT: int):
	match trickINT:
		1:
			#Vault Trick
			trick = true
			vault = true
			sprinting = false
			sprintPressed = false
			is_sliding = false
			setup_vault()
		2:
			#WallHang Trick
			setup_hang()
		_:
			print("Unknown trick:", trickINT)
	

func _on_animation_tree_animation_finished(anim_name):
	if player_id != multiplayer.get_unique_id():
		return
		
	if anim_name == "Vault":
		trick=false
		vault=false
	elif anim_name == "Vault2":
		trick=false
		vault=false
	elif anim_name == "WallHang":
		is_hang_climbing = true
	elif anim_name == "WallHangClimb":
		trick=false
		is_hang_climbing = false
		is_hanging = false
		cameraControlled = true
	elif anim_name == "FrontKick":
		kickAttack = false
		is_falling = true
		kicking = false
		targetCameraFov = NORMAL_FOV


func _on_trick_entered(in_trick: int, obs):
	current_trick = in_trick
	obstacle = obs

func _on_trick_exited():
	current_trick = 0
	
func _process(delta):
	if cancel_hang and is_hanging and not is_hang_climbing:
		cameraControlled = true
		is_hanging = false
		is_falling = true
		trick = false
		
	current_direction = lerp(current_direction,input_dir,delta*DIRECTION_LERP_SPEED)
	
	if cameraControlled:
		if is_on_floor() and velocity.length()>0.1:
			var temp = spring_arm.global_rotation
			global_rotation.y = move_toward_angle(
				global_rotation.y,
				target_rotation.y,
				ROTATION_INTERPOLATION * delta
			)
			spring_arm.global_rotation = temp
	else:
		global_rotation.y = lerp_angle(global_rotation.y,forced_rotation.y,delta*5.0)
	
	animTree.set("parameters/StateMachine/BlendSpace2D/blend_position",Vector2(current_direction.x,-current_direction.y))
	
	animTree.set("parameters/StateMachine/conditions/isSliding",is_sliding)
	animTree.set("parameters/StateMachine/conditions/notSliding",!is_sliding)
	animTree.set("parameters/StateMachine/conditions/isFalling",is_falling)
	animTree.set("parameters/StateMachine/conditions/notFalling",!is_falling)
	animTree.set("parameters/StateMachine/conditions/isWallLeft",is_wall_running_left)
	animTree.set("parameters/StateMachine/conditions/isNotWallLeft",!is_wall_running_left)
	animTree.set("parameters/StateMachine/conditions/isWallRight",is_wall_running_right)
	animTree.set("parameters/StateMachine/conditions/isNotWallRight",!is_wall_running_right)
	animTree.set("parameters/StateMachine/conditions/FastRun",sprinting)
	animTree.set("parameters/StateMachine/conditions/notFastRun",!sprinting)
	animTree.set("parameters/StateMachine/conditions/Trick",trick)
	animTree.set("parameters/StateMachine/conditions/notTrick",!trick)
	
	animTree.set("parameters/StateMachine/TrickMachine/conditions/CancelHang",cancel_hang)
	animTree.set("parameters/StateMachine/TrickMachine/conditions/isHanging",is_hanging)
	animTree.set("parameters/StateMachine/TrickMachine/conditions/Vault",vault)
	
	if smoothCameraLook:
		var bone_idx = skeleton.find_bone("mixamorig_Hips")
		var local_bone_transform = skeleton.get_bone_global_pose(bone_idx)
		var global_bone_pos = skeleton.to_global(local_bone_transform.origin)
		var camera_pos = camera.global_transform.origin
		# Current forward vector
		var current_basis = camera.global_transform.basis
		var target_basis := Basis.looking_at(global_bone_pos - camera_pos, Vector3.UP)
		var smoothed_basis = current_basis.slerp(target_basis, delta * 15.0)

		camera.global_transform = Transform3D(smoothed_basis, camera_pos)
		
	else:
		camera.look_at(spring_arm.global_position)
	
	camera.global_position = lerp(camera.global_position,cameraPositionNode.global_position,delta*10.0)
	savedCameraPos = camera.global_position
	
	if kickAttack and is_on_floor() and not kicking:
		#Perform Kick
		kicking = true
		velocity = -transform.basis.z * KICK_VELOCITY
		velocity.y = 5.0
		animTree.set("parameters/KickShot/request",AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		targetCameraFov = KICK_FOV
	
	
	#Scan for a wallgrab
	if not is_on_floor() and not is_wall_running and not cancel_hang:
		wallHangUnderRC.force_raycast_update()
		if not wallHangUnderRC.is_colliding():
			wallHangFrontRC.force_raycast_update()
			wallHangUpperRC.force_raycast_update()
			if wallHangFrontRC.is_colliding() and not wallHangUpperRC.is_colliding() and not is_hanging:
				animTree.set("parameters/JumpShot/request",AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
				perform_trick(2)

func move_toward_angle(current: float, target: float, max_delta: float) -> float:
	var diff = angle_difference(current, target)
	var step = clamp(diff, -max_delta, max_delta)
	return current + step

func _physics_process(delta):
	spring_arm.global_rotation.y = target_rotation.y

	if not is_on_floor() and not is_wall_running and not trick: 
		velocity.y -= gravity * delta
		is_falling = true

	if not in_menu:
		input_dir = Vector2.ZERO
		input_dir.x = Input.get_axis("ui_left", "ui_right")
		input_dir.y = Input.get_axis("ui_up", "ui_down")
	
	if sprintPressed:
		input_dir.x = 0
		if input_dir.y < 0:
			sprinting = true
		else:
			sprinting = false
	else:
		sprinting = false
	
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if is_on_floor() or is_wall_running:
		target_velocity.x = direction.x * speed
		target_velocity.z = direction.z * speed
		if sprinting and not is_wall_running:
			target_velocity *= SPRINT_MULTIPLIER
			if not raceFinished:
				targetCameraFov = RUN_FOV
		
		is_jumping = false
		is_falling = false
		cancel_hang = false
	else:
		target_velocity.x = velocity.x
		target_velocity.z = velocity.z
		is_sliding = false
	
	
	if trick:
		if vault:
			perform_vault(delta)
		if is_hanging:
			perform_hanging(delta)
	else:
		if $CollisionShape3D.disabled:
			$CollisionShape3D.disabled = false
		if jumped and is_on_floor():
			velocity.y = jump_strength
			is_jumping = true
			is_sliding = false
			jumped = false
			animTree.set("parameters/JumpShot/request",AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		elif jumped and is_wall_running:
			#Juming from wallrun
			velocity.y = BOUNCE_STRENGTH
			velocity += wall_normal * BOUNCE_STRENGTH
			
			cameraControlled = false
			is_jumping = true
			jumped = false
			is_wall_running = false
			is_wall_running_left = false
			is_wall_running_right = false
			
			var temp = global_rotation
			look_at(global_position+velocity,Vector3.UP)
			forced_rotation = global_rotation
			global_rotation = temp
			
			delayed_camera_enable(1.0)
			
			animTree.set("parameters/JumpShot/request",AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		else:
			#No jumping to do, cancel it
			jumped = false
	
	# Wall Run
	if not is_wall_running and not is_on_floor():
		wallRightRaycast.force_raycast_update()
		wallLeftRaycast.force_raycast_update()
		if wallRightRaycast.is_colliding() and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			wall_normal = wallRightRaycast.get_collision_normal()
			if abs(wall_normal.y) < 0.1:
				is_wall_running_right = true
				is_wall_running = true

				var forward = -transform.basis.z
				var wall_dir = (forward - wall_normal * forward.dot(wall_normal)).normalized()
				
				var temp = global_rotation
				look_at(global_position + wall_dir, Vector3.UP)
				forced_rotation= global_rotation
				global_rotation = temp
				cameraControlled = false
				
				velocity = wall_dir * WALLRUN_SPEED
				velocity.y = 0
				
				animTree.set("parameters/JumpShot/request",AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)

		if wallLeftRaycast.is_colliding() and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			wall_normal = wallLeftRaycast.get_collision_normal()
			if abs(wall_normal.y) < 0.1:
				is_wall_running_left = true
				is_wall_running = true

				var forward = -transform.basis.z
				var wall_dir = (forward - wall_normal * forward.dot(wall_normal)).normalized()
				
				var temp = global_rotation
				look_at(global_position + wall_dir, Vector3.UP)
				forced_rotation= global_rotation
				global_rotation = temp
				cameraControlled = false
				
				velocity = wall_dir * WALLRUN_SPEED
				velocity.y = 0
				
				animTree.set("parameters/JumpShot/request",AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
	if is_wall_running:
		velocity.y -= gravity * delta * WALLRUN_ANTIGRAVITY
		if is_on_floor() or (is_wall_running_left and not wallLeftRaycast.is_colliding()) or (is_wall_running_right and not wallRightRaycast.is_colliding()):
			is_wall_running = false
			is_wall_running_left = false
			is_wall_running_right = false
			cameraControlled = true

		
	if is_sliding:
		if not raceFinished:
			targetCameraFov = SLIDE_FOV
			
		slide_timer -= delta
		target_velocity *= 1.2  # Boost speed
		
		var ray_origin = global_position
		var ray_target = global_position + Vector3.DOWN * 2.0

		var ray_query = PhysicsRayQueryParameters3D.create(ray_origin, ray_target)
		ray_query.collide_with_areas = false
		ray_query.collide_with_bodies = true

		var space_state = get_world_3d().direct_space_state
		var result = space_state.intersect_ray(ray_query)

		if result:
			var ground_normal = result.normal
			var angle_radians = ground_normal.angle_to(Vector3.UP)

			var forward = -global_transform.basis.z.normalized()
			var gravity = Vector3.DOWN

			var slope_direction = (gravity - ground_normal * gravity.dot(ground_normal)).normalized()
			var dot = slope_direction.dot(forward)

			if dot > 0:
				target_velocity *= 1.0 + angle_radians / 9
			elif dot < 0:
				target_velocity *= 1.0 - angle_radians / 2

		if slide_timer <= 0:
			is_sliding = false
			slide_target_scale_y = 1.0
	else:
		is_sliding = false
		slide_target_scale_y = 1.0
		if not raceFinished and not sprinting:
			targetCameraFov = NORMAL_FOV
	
	if kicking:
		targetCameraFov = KICK_FOV
	if raceFinished:
		targetCameraFov = WIN_FOV
		spring_arm.spring_length = CAMERA_WIN_DISTANCE
		
	if not camera.fov == targetCameraFov:
		camera.fov = lerp(camera.fov,targetCameraFov,delta*3.0)
		if abs(camera.fov - targetCameraFov) < 0.3 :
			camera.fov = targetCameraFov
	
	if abs(collision_shape.scale.y - slide_target_scale_y) > 0.05:
		var current_y = collision_shape.scale.y
		var new_y = lerp(current_y, slide_target_scale_y, slide_scale_speed * delta)
		collision_shape.scale.y = new_y
		collision_shape.position.y = collision_shape.scale.y
		spring_arm.position.y = collision_shape.shape.height*collision_shape.scale.y
	
	if sprintPressed:
		target_velocity *= SPRINT_MULTIPLIER
	
	if is_on_floor():
		if target_velocity != Vector3.ZERO:
			velocity.x = lerp(velocity.x,target_velocity.x,delta*ACCELERATION_RATE)
			velocity.z = lerp(velocity.z,target_velocity.z,delta*ACCELERATION_RATE)
		else:
			velocity.x = lerp(velocity.x,target_velocity.x,delta*BRAKE_RATE)
			velocity.z = lerp(velocity.z,target_velocity.z,delta*BRAKE_RATE)
	else:
		velocity.x = lerp(velocity.x,target_velocity.x,delta*VELOCITY_INTERPOLATION_AIR)
		velocity.z = lerp(velocity.z,target_velocity.z,delta*VELOCITY_INTERPOLATION_AIR)
		is_falling = true

	move_and_slide()
	if is_multiplayer_authority():
		sync_position.rpc(global_position, velocity)

@rpc("unreliable")
func sync_position(pos: Vector3, vel: Vector3):
	global_position = pos
	velocity = vel
	
	animTree.set("parameters/StateMachine/BlendSpace2D/blend_position",Vector2(current_direction.x,-current_direction.y))
	
	animTree.set("parameters/StateMachine/conditions/isSliding",is_sliding)
	animTree.set("parameters/StateMachine/conditions/notSliding",!is_sliding)
	animTree.set("parameters/StateMachine/conditions/isFalling",is_falling)
	animTree.set("parameters/StateMachine/conditions/notFalling",!is_falling)
	animTree.set("parameters/StateMachine/conditions/isWallLeft",is_wall_running_left)
	animTree.set("parameters/StateMachine/conditions/isNotWallLeft",!is_wall_running_left)
	animTree.set("parameters/StateMachine/conditions/isWallRight",is_wall_running_right)
	animTree.set("parameters/StateMachine/conditions/isNotWallRight",!is_wall_running_right)
	animTree.set("parameters/StateMachine/conditions/FastRun",sprinting)
	animTree.set("parameters/StateMachine/conditions/notFastRun",!sprinting)
	animTree.set("parameters/StateMachine/conditions/Trick",trick)
	animTree.set("parameters/StateMachine/conditions/notTrick",!trick)
	
	animTree.set("parameters/StateMachine/TrickMachine/conditions/CancelHang",cancel_hang)
	animTree.set("parameters/StateMachine/TrickMachine/conditions/isHanging",is_hanging)
	animTree.set("parameters/StateMachine/TrickMachine/conditions/Vault",vault)

func teleport_to(pos: Vector3):
	set_physics_process(false)
	await get_tree().physics_frame     # ensure physics state is stable
	global_position = pos
	velocity = Vector3.ZERO
	await get_tree().physics_frame     # let the new position "stick"
	set_physics_process(true)

func setup_vault():
	var grab_global_pos = global_position
	
	grab_global_pos.x = clamp(grab_global_pos.x,
		obstacle.global_position.x - (obstacle.scale.x*0.5),
		obstacle.global_position.x + (obstacle.scale.x*0.5))
	grab_global_pos.z = clamp(grab_global_pos.z,
		obstacle.global_position.z - (obstacle.scale.z*0.5),
		obstacle.global_position.z + (obstacle.scale.z*0.5))
	grab_global_pos.y = obstacle.global_position.y + (obstacle.scale.y*0.5)
	
	
	var approach_dir: Vector3 = (grab_global_pos - global_position).normalized()
	var temp = global_rotation
	var tempPos = global_position
	
	global_rotation = Basis.looking_at(approach_dir, Vector3.UP).get_euler()
	forced_rotation.y = global_rotation.y
	forced_rotation.x = 0
	forced_rotation.z = 0
	target_rotation.y = forced_rotation.y
	cameraControlled = false
	
	var forward = -global_transform.basis.z.normalized()
	forward.y = 0.0
	
	trickCheckpointCount = 3
	trickCheckpoints[1] = grab_global_pos
	trickCheckpoints[1].y -= 0.95
	
	trickCheckpoints[2] = grab_global_pos + (forward * obstacle.scale * 2)
	trickCheckpoints[2].y = trickCheckpoints[1].y
	trickCheckpoints[3] = grab_global_pos + (forward * obstacle.scale * 3)
	trickCheckpoints[3].y = tempPos.y
	
	var trickCheckpointNormalizedTimes = {1: 0.3,2: 0.7,3: 1.0}
	var anim_name = "Vault2"
	var base_length = $AnimationPlayer.get_animation(anim_name).length
	
	trickAnimationSpeed = 1.2
	
	var scaled_length = base_length / trickAnimationSpeed
	
	for i in trickCheckpointNormalizedTimes:
		trickCheckpointTimers[i] = trickCheckpointNormalizedTimes[i] * scaled_length
	
	trickCheckpointCurrent = 1
	trickTimer = 0.0
	
	global_rotation = temp
	velocity = Vector3.ZERO
	target_velocity = Vector3.ZERO
	
	animTree.set("parameters/StateMachine/TrickMachine/BlendTree/TimeScale/scale",trickAnimationSpeed)

func setup_hang():
	trick = true
	is_hanging = true
	
	cameraControlled = false
	sprinting = false
	sprintPressed = false
	
	velocity = Vector3.ZERO
	
	var wall_direction = wallHangFrontRC.get_collision_normal()
	wall_direction.y = 0
	forced_rotation = Basis().looking_at(-wall_direction, Vector3.UP).get_euler()
	
	var hit_point = wallHangFrontRC.get_collision_point()
	var hang_offset = wall_direction * 0.25  # Pull back from the wall a bit
	
	var top_y = find_obstacle_top(global_position, -wall_direction, 1.5,2.5)
	
	var trickCheckpointNormalizedTimes = {1: 1.0,2: 1.0}
	trickCheckpointCount = 2
	trickCheckpoints[1] = hit_point + hang_offset
	trickCheckpoints[1].y = top_y
	trickCheckpoints[2] = hit_point
	trickCheckpoints[2].y = top_y
	trickCheckpoints[3] = hit_point  - (hang_offset *2)
	trickCheckpoints[3].y = top_y
	
	trickAnimationSpeed = 1.8
	
	var anim_name = "WallHang"
	var base_length = $AnimationPlayer.get_animation(anim_name).length
	var scaled_length1 = base_length / trickAnimationSpeed
	var anim_name2 = "WallHangClimb"
	var base_length2 = $AnimationPlayer.get_animation(anim_name2).length
	var scaled_length2 = base_length2 / trickAnimationSpeed
	
	trickCheckpointTimers[1] = trickCheckpointNormalizedTimes[1] * scaled_length1
	trickCheckpointTimers[2] = trickCheckpointNormalizedTimes[2] * scaled_length2
	trickCheckpointTimers[2] += trickCheckpointTimers[1]
	
	trickCheckpointCurrent = 1
	trickTimer = 0.0
	animTree.set("parameters/StateMachine/TrickMachine/BlendTree 2/HANGSPEED/scale",trickAnimationSpeed)
	animTree.set("parameters/StateMachine/TrickMachine/BlendTree 3/HANGSPEED/scale",trickAnimationSpeed)

func perform_vault(delta):
	$CollisionShape3D.disabled = true
	global_position = lerp(global_position,trickCheckpoints[trickCheckpointCurrent],delta*2.0 * trickAnimationSpeed)
	global_position = global_position.move_toward(trickCheckpoints[trickCheckpointCurrent],delta*2.0 * trickAnimationSpeed )
	if trickTimer > trickCheckpointTimers[trickCheckpointCurrent]:
		trickCheckpointCurrent += 1
		if trickCheckpointCurrent > trickCheckpointCount:
			trickCheckpointCurrent = 0
			trickTimer = 0
			trick = false
			vault = false
			cameraControlled = true
			target_rotation.y = global_rotation.y
			$CollisionShape3D.disabled = false
	trickTimer+=delta
	
func perform_hanging(delta):
	if is_multiplayer_authority():
		$CollisionShape3D.disabled = true
		global_position = lerp(global_position,trickCheckpoints[trickCheckpointCurrent],delta*7.0 * trickAnimationSpeed)
		#global_position = global_position.move_toward(trickCheckpoints[trickCheckpointCurrent],delta*2.0 * trickAnimationSpeed )
		if trickTimer > trickCheckpointTimers[trickCheckpointCurrent]:
			trickCheckpointCurrent += 1
			if trickCheckpointCurrent > trickCheckpointCount:
				#trickCheckpointCurrent = 0
				trickTimer = 0
				trick = false
				is_hanging = false
				is_hang_climbing = false
				cameraControlled = true
				target_rotation.y = global_rotation.y
				$CollisionShape3D.disabled = false
				global_position = trickCheckpoints[3]
		trickTimer+=delta

func delayed_camera_enable(delay_time: float):
	await get_tree().create_timer(delay_time).timeout
	cameraControlled = true

func find_obstacle_top(from_pos: Vector3, direction: Vector3, min_y: float, max_y: float, tolerance: float = 0.05) -> float:
	var space_state = get_world_3d().direct_space_state
	
	while abs(max_y - min_y) > tolerance:
		var mid_y = (min_y + max_y) / 2.0
		var ray_origin = from_pos + Vector3(0, mid_y, 0)
		var ray_end = ray_origin + direction * 2.5  # or desired ray length

		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
		query.exclude = [self]

		var result = space_state.intersect_ray(query)
		
		if result:
			min_y = mid_y  # Still hitting, move up
		else:
			max_y = mid_y  # No hit, move down

	return global_position.y + ((min_y + max_y) / 2.0)

func spawn_debug_marker(position: Vector3, text := ""):
	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.25
	mesh_instance.mesh = sphere
	mesh_instance.global_position = position

	# Give it a bright material so it's visible
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0, 0)
	mesh_instance.material_override = mat

	get_tree().root.add_child(mesh_instance)

	if text != "":
		var label := Label3D.new()
		label.text = text
		label.position = Vector3(0, 0.5, 0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		mesh_instance.add_child(label)
