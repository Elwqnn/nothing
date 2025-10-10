extends CanvasLayer
## vhs post-processing effect controller
## allows runtime toggling and parameter adjustment of the retro vhs shader

@onready var vhs_effect: ColorRect = $VHSEffect

## toggle the vhs effect on/off
func set_enabled(enabled: bool) -> void:
	vhs_effect.visible = enabled

## adjust the chromatic aberration strength
func set_aberration(value: float) -> void:
	vhs_effect.material.set_shader_parameter("aberration_strength", value)

## adjust the blur intensity
func set_blur(value: float) -> void:
	vhs_effect.material.set_shader_parameter("blur_strength", value)

## adjust the noise/grain intensity
func set_noise(value: float) -> void:
	vhs_effect.material.set_shader_parameter("noise_strength", value)

## adjust the vignette darkness
func set_vignette(value: float) -> void:
	vhs_effect.material.set_shader_parameter("vignette_strength", value)

## adjust the scanline intensity
func set_scanlines(value: float) -> void:
	vhs_effect.material.set_shader_parameter("scanline_strength", value)

## adjust the screen distortion/warping
func set_distortion(value: float) -> void:
	vhs_effect.material.set_shader_parameter("distortion_strength", value)

## adjust the ghosting effect strength
func set_ghost(value: float) -> void:
	vhs_effect.material.set_shader_parameter("ghost_strength", value)

## adjust the screen flicker intensity
func set_flicker(value: float) -> void:
	vhs_effect.material.set_shader_parameter("flicker_strength", value)
