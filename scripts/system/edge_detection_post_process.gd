extends Node3D
## Edge detection post-processing effect controller
## Provides runtime control over edge detection shader parameters

@onready var effect_mesh: MeshInstance3D = $EdgeDetectionMesh

## Toggle the edge detection effect on/off
func set_enabled(enabled: bool) -> void:
	effect_mesh.visible = enabled

## Toggle shadow edges
func set_shadows_enabled(enabled: bool) -> void:
	effect_mesh.material_override.set_shader_parameter("shadows_enabled", enabled)

## Toggle highlight edges
func set_highlights_enabled(enabled: bool) -> void:
	effect_mesh.material_override.set_shader_parameter("highlights_enabled", enabled)

## Adjust shadow strength
func set_shadow_strength(value: float) -> void:
	effect_mesh.material_override.set_shader_parameter("shadow_strength", value)

## Adjust highlight strength
func set_highlight_strength(value: float) -> void:
	effect_mesh.material_override.set_shader_parameter("highlight_strength", value)

## Set highlight color
func set_highlight_color(color: Color) -> void:
	effect_mesh.material_override.set_shader_parameter("highlight_color", Vector3(color.r, color.g, color.b))

## Set shadow color
func set_shadow_color(color: Color) -> void:
	effect_mesh.material_override.set_shader_parameter("shadow_color", Vector3(color.r, color.g, color.b))

