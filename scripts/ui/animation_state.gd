class_name AnimationState extends Resource
## defines an animation state for AnimationComponentV2

@export_group("General")
@export var enabled: bool = true
@export var duration: float = 0.3
@export var delay: float = 0.0
@export var parallel: bool = true
@export var transition: Tween.TransitionType = Tween.TRANS_SINE
@export var easing: Tween.EaseType = Tween.EASE_OUT

@export_group("Transform")
@export var animate_scale: bool = false
@export var scale: Vector2 = Vector2.ONE

@export var animate_position: bool = false
@export var position: Vector2 = Vector2.ZERO  # relative to default

@export var animate_rotation: bool = false
@export var rotation: float = 0.0  # in degrees, relative to default

@export_group("Appearance")
@export var animate_size: bool = false
@export var size: Vector2 = Vector2.ZERO  # relative to default

@export var animate_modulate: bool = false
@export var modulate: Color = Color.WHITE
