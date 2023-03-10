extends CharacterBody2D

#基本逻辑在于利用ray.首先利用点乘舍弃与移动方向相反的ray.然后舍弃碰撞到碰撞体的ray.
#最后利用剩下的ray进行移动方向的改变.
#参考了https://www.youtube.com/watch?v=dzqtF_CmX-I这个视频.进行了一点改动.

@onready var nav_2d: NavigationAgent2D = $NavigationAgent2D
const speed = 300
var scope=60#射线长度/范围

var ray_direction=[]
var direction = Vector2.ZERO
var lastPosition = Vector2.ZERO

func _ready():
	ray_direction.resize(8)
	for i in 8:
		var ray_angle=i*2*PI/8
		ray_direction[i]=Vector2.RIGHT.rotated(ray_angle)
		#print(i,'R',ray_direction[i])
		
func _physics_process(_delta):
	if nav_2d.is_navigation_finished() || nav_2d.get_final_location() == Vector2.ZERO:
		return
	#只有在发出寻路指令时才进行ray的判断
	updateDirection()
	velocity = velocity.move_toward(direction * speed, 10)
	move_and_slide()
		
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		nav_2d.set_target_location(event.position)
		nav_2d.get_next_location()
		var navPath = nav_2d.get_nav_path()
		get_parent().get_node("Line2D").points = navPath
		

func updateDirection():
	direction = Vector2.ZERO
	
	var direct_space_state = get_world_2d().direct_space_state
	
	# 如果有碰撞，则8个方向中寻找一个没有发生碰撞并且不是相反方向的继续移动
	for i in 8:
		# 只取目标方向60度角以内的方向
		var dotValue = ray_direction[i].dot((nav_2d.get_next_location() - position).normalized())
		if dotValue < 0:
			continue
		# 判断ray是否碰撞到碰撞体，取第一个没有发生碰撞的方向射线
		var direction_params = PhysicsRayQueryParameters2D.create(position, position + ray_direction[i] * scope, 0xFFFFFFFF, [self.get_rid()])
		if (direct_space_state.intersect_ray(direction_params).is_empty()):
			direction += ray_direction[i] * dotValue
	direction = direction.normalized()
	lastPosition = position
