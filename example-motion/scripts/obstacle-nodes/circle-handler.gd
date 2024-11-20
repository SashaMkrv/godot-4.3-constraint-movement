extends Node2D

func getCircles() -> Array[CircleInfo]:
	return _getCircles()

# Well, I tried to avoid scripts on the markers
# Then it was more work than could be justified
# Worse, the draw function being on the marker nodes
# is just better. It translates the circle for free :(

#func _ready() -> void:
	#_signalUpdate()
#
#func _notification(what: int) -> void:
	#if what == NOTIFICATION_CHILD_ORDER_CHANGED:
		#_childListChange()
#
#func _marker_redrawn() -> void:
	#print("am i ever called?")
	#_childRectChange()
#
#func _childListChange() -> void:
	#_signalUpdate()
	#queue_redraw()
#
#func _childRectChange() -> void:
	#queue_redraw()

# this will forever adopt the child.
# if you're moving marker nodes around the tree
# ... don't?
#func _signalUpdate() -> void:
	#for child in _getMarkers():
		#if child.draw.is_connected(
			#_marker_redrawn
		#):
			#print("hello? connected?")
			#continue
		#child.draw.connect(
			#_marker_redrawn
		#)
		#print("not connected, but now friends?")

#func _draw() -> void:
	#var circles := _getCircles()
	#for circle in circles:
		#draw_circle(
			#circle.location,
			#circle.radius,
			#Color.GREEN,
			#true)
	#return

func _getCircles() -> Array[CircleInfo]:
	var circles : Array[CircleInfo] = []
	for child in _getMarkers():
		circles.append(
			CircleInfo.new(
				child.position,
				child.radius
			)
		)
	return circles

func _getMarkers() -> Array[Marker2D]:
	var markers: Array[Marker2D] = []
	for child in get_children():
		if child.is_in_group("ObstacleMarker"):
			markers.append(child)
	return markers
