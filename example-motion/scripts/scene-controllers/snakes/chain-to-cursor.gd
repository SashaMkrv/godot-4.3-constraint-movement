extends Node

@export_range(0, 1000) var distanceToTarget := 50.0

@onready var cursorMarker := $CursorMarker
@onready var chainLine := $ChainLine
@onready var pointsCalculator := $ChainPointsCalculator

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
	var currentLine = chainLine.points
	chainLine.points = nextPositions(position, currentLine)
	
func nextPositions(target: Vector2, _points: PackedVector2Array) -> PackedVector2Array:
	var points := _points.duplicate()
	if points.size() < 1:
		return points
	
	var originalHead := points[0]
	var newHead := headPosition(target, originalHead, distanceToTarget)
	points[0] = newHead
	
	var targetLinkLocation: Vector2 = newHead
	for index in range(1, points.size()):
		points[index] = bodyLinkPosition(targetLinkLocation, points[index], distanceToTarget)
		targetLinkLocation = points[index]
		
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
	distance: float
	) -> Vector2:
		return constrainConstantDistance(
			current,
			beforeLink,
			distance
		)
	

func constrainMaximumDistance(
	currentLocation: Vector2,
	targetLocation: Vector2,
	distance: float
	) -> Vector2:
		var rawDirection = (targetLocation - currentLocation)
		var currentDistance = rawDirection.length()
		if currentDistance <= distance:
			return currentLocation
		
		return targetLocation - rawDirection.normalized() * distance

func constrainConstantDistance(
	currentLocation: Vector2,
	targetLocation: Vector2,
	distance: float
	) -> Vector2:
		var rawDirection = (targetLocation - currentLocation)
		var currentDistance = rawDirection.length()
		return targetLocation - rawDirection.normalized() * distance
