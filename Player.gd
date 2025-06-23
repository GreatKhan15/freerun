extends CharacterBody3D

@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var animTree : AnimationTree = $AnimationPlayer/AnimationTree
@onready var spring_arm : SpringArm3D = $SpringArm3D
@onready var obstacleRaycast : RayCast3D = $ObstacleRayCast
@onready var wallLeftRaycast : RayCast3D = $WallLeftRayCast
@onready var wallRightRaycast : RayCast3D = $WallRightRayCast

@export var speed: float = 7.0
@export var jump_strength: float = 12.0
@export var gravity: float = 20.0
@export var slide_time: float = 1.3

var is_wall_running_left: bool = false
var is_wall_running_right: bool = false
var is_wall_running: bool = false


var is_sliding: bool = false
var slide_timer: float = 0.0
var wall_normal: Vector3 = Vector3.ZERO
var player_id: int = 1
var direction : Vector3
var current_direction : Vector2
var input_dir : Vector2
var is_jumping = false
var is_falling = false
var slide_target_scale_y: float = 1.0
var slide_scale_speed: float = 10.0  # larger = faster transition
var target_velocity : Vector3
var target_rotation : Vector3

var DIRECTION_LERP_SPEED = 5.0
var VELOCITY_INTERPOLATION_GROUND = 15.0
var VELOCITY_INTERPOLATION_AIR = 0.5
var WALLRUN_ANTIGRAVITY = 0.1
var SPRINT_MULTIPLIER = 1.3
var ROTATION_INTERPOLATION = 3.0
var BOUNCE_STRENGTH = 9.0
var ACCELERATION_RATE = 3.0
var BRAKE_RATE = 6.0

var sprintPressed = false
var sprinting = false
var jumped = false

@export var mouse_sensitivity = 0.002
var rotation_x = 0.0

func _input(event):
	if camera.current == true:
		if event is InputEventMouseMotion:
			target_rotation.x -= event.relative.y * mouse_sensitivity
			target_rotation.x = clamp(target_rotation.x, deg_to_rad(-89), deg_to_rad(70))
			spring_arm.rotation.x = target_rotation.x
			target_rotation.y -= event.relative.x * mouse_sensitivity
	if event is InputEventKey:
		if event.is_action_pressed("ui_sprint"):
			sprintPressed = true
		elif event.is_action_released("ui_sprint"):
			sprintPressed = false
			
		if event.is_action_pressed("ui_accept"):
			jumped = true
		elif event.is_action_released("ui_accept"):
			jumped = false
	
	
func _ready():
	if multiplayer.get_unique_id() == player_id:
		camera.current = true
	else:
		camera.current = false
	add_to_group("players")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	spring_arm.add_excluded_object(self)
	animTree.active = true
	
	floor_max_angle= deg_to_rad(45)
	floor_snap_length= 3.0

func _process(delta):
	if not is_multiplayer_authority():
		return
		
	current_direction = lerp(current_direction,input_dir,delta*DIRECTION_LERP_SPEED)
	animTree.set("parameters/StateMachine/BlendSpace2D/blend_position",Vector2(current_direction.x,-current_direction.y))
	animTree.set("parameters/StateMachine/conditions/Jumping",is_jumping)
	animTree.set("parameters/StateMachine/conditions/notJumping",!is_jumping)
	animTree.set("parameters/StateMachine/conditions/isSliding",is_sliding)
	animTree.set("parameters/StateMachine/conditions/isFalling",is_falling)
	animTree.set("parameters/StateMachine/conditions/notFalling",!is_falling)
	animTree.set("parameters/StateMachine/conditions/isWallLeft",is_wall_running_left)
	animTree.set("parameters/StateMachine/conditions/isNotWallLeft",!is_wall_running_left)
	animTree.set("parameters/StateMachine/conditions/isWallRight",is_wall_running_right)
	animTree.set("parameters/StateMachine/conditions/isNotWallRight",!is_wall_running_right)
	animTree.set("parameters/StateMachine/conditions/FastRun",sprinting)
	animTree.set("parameters/StateMachine/conditions/notFastRun",!sprinting)
	
	global_rotation.y = move_toward_angle(
		global_rotation.y,
		target_rotation.y,
		ROTATION_INTERPOLATION * delta
	)
	spring_arm.global_rotation.y = target_rotation.y

func move_toward_angle(current: float, target: float, max_delta: float) -> float:
	var diff = angle_difference(current, target)
	var step = clamp(diff, -max_delta, max_delta)
	return current + step

