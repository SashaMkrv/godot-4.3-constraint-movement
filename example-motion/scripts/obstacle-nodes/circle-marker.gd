@tool
extends Node2D
class_name CircleMarker

signal radius_changed(newValue: int)

@export_range(1, 10000) var radius: int = 100:
	set(value):
		radius = value
		radius_changed.emit(radius)
		queue_redraw()

func _draw() -> void:
	draw_circle(
		Vector2i.ZERO,
		radius,
		Color.GREEN,
		true
	)
