extends Node
class_name State

"""
This is a base class from which all states extend from, all of it's functions
should be virtual.
"""


func handle_input(entity, delta):
	pass


func update(entity, delta):
	pass


func enter(entity, optional_args=null):
	pass


func exit(entity):
	pass





