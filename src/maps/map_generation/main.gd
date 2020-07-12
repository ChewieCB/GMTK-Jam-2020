extends Node2D

var Room = preload("res://src/maps/map_generation/room/Room.tscn")
var Player = preload("res://src/characters/player/Player.tscn")

onready var tile_map = $Borders
onready var floor_map = $Floor
onready var wall_map = $Wall

var top_left
var bottom_right

var tile_size = 16
var num_rooms = 20
var min_size = 4
var max_size = 8
var hspread = 150
var vspread = 150
var cull = 0.6

var corridor_path # AStar pathfinding object

# Pathfinding
var astar_node = AStar2D.new()
var walkable_cells = []

# Enemy spawning
var nodes_to_spawn
var PlaceholderEnemy = preload("res://src/characters/enemies/placeholder/PlaceholderEnemy.tscn")


func _ready():
	randomize()
	make_rooms()


func _input(event):
	if Input.is_action_pressed("reset"):
		get_tree().reload_current_scene()


func _draw():
	if walkable_cells:
		for cell in walkable_cells:
			draw_circle(floor_map.map_to_world(cell) + floor_map.cell_size / 2, 3, Color(1, 1, 1, 1))


func _process(_delta):
	update()


func make_rooms():
	# Generate some rooms
	for _i in range(num_rooms):
		var _position = Vector2(rand_range(-hspread, hspread), rand_range(-vspread, vspread))
		var room = Room.instance()
		var room_width = min_size + randi() % (max_size - min_size)
		var room_height = min_size + randi() % (max_size - min_size)
		room.make_room(_position, Vector2(room_width, room_height) * tile_size)
		$Rooms.add_child(room)
	
	# Wait for the movement to stop
	yield(get_tree().create_timer(0.5), 'timeout')
	
	# Cull rooms
	var room_positions = []
	for room in $Rooms.get_children():
		if randf() < cull:
			room.queue_free()
		else:
			room.mode = RigidBody2D.MODE_STATIC
			room_positions.append(room.position)
	yield(get_tree(), 'idle_frame')
	
	# Generate a minimum spanning tree connecting the rooms
	corridor_path = find_mst(room_positions)
	yield(get_tree(), 'idle_frame')
	
	# Build the map
	make_map()
	yield(get_tree().create_timer(0.5), 'timeout')
	make_walls()
	yield(get_tree().create_timer(0.5), 'timeout')
	
	# Generate the pathfinding graph
	generate_pathfinding_nodes()
	
	place_nodes()
	
	# Place player
	var floor_tiles = floor_map.get_used_cells()
	var spawn_tiles = []
	# Limit spawn points to tiles within rooms
	var spawn_room = $Rooms.get_children()[rand_range(0, len($Rooms.get_children()))]
	var room_extents = spawn_room.get_node("CollisionShape2D").shape.extents
	var spawn_position = Vector2(
		rand_range(spawn_room.position.x + floor_map.cell_size.x * 2, spawn_room.position.x + room_extents.x - floor_map.cell_size.x * 2),
		rand_range(spawn_room.position.y + floor_map.cell_size.y * 2, spawn_room.position.y + room_extents.y - floor_map.cell_size.y * 2)
	) 
	var spawn_cell = floor_map.world_to_map(spawn_position)
	
	var player = Player.instance()
	player.global_position = floor_map.map_to_world(spawn_cell)
	add_child(player)



func make_map():
	# Create a tilemap from the generated rooms and corridor_path
	tile_map.clear()
	# Get the size of the map
	var full_rect = Rect2()
	for room in $Rooms.get_children():
		var _rect = Rect2(room.position - room.size,
						room.get_node("CollisionShape2D").shape.extents * 2)
		full_rect = full_rect.merge(_rect)
	# Set loop bounds
	top_left = tile_map.world_to_map(full_rect.position - tile_map.cell_size)
	bottom_right = tile_map.world_to_map(full_rect.end + tile_map.cell_size)
	# Loop over positions and set tiles to solid
	for x in range(top_left.x, bottom_right.x):
		for y in range(top_left.y, bottom_right.y):
			tile_map.set_cell(x, y, 0)
	# Create the map geometry
	carve_rooms()
	make_floors()


