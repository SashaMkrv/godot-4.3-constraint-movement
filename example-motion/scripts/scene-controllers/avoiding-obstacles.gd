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
		var constantIdeal = constrainConstantDistance(
			current,
			beforeLink,
			distance
		)
		var angleConstrained = angleConstrainedConstantDistance(
			constantIdeal,
			beforeLink,
			beforeLinkFromEnd,
			distance,
			minimumAngle
		)
		var obstacleConstrained = getLocationWithObstacleAvoision(
			angleConstrained,
			beforeLink,
			distance,
			constantIdeal
		)
		# there is a secret obstacles fetch in here
		# because I'm still not 100% on how to repr
		# the obstacle info.
		
		return obstacleConstrained
	

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
		if previousLinkFromTarget == Vector2.ZERO:
			return currentLocation
		
		var currentLinkFromTarget := currentLocation - targetLocation
		
		var signedLinkAngle := rad_to_deg(
			previousLinkFromTarget.angle_to(currentLinkFromTarget)
		)
		var linkAngle: float = abs(signedLinkAngle)
		
		if linkAngle >= minimumAngleDifference:
			return currentLocation
		
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
	_current: Vector2,
	target: Vector2,
	distance: float,
	ideal: Vector2 = _current
) -> Vector2:
	var current = _current
	for obstacle in obstacles._getCircles():
		var obstacleLocation = obstacle.location
		var fromObstacleToTarget = target - obstacleLocation
		var obstacleRadius = obstacle.radius
		var obstacleBuffer = 1.0
		
		var distanceBetweenOrigins = fromObstacleToTarget.length()
		
		# check if there's anything to calculate
		# too far from target for intersection at all
		if distanceBetweenOrigins >= (
			distance + obstacleRadius
		):
			continue
		
		# check if all possible link locations intersect
		# the obstacle
		# if yes, good luck, so long!
		if (
			obstacleRadius > distance
		) and (
			distanceBetweenOrigins < obstacleRadius
		) and not (
			is_equal_approx(distanceBetweenOrigins, obstacleRadius)
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
				obstacleRadius + obstacleBuffer
			)
			var upper: Vector2 = tangents[0] * distance + target
			var lower: Vector2 = tangents[1] * distance + target
			
			if (
				upper.distance_to(ideal) <= lower.distance_to(ideal)
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
		
		# this is not a good result if the target
		# is too close to the obstacle.
		var candidates = getIntersectionVectors(
			target,
			distance,
			obstacleLocation,
			obstacleRadius + obstacleBuffer
		)
		var upperIntersection: Vector2 = candidates[0]
		var lowerIntersection: Vector2 = candidates[1]
		
		if (
			upperIntersection.distance_to(ideal) <= lowerIntersection.distance_to(ideal)
		):
			current = upperIntersection
		else:
			current = lowerIntersection
		
		# check if the previous result intersects.
		# if it does, grab the tangent instead.
		# isn't it cool how much computers can compute?
		# what a mess.
		# I bet there's some actual math I could do
		# to check which one to use.
		if not checkLineCircleIntersection(
			target,
			current,
			obstacleLocation,
			obstacleRadius
		):
			continue
		
		var tangents = getTangentVectors(
				target,
				obstacleLocation,
				obstacleRadius + obstacleBuffer
			)
		var upperTangent: Vector2 = tangents[0] * distance + target
		var lowerTangent: Vector2 = tangents[1] * distance + target
		
		if (
			upperTangent.distance_to(ideal) <= lowerTangent.distance_to(ideal)
		):
			current = upperTangent
			continue
		else:
			current = lowerTangent
			continue
		
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
	var originDistance = (origin2 - origin1).length()
	
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
	).normalized() * baseLength1 + origin1
	
	var unitBaseDirection = (
		origin2 - origin1
	).normalized()
	var perpindicularUpper = Vector2(
		unitBaseDirection.y,
		-unitBaseDirection.x
	) * height
	var perpindicularLower = Vector2(
		-unitBaseDirection.y,
		unitBaseDirection.x
	) * height
	
	
	var upper = perpindicularUpper + lineOfIntersectionCenter
	var lower = perpindicularLower + lineOfIntersectionCenter
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