func _physics_process(delta):
	if not is_multiplayer_authority():
		return

	if not is_on_floor() and not is_wall_running: 
		velocity.y -= gravity * delta

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
		is_jumping = false
		is_falling = false
	else:
		target_velocity.x = velocity.x
		target_velocity.z = velocity.z
		is_sliding = false
	
	
	if jumped and is_on_floor():
		velocity.y = jump_strength
		is_jumping = true
		is_sliding = false
		jumped = false
	elif jumped and is_wall_running:
		velocity.y = jump_strength / 1.5
	
		velocity += wall_normal * BOUNCE_STRENGTH
		
		is_jumping = true
		jumped = false
		is_wall_running = false
		is_wall_running_left = false
		is_wall_running_right = false
		
	
	
	# Wall Run
	if not is_on_floor() and not is_wall_running:
		wallRightRaycast.force_raycast_update()
		wallLeftRaycast.force_raycast_update()
		if wallRightRaycast.is_colliding() and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			wall_normal = wallRightRaycast.get_collision_normal()
			if abs(wall_normal.y) < 0.1:  # Ensure it's a wall
				is_wall_running_right = true
				is_wall_running = true
				velocity.y = 0
		elif wallLeftRaycast.is_colliding() and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			wall_normal = wallLeftRaycast.get_collision_normal()
			if abs(wall_normal.y) < 0.1:  # Ensure it's a wall
				is_wall_running_left = true
				is_wall_running = true
				velocity.y = 0
	if is_wall_running:
		velocity.y -= gravity * delta * WALLRUN_ANTIGRAVITY
		if is_on_floor() or (is_wall_running_left and not wallLeftRaycast.is_colliding()) or (is_wall_running_right and not wallRightRaycast.is_colliding()):
			is_wall_running = false
			is_wall_running_left = false
			is_wall_running_right = false


	# Slide
	if Input.is_action_just_pressed("ui_crouch") and is_on_floor() and input_dir.length() > 0 and not is_sliding:
		is_sliding = true
		slide_timer = slide_time
		slide_target_scale_y = 0.3
		
	if is_sliding:
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
	
	var current_y = collision_shape.scale.y
	var new_y = lerp(current_y, slide_target_scale_y, slide_scale_speed * delta)
	collision_shape.scale.y = new_y
	collision_shape.position.y = collision_shape.scale.y
	spring_arm.position.y = collision_shape.position.y
	
	if sprintPressed:
		target_velocity *= SPRINT_MULTIPLIER
	
	if is_on_floor():
		if target_velocity != Vector3.ZERO:
			velocity.x = lerp(velocity.x,target_velocity.x,delta*ACCELERATION_RATE)
			velocity.z = lerp(velocity.z,target_velocity.z,delta*ACCELERATION_RATE)
		else:
			velocity.x = lerp(velocity.x,target_velocity.x,delta*BRAKE_RATE)
			velocity.z = lerp(velocity.z,target_velocity.z,delta*BRAKE_RATE)
			
		#if velocity.x < target_velocity.x:
			#velocity.x += ACCELERATION_RATE
			#if target_velocity.x - velocity.x < ACCELERATION_RATE:
				#velocity.x = target_velocity.x
		#elif velocity.x > target_velocity.x:
			#velocity.x -= BRAKE_RATE
			#if velocity.x - target_velocity.x < BRAKE_RATE:
				#velocity.x = target_velocity.x
				#
		#if velocity.z < target_velocity.z:
			#velocity.z += ACCELERATION_RATE
			#if target_velocity.z - velocity.z < ACCELERATION_RATE:
				#velocity.z = target_velocity.z
		#elif velocity.z > target_velocity.z:
			#velocity.z -= BRAKE_RATE
			#if velocity.z - target_velocity.z < BRAKE_RATE:
				#velocity.z = target_velocity.z
	else:
		velocity.x = lerp(velocity.x,target_velocity.x,delta*VELOCITY_INTERPOLATION_AIR)
		velocity.z = lerp(velocity.z,target_velocity.z,delta*VELOCITY_INTERPOLATION_AIR)
		is_falling = true

	move_and_slide()
	sync_position.rpc(global_position, velocity)

@rpc("unreliable")
func sync_position(pos: Vector3, vel: Vector3):
	global_position = pos
	velocity = vel

func setup_player(id: int,pos: Vector3):
	player_id = id
	name = str(id)
	teleport_to(pos)
	set_multiplayer_authority(id)


func teleport_to(pos: Vector3):
	set_physics_process(false)
	await get_tree().physics_frame     # ensure physics state is stable
	global_position = pos
	velocity = Vector3.ZERO
	await get_tree().physics_frame     # let the new position "stick"
	set_physics_process(true)
