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

var is_move_complete


func enter(entity, optional_args=null):
	print("Enter Move State")
	is_move_complete = false
	movement_direction = optional_args[0]
	raycast = entity.get_node("RayCast2D")
	# Try and move
	is_move_complete = move(entity, movement_direction)


func move(entity, direction):
	raycast.cast_to = inputs[direction] * tile_size
	raycast.force_raycast_update()
	if !raycast.is_colliding():
		entity.position += inputs[direction] * tile_size
	
	return true


func handle_input(entity, delta):
	if is_move_complete:
		return "Idle"


func exit(entity):
	print("Exit Move state.")






