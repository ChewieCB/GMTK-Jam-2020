extends Node

signal state_changed(new_state)

# Root entity
onready var actor = get_parent()
# Possible States
onready var states = {
	"Idle": get_node($IdleState.get_path()),
	"Move": get_node($MoveState.get_path()),
}
# State Management
var current_state setget set_state
var next_state


func _ready():
	set_state(states.Idle)


func _physics_process(delta):
	# Update the current state
	current_state.update(actor, delta)
	# Check if the state needs changing
	var update_state = current_state.handle_input(actor, delta)
	if update_state != null:
		# If length is 2, the return has an array of optional args to pass
		if len(update_state) == 2:
			set_state(states[update_state[0]], update_state[1])
			actor.current_state = update_state[0]
		else:
			set_state(states[update_state])
			actor.current_state = update_state


func set_state(new_state, optional_args=null):
	if current_state != null:
		current_state.exit(actor)
	current_state = new_state
	if optional_args:
		new_state.enter(actor, optional_args)
	else:
		new_state.enter(actor)
	emit_signal("state_changed", new_state.name)
	

