extends RigidBody2D
class_name Room

var size


func make_room(_position, _size):
	position = _position
	size = _size
	var shape = RectangleShape2D.new()
	shape.custom_solver_bias = 0.5
	shape.extents = size
	$CollisionShape2D.shape = shape