func carve_rooms():
	var corridors = []
	for room in $Rooms.get_children():
		var room_size = (room.size / tile_size).floor()
		var room_position = tile_map.world_to_map(room.position)
		var room_upper_left = (room.position / tile_map.cell_size.x).floor() - room_size
		for x in range(2, room_size.x * 2 - 1):
			for y in range(2, room_size.y * 2 - 1):
				tile_map.set_cell(room_upper_left.x + x, room_upper_left.y + y, -1)
		
		# Carve connecting corridor
		var point = corridor_path.get_closest_point(room.position)
		for connection in corridor_path.get_point_connections(point):
			if not connection in corridors:
				var start = tile_map.world_to_map(corridor_path.get_point_position(point))
				var end = tile_map.world_to_map(corridor_path.get_point_position(connection))
				carve_path(start, end)
		corridors.append(point)


func carve_path(pos1, pos2):
	# Carves a corridor_path between two points
	var x_diff = sign(pos2.x - pos1.x)
	var y_diff = sign(pos2.y - pos1.y)
	if x_diff == 0: x_diff = pow(-1.0, randi() % 2)
	if y_diff == 0: y_diff = pow(-1.0, randi() % 2)
	# Carve either x/y or y/x
	var x_y = pos1
	var y_x = pos2
	if (randi() % 2) > 0:
		x_y = pos2
		y_x = pos1
	for x in range(pos1.x, pos2.x, x_diff):
		tile_map.set_cell(x, x_y.y, -1)
		tile_map.set_cell(x, x_y.y + y_diff, -1)  # widen the corridor
		tile_map.set_cell(x, x_y.y + 2 * y_diff, -1)
	for y in range(pos1.y, pos2.y, y_diff):
		tile_map.set_cell(y_x.x, y, -1)
		tile_map.set_cell(y_x.x + x_diff, y, -1)  # widen the corridor


func make_floors():
	# Place the floors in empty spaces
	for x in range(top_left.x, bottom_right.x):
		for y in range(top_left.y, bottom_right.y):
			if tile_map.get_cellv(Vector2(x, y)) == -1:
				# Randomly scatter broken floor tiles about
				if randf() < 0.02:
					# Broken Tiles
					floor_map.set_cell(x, y, rand_range(4, 7))
				else:
					# Normal Tiles
					floor_map.set_cell(x, y, rand_range(0, 3))
	
	# Update the autotile
	tile_map.update_bitmask_region(top_left, bottom_right)


func make_walls():
	# Get all the floor tiles
	var floor_tiles = floor_map.get_used_cells()
	var possible_wall_tiles = []
	# Filter out the ones that do not have space above them
	for tile in floor_tiles:
		var tile_above = tile + Vector2(0, -1)
		if floor_map.get_cellv(tile_above) == -1:
			possible_wall_tiles.append(tile)
	
	# Draw 2 high walls in place of some floor tiles
	for free_tile in possible_wall_tiles:
		var tile_below = free_tile + Vector2(0, 1)
		# Take the free tile as the top of the walland  the cell below as 
		# the bottom of the wall
		wall_map.set_cellv(free_tile, 0)
		wall_map.set_cellv(tile_below, 0)

	# Update the autotile
	floor_map.update_bitmask_region(top_left, bottom_right)
	wall_map.update_bitmask_region(top_left, bottom_right)


