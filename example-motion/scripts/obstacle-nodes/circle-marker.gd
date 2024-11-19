@tool
extends Node2D
class_name CircleMarker

@export_color_no_alpha var fillColor:= Color.GREEN:
	set(value):
		fillColor = value
		queue_redraw()
		
@export var fill: bool = true:
	set(value):
		fill = value
		queue_redraw()

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
		fillColor,
		fill
	)

func _ready() -> void:
	queue_redraw()
