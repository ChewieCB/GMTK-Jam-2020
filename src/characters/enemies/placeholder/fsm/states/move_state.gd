extends State

const inputs = {
	"right": Vector2.RIGHT, 
	"left": Vector2.LEFT, 
	"up": Vector2.UP, 
	"down": Vector2.DOWN
}

var tile_size = 16
var movement_direction
var raycast

var target_position = Vector2()
var target_point_world = Vector2()
var path
var is_path_finished = false


func enter(entity, optional_args=null):
	print("%s enter Move State" % [entity.name])
	raycast = entity.get_node("RayCast2D")
	# If no optional args are passed then we don't have a target point to path
	# to and something has fucked up
#	if not _target_position:
#		push_error("_target_positon arg not found, Move state requires a valid position to path to!")
#		var is_path_finished = true
#		return
	path = entity._point_path


func handle_input(entity, _delta):
	if not path or len(path) == 1:
		is_path_finished = true
		return
	else:
		is_path_finished = false
		# The index 0 is the starting cell
		# we don't want the character to move back to it in this example
		target_point_world = entity.tile_map.map_to_world(path[1])

	if is_path_finished:
		return "Idle"
	else:
		var arrived_to_next_point = move_to(entity, target_point_world)
		if arrived_to_next_point:
			path.remove(0)
			entity._point_path.remove(0)
			if len(path) == 0:
				is_path_finished = true
				return "Idle"
			target_point_world = path[0]


func move_to(entity, world_position):
	var ARRIVE_DISTANCE = 2
	var movement_direction = (world_position - entity.position + entity._half_cell_size).normalized()
	# Grid movement
	raycast.cast_to = movement_direction * tile_size / 2
	raycast.force_raycast_update()
	if !raycast.is_colliding():
		entity.position += movement_direction * tile_size
		var test = entity.position.distance_to(world_position)
		return true
	else:
		return false


func exit(entity):
	print("%s exit Move state." % [entity.name])
#	# Set the path start point to the current node position
#	entity.path_start_position = entity.global_position