func find_mst(nodes):
	# Prim's algorithm
	# Given an array of positions (nodes), generates a minimum
	# spanning tree
	# Returns an AStar object

	# Initialize the AStar and add the first point
	var _path = AStar2D.new()
	_path.add_point(_path.get_available_point_id(), nodes.pop_front())

	# Repeat until no more nodes remain
	while nodes:
		var min_distance = INF  # Minimum distance found so far
		var min_position = null  # Position of that node
		var current_position = null  # Current position
		# Loop through the points in the _path
		for p1 in _path.get_points():
			p1 = _path.get_point_position(p1)
			# Loop through the remaining nodes in the given array
			for p2 in nodes:
				# If the node is closer, make it the closest
				if p1.distance_to(p2) < min_distance:
					min_distance = p1.distance_to(p2)
					min_position = p2
					current_position = p1
		# Insert the resulting node into the _path and add
		# its connection
		var new_node_index = _path.get_available_point_id()
		_path.add_point(new_node_index, min_position)
		_path.connect_points(_path.get_closest_point(current_position), new_node_index)
		# Remove the node from the array so it isn't visited again
		nodes.erase(min_position)
	return _path


func place_nodes():
	nodes_to_spawn = 1 #int(rand_range(50, 200))
	# Get all the floor tiles as possible spawn points
	var floor_tiles = floor_map.get_used_cells()
	var spawn_tiles = []
	# Limit spawn points to tiles within rooms
	for room in $Rooms.get_children():
		# Skip some rooms
		var room_extents = room.get_node("CollisionShape2D").shape.extents
		for _i in range(rand_range(0, 4)):
			if nodes_to_spawn > 0:
				var spawn_position
				var is_spawned = false
				while not is_spawned:
					spawn_position = Vector2(
						rand_range(room.position.x + floor_map.cell_size.x * 2, room.position.x + room_extents.x - floor_map.cell_size.x * 2),
						rand_range(room.position.y + floor_map.cell_size.y * 2, room.position.y + room_extents.y - floor_map.cell_size.y * 2)
					) 
					var spawn_cell = floor_map.world_to_map(spawn_position)
					
					# Check if there are any enemies in surrounding cells
					var surrounding_cells = [
						Vector2(-floor_map.cell_size.x, 0),
						Vector2(0, -floor_map.cell_size.y),
						Vector2(floor_map.cell_size.x, 0),
						Vector2(0, floor_map.cell_size.y),
					]
					for cell in surrounding_cells:
						var _neighbor = spawn_cell + cell
						if _neighbor in spawn_tiles:
							continue
					
					if not spawn_cell in spawn_tiles:
						spawn_tiles.append(spawn_cell)
						nodes_to_spawn -= 1
						is_spawned = true
					else:
						continue
	
	# Place enemies
	for tile in spawn_tiles:
		var enemy = PlaceholderEnemy.instance()
		var spawn_position = floor_map.map_to_world(tile)
		enemy.global_position = spawn_position
		$Enemies.add_child(enemy)
	# Make sure enemies don't spawn near/in the same room as the player
	# TODO


func generate_pathfinding_nodes():
	# Generate the AStar nodes
	walkable_cells = floor_map.get_used_cells()
	var pathfinding_nodes = []
	# Loop through the walkable cells and add them to the AStar node
	for cell in walkable_cells:
		# Remove any cells that overlap with wall tiles
		if wall_map.get_cellv(cell) != -1 or tile_map.get_cellv(cell) != -1:
			walkable_cells.erase(cell)
		else:
#			var cell_world = floor_map.map_to_world(cell)
			astar_node.add_point(calculate_point_index(cell), cell)
			pathfinding_nodes.append(cell)
	
	# Connect the astar nodes
	for point in pathfinding_nodes:
		var point_index = calculate_point_index(point)
		# For every cell in the map, we check the one to the top, right.
		# left and bottom of it. If it's in the map and not an obstalce,
		# We connect the current point with it
		var points_relative = PoolVector2Array([
			Vector2(point.x + 1, point.y),
			Vector2(point.x - 1, point.y),
			Vector2(point.x, point.y + 1),
			Vector2(point.x, point.y - 1)])
		for point_relative in points_relative:
			var point_relative_index = calculate_point_index(point_relative)
			
			if not astar_node.has_point(point_relative_index):
				continue
			
			astar_node.connect_points(point_index, point_relative_index, true)


func calculate_point_index(point) -> int:
	var map_limits = tile_map.get_used_rect()
	# Subtract offset from position
	point -= map_limits.position
	return point.y * map_limits.size.x + point.x
