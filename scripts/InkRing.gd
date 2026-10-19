class_name InkRing
extends ColorRect

## Smooth, anti-aliased hand-drawn ellipse rendered entirely in a fragment shader.
## `inner_rect` is the annotation's logical bounds; the visual control is padded
## so the glow is not clipped by the ColorRect.

static var _shader: Shader
var inner_rect := Rect2()
var seed := 0.0
var pad := 8.0

static func _get_shader() -> Shader:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = """
shader_type canvas_item;
render_mode blend_mix;

uniform vec2 rect_size = vec2(100.0, 50.0);
uniform float pad = 8.0;
uniform float seed = 0.0;
uniform vec4 ink_color : source_color = vec4(0.659, 0.227, 0.184, 1.0);
uniform vec4 shadow_color : source_color = vec4(0.435, 0.141, 0.114, 0.30);
uniform vec4 glow_color : source_color = vec4(0.659, 0.227, 0.184, 0.06);

void fragment() {
	vec2 half_size = max(rect_size * 0.5 - vec2(pad), vec2(1.0));
	vec2 q = (UV - 0.5) * rect_size;
	vec2 e = q / half_size;
	float ang = atan(e.y, e.x);
	float wob = 1.0 + 0.010 * sin(ang * 3.0 + seed);
	float scale = min(half_size.x, half_size.y);
	float d = (length(e) - wob) * scale;
	float aa = max(fwidth(d), 0.55);

	float a_main = 1.0 - smoothstep(1.15 - aa, 1.15 + aa, abs(d));
	float a_glow = 1.0 - smoothstep(2.55 - aa, 2.55 + aa, abs(d));

	vec2 q2 = q - vec2(1.2, -1.2);
	vec2 e2 = q2 / half_size;
	float d2 = (length(e2) - wob) * scale;
	float a_shadow = 1.0 - smoothstep(0.55 - aa, 0.55 + aa, abs(d2));

	float a = a_main + a_shadow * shadow_color.a + a_glow * glow_color.a;
	vec3 rgb = (ink_color.rgb * a_main
		+ shadow_color.rgb * a_shadow * shadow_color.a
		+ glow_color.rgb * a_glow * glow_color.a) / max(a, 0.0001);
	COLOR = vec4(rgb, min(a, 1.0));
}
"""
	return _shader

func _init() -> void:
	color = Color.WHITE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 60
	material = ShaderMaterial.new()
	material.shader = _get_shader()

func configure(rect: Rect2, p_seed: float = 0.0) -> void:
	inner_rect = rect
	seed = p_seed
	position = rect.position - Vector2(pad, pad)
	size = rect.size + Vector2(pad, pad) * 2.0
	material.set_shader_parameter("rect_size", size)
	material.set_shader_parameter("pad", pad)
	material.set_shader_parameter("seed", seed)
