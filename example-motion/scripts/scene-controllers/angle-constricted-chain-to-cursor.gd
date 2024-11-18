extends Node

@export_range(0, 1000) var distanceToTarget := 50.0
@export_range(10, 200) var linkSize := 70.0
@export_range(0, 179) var minimumAngle := 100.0

@onready var cursorMarker := $CursorMarker
@onready var chainLine := $ChainLine

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
		return angleConstrainedConstantDistance(
			current,
			beforeLink,
			beforeLinkFromEnd,
			distance,
			minimumAngle
		)
	

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
