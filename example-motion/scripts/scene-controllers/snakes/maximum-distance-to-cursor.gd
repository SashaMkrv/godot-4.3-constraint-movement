extends Node

@onready var cursorMarker := $CursorMarker
@onready var agentMarker := $AgentMarker

var hasCursorMarker : bool = false:
	get():
		return cursorMarker != null
var hasAgentMarker : bool = false:
	get():
		return agentMarker != null

func _input(event: InputEvent) -> void:
	if not hasCursorMarker:
		return
	if event is InputEventMouse:
		var mouseEvent : InputEventMouse = event
		var position := mouseEvent.position
		cursorMarker.position = position
		updateAgent()

func updateAgent() -> void:
	agentMarker.position = constrainMaximumDistance(
		agentMarker.position,
		cursorMarker.position,
		cursorMarker.width / 2.0
		)

# as opposed to constrain distance, so it's always on the circle
# which you can apply to chain links
# this is great for heads though!
func constrainMaximumDistance(
	agentLocation: Vector2,
	targetLocation: Vector2,
	distance: float) -> Vector2:
		var rawDirection = (targetLocation - agentLocation)
		var currentDistance = rawDirection.length()
		if currentDistance <= distance:
			return agentLocation
		
		return targetLocation - rawDirection.normalized() * distance
