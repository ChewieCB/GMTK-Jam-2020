extends KinematicBody2D

var current_state = ""


func _process(delta):
	$DebugUI/State.text = current_state
 

