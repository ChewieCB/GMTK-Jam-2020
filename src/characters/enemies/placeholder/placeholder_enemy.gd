extends KinematicBody2D

onready var state_machine = $StateMachine

var _point_path = []
var path_start_position = Vector2() setget set_path_start_position
var path_end_position = Vector2() setget set_path_end_position

onready var floor_map = get_tree().find_node("")
onready var astar_node = tile_map.astar_node
onready var _half_cell_size = tile_map._half_cell_size
onready var graph_nodes = tile_map.graph_nodes

