extends Node2D

@onready var linkLine : Line2D = %LinkLine
@onready var target : CircleMarker = %Target

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		var mouseEvent : InputEventMouse = event
		var mousePosition := mouseEvent.position
		updateCursorMarker(mousePosition)

func getObstacleCircles() -> Array[CircleInfo]:
	var circles: Array[CircleInfo] = []
	for child in get_children():
		if child is CircleMarker and child.is_in_group("obstacle"):
			circles.append(
				CircleInfo.new(
					to_local(child.global_position),
					child.radius
				)
			)
	return circles

func updateCursorMarker(globalPosition: Vector2) -> void:
	var localTargetPosition = to_local(target.global_position)
	var obstacles = getObstacleCircles()
	
	var localMouse = to_local(globalPosition)
	
	var initialPosition = getIdealConstantNodeLocation(
		localTargetPosition,
		localMouse,
		target.radius
	)
	var constrainedPosition = avoidObstacleConstraint(
		initialPosition,
		localTargetPosition,
		target.radius,
		obstacles
	)
	
	var globalConstrainedPosition = to_global(constrainedPosition)
	
	var lineLocalPosition = linkLine.to_local(globalConstrainedPosition)
	linkLine.set_point_position(1, lineLocalPosition)


func getIdealConstantNodeLocation(
	target: Vector2,
	current: Vector2,
	distance: float
	) -> Vector2:
		var rawDirection := (target - current)
		var currentDistance := rawDirection.length()
		
		return target - rawDirection.normalized() * distance


func avoidObstacleConstraint(
	_current: Vector2,
	target: Vector2,
	distance: float,
	obstacles: Array[CircleInfo]
) -> Vector2:
	var current = _current
	for obstacle in obstacles:
		var obstacleLocation = Vector2(obstacle.location)
		var fromObstacleToTarget = target - obstacleLocation
		var obstacleRadius = obstacle.radius
		
		var distanceBetweenOrigins = fromObstacleToTarget.length()
		
		# check if there's anything to calculate
		# too far from target for intersection at all
		if distanceBetweenOrigins >= (
			distance + obstacleRadius
		):
			continue
		
		# check if all possible joint locations are INSIDE
		# the obstacle
		# if yes, good luck, so long!
		if (
			obstacleRadius >= distance
		) and (
			distanceBetweenOrigins < obstacleRadius
		):
			continue
		
		# here is where calculating happens,
		# so first check if there is an intersection
		# at all
		if not checkLineCircleIntersection(
			target,
			current,
			obstacleLocation,
			obstacleRadius
		):
			continue
		
		
		# check if the obstacle is fully inside
		# the circle of the target
		# if yes, we can't use intersections
		# get a tangent lines instead
		# and pick the closest one
		if (
			distance >= obstacleRadius
		) and (
			distanceBetweenOrigins < distance
		):
			var tangents = getTangentVectors(
				target,
				obstacleLocation,
				obstacleRadius
			)
			var upper: Vector2 = tangents[0] * distance
			var lower: Vector2 = tangents[1] * distance
			var upper: Vector2 = tangents[0] * distance + target
			var lower: Vector2 = tangents[1] * distance + target
			if (
				upper.distance_to(current) <= lower.distance_to(current)
			):
				current = upper
				continue
			else:
				current = lower
				continue
		
		# unexpectional intersection
		# get intersection of possible joint locations
		# and obstacle circles
		# return closest one
		var candidates = getIntersectionVectors(
			target,
			distance,
			obstacleLocation,
			obstacleRadius
		)
		var upper: Vector2 = candidates[0]
		var lower: Vector2 = candidates[1]
		
		if (
			upper.distance_to(current) <= lower.distance_to(current)
		):
			current = upper
			continue
		else:
			current = lower
			continue
		
		
		# get intersections, then pick the closest one
		# if there's only one intersection
	return current


func getTangentVectors(
	point: Vector2,
	circleOrigin: Vector2,
	circleRadius: float
) -> Array[Vector2]:
	# I miss tuple returns.
	var hypotnuse = (point - circleOrigin).length()
	var opposite = circleRadius
	var theta = asin(opposite/hypotnuse)
	
	var baseVector = (circleOrigin - point)
	var upper = baseVector.rotated(theta)
	var lower = baseVector.rotated(-theta)
	return [upper.normalized(), lower.normalized()]

## We're assuming there IS an intersection here.
## Godot's functions return packed vector arrays
## which might be a better way to do this
## but everything's a little script-y here as is
func getIntersectionVectors(
	origin1: Vector2,
	radius1: float,
	origin2: Vector2,
	radius2: float
) -> Array[Vector2]:
	var originDistance = (origin1 - origin2).length()
	
	var baseLength1 = (
		pow(radius1, 2.0) - pow(radius2, 2.0) + pow(originDistance, 2.0)
	)/(
		2 * (originDistance)
	)
	
	var height = sqrt(
		pow(radius1, 2.0) - pow(baseLength1, 2.0)
	)
	
	# multiple unit vector by traingle base length
	var lineOfIntersectionCenter = (
		origin2 - origin1
	).normalized() * baseLength1
	
	var yPerp = (origin2.y-origin1.y)/originDistance
	var xPerp = (origin2.x-origin1.x)/originDistance
	
	var upper = Vector2(
		lineOfIntersectionCenter.x + height * yPerp,
		lineOfIntersectionCenter.y + height * xPerp
	)
	var lower = Vector2(
		lineOfIntersectionCenter.x - height * yPerp,
		lineOfIntersectionCenter.y - height * xPerp
	)
	return [upper, lower]


func checkLineCircleIntersection(
	lineFrom: Vector2,
	lineTo: Vector2,
	circleOrigin: Vector2,
	circleRadius: float
) -> bool:
	if Geometry2D.is_point_in_circle(
		lineFrom,
		circleOrigin,
		circleRadius
	) or Geometry2D.is_point_in_circle(
		lineTo,
		circleOrigin,
		circleRadius
	):
		return true
	var closestPoint = Geometry2D.get_closest_point_to_segment(
		circleOrigin,
		lineFrom,
		lineTo
		)
	var distanceFromCircle = (closestPoint - circleOrigin).length()
	var distanceFromLineEnd = (closestPoint - lineTo).length()
	var segmentLength = (lineFrom - lineTo).length()
	return (
		distanceFromCircle < circleRadius
	) and (
		distanceFromLineEnd < segmentLength
	)
	return false

class CircleInfo:
	var location: Vector2i
	var radius: int
	func _init(_location: Vector2i, _radius: int) -> void:
		location = _location
		radius = _radius
