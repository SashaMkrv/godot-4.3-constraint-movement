extends RefCounted
class_name CircleInfo

var location: Vector2
var radius: int

func _init(_location: Vector2, _radius: int) -> void:
	location = _location
	radius = _radius
