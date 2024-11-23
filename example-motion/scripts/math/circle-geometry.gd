extends RefCounted
class_name WormGeometry

static func tangentVectors(
	point: Vector2,
	circleOrigin: Vector2,
	circleRadius: float
) -> PackedVector2Array:
	# I miss tuple returns.
	var hypotnuse = (point - circleOrigin).length()
	var opposite = circleRadius
	var theta = asin(opposite/hypotnuse)
	
	var baseVector = (circleOrigin - point)
	var upper = baseVector.rotated(theta)
	var lower = baseVector.rotated(-theta)
	return [upper.normalized(), lower.normalized()]

# We're assuming there ARE intersection here.
# Though I think this is just NaNs if not.
static func circleIntersections(
	origin1: Vector2,
	radius1: float,
	origin2: Vector2,
	radius2: float
) -> PackedVector2Array:
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

static func lineIntersectsCircle(
	lineFrom: Vector2,
	lineTo: Vector2,
	circleOrigin: Vector2,
	circleRadius: float
) -> bool:
	# the segment mentioned is the point
	var closestPoint = Geometry2D.get_closest_point_to_segment(
		circleOrigin,
		lineFrom,
		lineTo
	)
	var distanceFromCircleOrigin = (closestPoint - circleOrigin).length()
	return (distanceFromCircleOrigin < circleRadius)

static func distanceToTangent(
	point: Vector2,
	circleOrigin: Vector2,
	circleRadius: float
) -> float:
	var distanceToOrigin = (circleOrigin - point).length()
	
	return sqrt(
		pow(distanceToOrigin, 2.0) + pow(circleRadius, 2.0)
	)

static func closestPoint(
	target: Vector2,
	candidates: PackedVector2Array
) -> Vector2:
	if candidates.size() == 0:
		# >:( well don't do that. Please.
		return Vector2.ZERO
	
	var closest := candidates[0]
	var closestDistance := (closest - target).length()
	var currentDistance: float
	# redoes the first one, sorry.
	for candidate in candidates:
		currentDistance = (candidate - target).length()
		if currentDistance < closestDistance:
			closest = candidate
			closestDistance = currentDistance
	
	return closest

static func lineIntersectsCircleVeryExtra(
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
	
	# I don't believe this is wrong per se,
	# but i don't know why i did that second check.
	# did i think the closest point wasn't always on the segment?
	var distanceFromCircleOrigin = (closestPoint - circleOrigin).length()
	var distanceFromLineEnd = (closestPoint - lineTo).length()
	var segmentLength = (lineFrom - lineTo).length()
	
	return (
		distanceFromCircleOrigin < circleRadius
	) and (
		distanceFromLineEnd < segmentLength
	)
	return false
