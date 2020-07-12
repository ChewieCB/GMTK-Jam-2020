extends KinematicBody2D

onready var state_machine = $StateMachine

var _point_path = []
var path_start_position = Vector2() setget set_path_start_position
var path_end_position = Vector2() setget set_path_end_position

onready var level = get_parent().get_parent()
onready var tile_map = level.get_node("Floor")
onready var astar_node = level.astar_node
onready var _half_cell_size = level.get_node("Borders").cell_size / 2
onready var graph_nodes = level.walkable_cells

var target_position = null


func _draw() -> void:
	if _point_path:
		var point_start = _point_path[0] - self.position
		var point_end = _point_path[len(_point_path) - 1]

		var last_point = Vector2(point_start.x, point_start.y)# + _half_cell_size
		for index in range(0, len(_point_path)):
			var current_point = Vector2(_point_path[index].x - self.position.x, _point_path[index].y - self.position.y)# + _half_cell_size
			draw_line(last_point, current_point, Color(1, 1, 1, 1), 1.5, true)
			if index == 0:
				draw_circle(current_point, 4, Color(1, 0, 0, 1))
			elif index == len(_point_path) - 1:
				draw_circle(current_point, 4, Color(0, 1, 0, 1))
			else:
				draw_circle(current_point, 4, Color(1, 1, 1, 1))
			last_point = current_point


func _physics_process(delta):
	# Set path start to current cell
	var path_start_position_map = tile_map.world_to_map(self.global_position)
	path_start_position = tile_map.map_to_world(path_start_position_map) + _half_cell_size
	update()


func calculate_point_index(point) -> int:
	var map_limits = tile_map.get_used_rect()
	# Subtract offset from position
	point -= map_limits.position
	return point.y * map_limits.size.x + point.x


func find_path(world_start, world_end) -> Array:
	self.path_start_position = world_start
	self.path_end_position = world_end
	_recalculate_path()
	
	#get_node("Placeholder").state_machine = get_node("Placeholder/StateMachine/MoveState")

	return _point_path


func _recalculate_path() -> void:
	# Make sure start point is the node's current position
	var start_pos_world = tile_map.world_to_map(self.global_position) + _half_cell_size
	self.path_start_position = tile_map.map_to_world(start_pos_world)
	
	var start_point_index = calculate_point_index(path_start_position)
	var end_point_index = calculate_point_index(path_end_position)
	# This method gives us an array of points. Note you need the start and end
	# points' indices as input
	_point_path = astar_node.get_point_path(start_point_index, end_point_index)
	# Redraw the lines and circles from the start to the end point
	update()


func _input(event) -> void:
	# FOR PATH DEBUGGING
	# TODO - add a command for this in the debug console
	if event.is_action_pressed('click'):
		var new_position = tile_map.world_to_map(get_global_mouse_position())
		if Input.is_key_pressed(KEY_SHIFT):
			set_path_start_position(new_position)
		else:
			set_path_end_position(new_position)


# SETTERS

func set_path_start_position(value):
	if not value in graph_nodes:
		print("NOPE!")
		return
	
	if path_end_position and path_end_position != path_start_position:
		path_start_position = value
		self.global_position = Vector2(path_start_position.x, path_start_position.y - tile_map.cell_size.y) 
		_recalculate_path()
		state_machine.set_state(state_machine.states.Move)


func set_path_end_position(value):
	if not value in graph_nodes:
		print("NOPE!")
		return
	
	path_end_position = value
	if path_start_position != value:
		_recalculate_path()
		state_machine.set_state(state_machine.states.Move)







