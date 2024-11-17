extends Node2D

@export_range(0, 500) var distanceToTarget := 200.0:
	set(value):
		distanceToTarget = value
		respecVisuals()
@export_range(0, 179) var minimumAngle := 90:
	set(value):
		minimumAngle = value
		respecVisuals()

@onready var nextLinkLine := $NextLink
@onready var previousLinkLine := $PreviousLink
@onready var distanceMarker := $DistanceMarker
@onready var positiveAngleLine := $AngleRangePositive
@onready var negativeAngleLine := $AngleRangeNegative

func _ready() -> void:
	respecVisuals()

func respecVisuals() -> void:
	if not is_node_ready():
		return
	distanceMarker.width = distanceToTarget * 2.0
	var baseVector: Vector2 = previousLinkLine.points[1]
	updateVectorVisual(
		previousLinkLine, recalculateLine(
			0,
			distanceToTarget,
			baseVector
		)
	)
	updateVectorVisual(
		positiveAngleLine, recalculateLine(
			minimumAngle,
			distanceToTarget,
			baseVector
		)
	)
	updateVectorVisual(
		negativeAngleLine, recalculateLine(
			-minimumAngle,
			distanceToTarget,
			baseVector
		)
	)

func updateVectorVisual(line: Line2D, newEndpoint: Vector2) -> void:
	line.set_point_position(
		1, newEndpoint
	)

func recalculateLine(newAngle: float, newLength: float, originalTarget: Vector2):
	return originalTarget.rotated(
		deg_to_rad(newAngle)
	).normalized() * newLength
	

func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		var mouseEvent : InputEventMouse = event
		var mousePosition := mouseEvent.position
		var localPosition = mousePosition - global_position
		updateCursorMarker(localPosition)

func updateCursorMarker(newPosition: Vector2) -> void:
	var angleConstrained = angleConstrainedConstantDistance(
		newPosition,
		Vector2.ZERO,
		previousLinkLine.points[1],
		distanceToTarget,
		minimumAngle
	)
	updateVectorVisual(
		nextLinkLine, recalculateLine(
			0,
			distanceToTarget,
			angleConstrained
		)
	)

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
		
		var angleChange := minimumAngleDifference - linkAngle
		var fromTarget := currentLinkFromTarget
		
		var radRotation := deg_to_rad(minimumAngleDifference)
		
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
		var rawDirection := (target - current)
		var currentDistance := rawDirection.length()
		
		return target - rawDirection.normalized() * distance
