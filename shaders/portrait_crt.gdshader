shader_type canvas_item;
render_mode unshaded;

// 03 窗口 · 立绘 CRT / 低色深滤镜
// 对应 WebGL 版：桶形畸变 + RGB 色散 + 扫描线 + 颗粒 + 暗角 + 压黑冷紫 + 色阶量化

uniform float intensity : hint_range(0.0, 1.0) = 1.0;
uniform float scan_strength : hint_range(0.0, 1.0) = 0.18;
uniform float scan_freq = 900.0;
uniform float scan_speed = 6.0;
uniform float grain_strength : hint_range(0.0, 0.2) = 0.07;
uniform float chroma : hint_range(0.0, 0.02) = 0.0016;
uniform float levels : hint_range(2.0, 64.0) = 28.0;
uniform float vignette : hint_range(0.0, 1.0) = 0.55;
uniform float barrel : hint_range(0.0, 0.1) = 0.035;
uniform vec3 tint = vec3(1.05, 1.0, 1.16);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 c = UV - 0.5;
	vec2 uv = 0.5 + c * (1.0 + barrel * dot(c, c));

	vec2 ca = vec2(chroma, 0.0);
	vec4 base = texture(TEXTURE, UV);
	vec3 col;
	col.r = texture(TEXTURE, uv + ca).r;
	col.g = texture(TEXTURE, uv).g;
	col.b = texture(TEXTURE, uv - ca).b;

	// 扫描线（缓慢滚动）
	float sl = 1.0 - scan_strength * (0.5 + 0.5 * sin(uv.y * scan_freq + TIME * scan_speed));
	col *= sl;

	// 颗粒
	float g = hash(uv * 512.0 + fract(TIME) * 37.0) - 0.5;
	col += g * grain_strength;

	// 暗角
	float v = smoothstep(0.95, 0.25, length(c));
	col *= mix(1.0 - vignette, 1.0, v);

	// 压黑 + 冷紫偏色 + 色阶量化
	col = pow(max(col, 0.0), vec3(1.12));
	col *= tint;
	col = floor(col * levels + 0.5) / levels;

	vec3 outc = mix(base.rgb, col, intensity);
	COLOR = vec4(outc, base.a);
}
