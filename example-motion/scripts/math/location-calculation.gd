extends RefCounted
class_name LocationCalculation

static func constantDistance(
	currentLocation: Vector2,
	target: Vector2,
	distance: float
) -> Vector2:
	var rawDirection := (target - currentLocation)
	var currentDistance := rawDirection.length()
	
	return target - rawDirection.normalized() * distance


static func maximumDistance(
	currentLocation: Vector2,
	target: Vector2,
	distance: float
) -> Vector2:
	var rawDirection := (target - currentLocation)
	var currentDistance := rawDirection.length()
	
	if currentDistance <= distance:
		return currentLocation
	
	return target - rawDirection.normalized() * distance


static func minimumDistance(
	currentLocation: Vector2,
	target: Vector2,
	distance: float
) -> Vector2:
	var rawDirection := (target - currentLocation)
	var currentDistance := rawDirection.length()
	
	if currentDistance >= distance:
		return currentLocation
	
	return target - rawDirection.normalized() * distance


static func minimumAngle(
	currentLocation: Vector2,
	target: Vector2,
	previousLinkFromTarget: Vector2,
	distance: float,
	minimumAngleInDegrees: float
) -> Vector2:
	if previousLinkFromTarget == Vector2.ZERO:
		return currentLocation
	
	var currentJointFromTarget := currentLocation - target
	
	var signedLinkAngle := rad_to_deg(
		previousLinkFromTarget.angle_to(currentJointFromTarget)
	)
	var linkAngle: float = abs(signedLinkAngle)
	
	if linkAngle >= minimumAngleInDegrees:
		return currentLocation
	
	var radRotation := deg_to_rad(minimumAngleInDegrees)
	
	var fromTarget := currentJointFromTarget
	if signedLinkAngle > 0:
		fromTarget = previousLinkFromTarget.rotated(radRotation)
	else:
		fromTarget = previousLinkFromTarget.rotated(-radRotation)
	
	return target + fromTarget.normalized() * distance


static func avoidObstacles(
	_current: Vector2,
	target: Vector2,
	distance: float,
	obstacles: Array[CircleInfo],
	ideal: Vector2 = _current
) -> Vector2:
	var current = _current
	
	for obstacle in obstacles:
		current = avoidObstacle(
			current,
			target,
			distance,
			obstacle,
			ideal
		)
	
	return current


static func avoidObstacle(
	_current: Vector2,
	target: Vector2,
	distance: float,
	obstacle: CircleInfo,
	ideal: Vector2 = _current
) -> Vector2:
	var current = _current
	
	var obstacleLocation = obstacle.location
	var fromObstacleToTarget = target - obstacleLocation
	var obstacleRadius = obstacle.radius
	# this keeps the links from sticking to the obstacles
	var obstacleBuffer = 1.0
	
	var distanceBetweenOrigins = fromObstacleToTarget.length()
	
	# check if there's anything to calculate
	# too far from target for intersection at all
	if distanceBetweenOrigins >= (distance + obstacleRadius):
		return current
	
	# check if all possible link locations intersect
	# the obstacle, i.e. the target is inside the obstacle
	# if yes, good luck, so long!
	if (
		obstacleRadius > distance
	) and (
		distanceBetweenOrigins < obstacleRadius
	) and not (
		# this keeps wobbling around obstacles from happening
		is_equal_approx(distanceBetweenOrigins, obstacleRadius)
	):
		return current
	
	# check if there is an intersection at all
	if not WormGeometry.lineIntersectsCircle(
		target,
		current,
		obstacleLocation,
		obstacleRadius
	):
		return current
	
	# check if the circle intersection would result in the link
	# intersecting the obstacle
	# reasoning being that a tangent point further out than the circles'
	# intersections (which are always `distance` away from the target)
	# then it is too wide an angle for us
	# if it's closer, then the angle of the intersection is
	# too shallow and the line to an intersection will cut into the obstacle.
	var distanceToTangent = WormGeometry.distanceToTangent(
		current,
		obstacleLocation,
		obstacleRadius + obstacleBuffer
	)
	if (
		distanceToTangent < distance
	):
		# if yes, return the closest tangent
		var tangents = WormGeometry.tangentVectors(
			target,
			obstacleLocation,
			obstacleRadius + obstacleBuffer
		)
		
		return WormGeometry.closestPoint(
			ideal,
			tangents
		)
		
	else:
		# if not, get the intersections between the link and the obstacle,
		# return the closest one
		var intersections = WormGeometry.circleIntersections(
			target,
			distance,
			obstacleLocation,
			obstacleRadius + obstacleBuffer
		)
		
		return WormGeometry.closestPoint(
			ideal,
			intersections
		)
