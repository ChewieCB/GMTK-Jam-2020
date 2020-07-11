extends State

const inputs = {
	"right": Vector2.RIGHT, 
	"left": Vector2.LEFT, 
	"up": Vector2.UP, 
	"down": Vector2.DOWN
}


func enter(entity, optional_args=null):
	print("Enter idle state.")


func handle_input(entity, delta):
	for input in inputs:
		if Input.is_action_just_pressed(input):
			return ["Move", [input]]


func exit(entity):
	print("Exit idle state.")

