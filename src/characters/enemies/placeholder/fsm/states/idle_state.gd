extends State


func enter(entity, optional_args=null):
	print("%s enter idle state." % [entity.name])


func handle_input(entity, delta):
	pass


func exit(entity):
	print("%s exit idle state." % [entity.name])

