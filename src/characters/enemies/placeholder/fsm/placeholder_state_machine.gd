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
		set_state(states[update_state])


func set_state(new_state):
	if current_state != null:
		current_state.exit(actor)
	current_state = new_state
	new_state.enter(actor, actor.target_position)
	emit_signal("state_changed", new_state.name)
	

