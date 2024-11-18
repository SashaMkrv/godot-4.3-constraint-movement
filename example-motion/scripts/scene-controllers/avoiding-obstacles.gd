extends Node

@export_range(0, 1000) var distanceToTarget := 50.0
@export_range(10, 200) var linkSize := 70.0
@export_range(0, 179) var minimumAngle := 100.0

@onready var cursorMarker := $CursorMarker
@onready var chainLine := $ChainLine
@onready var obstacles := $Obstacles

var hasCursorMarker : bool = false:
	get():
		return cursorMarker != null

func _input(event: InputEvent) -> void:
	if not hasCursorMarker:
		return
	if event is InputEventMouse:
		var mouseEvent : InputEventMouse = event
		var position := mouseEvent.position
		updateCursorMarker(position)
		updateChainForPoint(position)

func updateCursorMarker(newPosition: Vector2) -> void:
	cursorMarker.position = newPosition

func updateChainForPoint(position: Vector2) -> void:
	var currentLine: PackedVector2Array = chainLine.points.duplicate()
	#currentLine.reverse()
	var nextPoints := nextPositions(position, currentLine)
	#nextPoints.reverse()
	chainLine.points = nextPoints
	
func nextPositions(target: Vector2, _points: PackedVector2Array) -> PackedVector2Array:
	var points := _points.duplicate()
	if points.size() < 1:
		return points
	
	var originalHead := points[0]
	var newHead := headPosition(target, originalHead, distanceToTarget)
	points[0] = newHead
	
	var targetLinkLocation: Vector2 = newHead
	var linkVector:= Vector2.ZERO
	for index in range(1, points.size()):
		var newPoint := bodyLinkPosition(
			targetLinkLocation,
			points[index],
			linkVector,
			linkSize,
			minimumAngle
		)
		points[index] = newPoint
		linkVector = targetLinkLocation - newPoint
		targetLinkLocation = newPoint
		
	return points

func headPosition(
	target: Vector2,
	head: Vector2,
	distance: float
	) -> Vector2:
	return constrainMaximumDistance(
		head,
		target,
		distance
	)

func bodyLinkPosition(
	beforeLink: Vector2,
	current: Vector2,
	beforeLinkFromEnd: Vector2,
	distance: float,
	minimumAngle: float
	) -> Vector2:
		var angleConstrained = angleConstrainedConstantDistance(
			current,
			beforeLink,
			beforeLinkFromEnd,
			distance,
			minimumAngle
		)
		var obstacleConstained = getLocationWithObstacleAvoision(
			beforeLink,
			current,
			distance
		)
		# there is a secret obstacles fetch in here
		# because I'm still not 100% on how to repr
		# the obstacle info.
		
		return obstacleConstained
	

func constrainMaximumDistance(
	currentLocation: Vector2,
	targetLocation: Vector2,
	distance: float
	) -> Vector2:
		var rawDirection := (targetLocation - currentLocation)
		var currentDistance := rawDirection.length()
		if currentDistance <= distance:
			return currentLocation
		
		return targetLocation - rawDirection.normalized() * distance

func constrainConstantDistance(
	currentLocation: Vector2,
	targetLocation: Vector2,
	distance: float
	) -> Vector2:
		var rawDirection := (targetLocation - currentLocation)
		var currentDistance := rawDirection.length()
		
		return targetLocation - rawDirection.normalized() * distance

func angleConstrainedConstantDistance(
	currentLocation: Vector2,
	targetLocation: Vector2,
	previousLinkFromTarget: Vector2,
	distance: float,
	minimumAngleDifference: float
	) -> Vector2:
		var idealLocation := getIdealConstantNodeLocation(
			targetLocation,
			currentLocation,
			distance
		)
		
		if previousLinkFromTarget == Vector2.ZERO:
			return idealLocation
		
		var currentLinkFromTarget := idealLocation - targetLocation
		
		var signedLinkAngle := rad_to_deg(
			previousLinkFromTarget.angle_to(currentLinkFromTarget)
		)
		var linkAngle: float = abs(signedLinkAngle)
		
		if linkAngle >= minimumAngleDifference:
			return idealLocation
		
		var radRotation := deg_to_rad(minimumAngleDifference)
		
		var fromTarget := currentLinkFromTarget
		if signedLinkAngle > 0:
			fromTarget = previousLinkFromTarget.rotated(radRotation)
		else:
			fromTarget = previousLinkFromTarget.rotated(-radRotation)
		
		return targetLocation + fromTarget.normalized() * distance


func getIdealConstantNodeLocation(
	target: Vector2,
	current: Vector2,
	distance: float
	) -> Vector2:
		return constrainConstantDistance(current, target, distance)


# move for all obstacles
# will prioritize last obstacle
func getLocationWithObstacleAvoision(
	target: Vector2,
	_current: Vector2,
	distance: float
) -> Vector2:
	var current = _current
	for obstacle in obstacles._getCircles():
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
			if (
				upper.distance_to(current) <= lower.distance_to(current)
			):
				current = upper
				continue
			else:
				current = lower
				continue
		
		if Geometry2D.segment_intersects_circle(
			target,
			current,
			obstacleLocation,
			obstacleRadius
		):
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
			var upper: Vector2 = candidates[0] * distance
			var lower: Vector2 = candidates[1] * distance
			
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
	radius: float
) -> Array[Vector2]:
	# I miss tuple returns.
	var hypotnuse = (point - circleOrigin).length()
	var opposite = radius
	var theta = asin(opposite/hypotnuse)
	
	var baseVector = (circleOrigin - point).normalized()
	var upper = baseVector.rotated(theta)
	var lower = baseVector.rotated(-theta)
	return [upper, lower]

## We're assuming there IS an intersection here.
func getIntersectionVectors(
	origin1: Vector2,
	radius1: float,
	origin2: Vector2,
	radius2: float
) -> Array[Vector2]:
	var originDistance = (origin1 - origin2).length()
	
	var baseLength1 = (
		pow(radius1, 2.0) - pow(radius2, 2.0) + (originDistance)
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
