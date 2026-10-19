shader_type canvas_item;
render_mode unshaded, blend_mix;

// ---------------------------------------------------------------
// THESIS, PLEASE — 1-bit student portrait material.
// 7-colour ink/paper/pine/stamp palette + the game's portrait CRT:
// barrel, chroma, scanlines, grain, vignette, level quantization.
// Flash / dissolve / tint are exposed for game state.
// ---------------------------------------------------------------

uniform vec2 virtual_size = vec2(72.0, 96.0);
uniform float alpha_cutoff : hint_range(0.0, 1.0) = 0.50;
uniform float palette_mix : hint_range(0.0, 1.0) = 1.0;

// CRT block (defaults are the game's portrait filter, softened)
uniform float intensity : hint_range(0.0, 1.0) = 1.0;
uniform float scan_strength : hint_range(0.0, 1.0) = 0.14;
uniform float scan_freq = 900.0;
uniform float scan_speed = 6.0;
uniform float crt_grain : hint_range(0.0, 0.2) = 0.05;
uniform float chroma : hint_range(0.0, 0.02) = 0.0014;
uniform float levels : hint_range(2.0, 64.0) = 28.0;
uniform float vignette : hint_range(0.0, 1.0) = 0.40;
uniform float barrel : hint_range(0.0, 0.1) = 0.022;
uniform vec3 crt_tint = vec3(1.04, 1.0, 1.10);

// 1-bit style
uniform float paper_grain : hint_range(0.0, 0.4) = 0.04;
uniform float rim_strength : hint_range(0.0, 2.0) = 0.16;
uniform vec4 rim_color : source_color = vec4(0.937, 0.890, 0.780, 1.0);
uniform float outline_strength : hint_range(0.0, 2.0) = 0.0;
uniform vec4 outline_color : source_color = vec4(0.078, 0.067, 0.059, 1.0);

// game state
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(0.639, 0.227, 0.196, 1.0);
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float tint_strength : hint_range(0.0, 1.0) = 0.0;

const vec3 PALETTE[7] = {
    vec3(0.078, 0.067, 0.059), // ink
    vec3(0.937, 0.890, 0.784), // paper cream
    vec3(0.133, 0.231, 0.176), // pine green
    vec3(0.424, 0.478, 0.333), // olive
    vec3(0.639, 0.227, 0.196), // stamp red
    vec3(0.788, 0.663, 0.486), // tan
    vec3(0.969, 0.941, 0.875)  // pale highlight
};

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec3 nearest_palette(vec3 c) {
    vec3 best = PALETTE[0];
    float best_d = 1e9;
    for (int i = 0; i < 7; i++) {
        vec3 d = c - PALETTE[i];
        float dd = dot(d, d);
        if (dd < best_d) {
            best_d = dd;
            best = PALETTE[i];
        }
    }
    return best;
}

void fragment() {
    vec2 tex_size = vec2(textureSize(TEXTURE, 0));
    vec2 grid = max(vec2(1.0), tex_size / virtual_size);
    vec2 snapped = (floor(UV * virtual_size) + 0.5) / virtual_size;

    // dissolve by virtual pixel
    if (dissolve > 0.0) {
        float h = hash(floor(UV * virtual_size) + vec2(0.37, 1.71));
        if (h < dissolve) {
            discard;
        }
    }

    // CRT barrel + chroma
    vec2 c = UV - 0.5;
    vec2 uv = 0.5 + c * (1.0 + barrel * dot(c, c));
    vec2 ca = vec2(chroma, 0.0);
    vec4 base = texture(TEXTURE, UV);
    vec3 col;
    col.r = texture(TEXTURE, uv + ca).r;
    col.g = texture(TEXTURE, uv).g;
    col.b = texture(TEXTURE, uv - ca).b;

    float sl = 1.0 - scan_strength * (0.5 + 0.5 * sin(uv.y * scan_freq + TIME * scan_speed));
    col *= sl;

    float g = hash(uv * 512.0 + fract(TIME) * 37.0) - 0.5;
    col += g * crt_grain;

    float v = smoothstep(0.95, 0.25, length(c));
    col *= mix(1.0 - vignette, 1.0, v);

    col = pow(max(col, 0.0), vec3(1.08));
    col *= crt_tint;
    col = floor(col * levels + 0.5) / levels;
    col = mix(base.rgb, col, intensity);

    // paper grain before palette snap
    float pg = hash(floor(UV * virtual_size) + vec2(3.1, 7.7)) - 0.5;
    col += vec3(pg * paper_grain);

    col = mix(col, nearest_palette(col), palette_mix);

    // pale rim so the ink silhouette separates from the pine panel
    if (rim_strength > 0.0) {
        float a_l = texture(TEXTURE, snapped - vec2(grid.x / tex_size.x, 0.0)).a;
        float a_r = texture(TEXTURE, snapped + vec2(grid.x / tex_size.x, 0.0)).a;
        float a_u = texture(TEXTURE, snapped - vec2(0.0, grid.y / tex_size.y)).a;
        float a_d = texture(TEXTURE, snapped + vec2(0.0, grid.y / tex_size.y)).a;
        float edge = clamp(1.0 - min(min(a_l, a_r), min(a_u, a_d)), 0.0, 1.0) * step(0.05, base.a);
        col += rim_color.rgb * edge * rim_strength;
    }

    if (outline_strength > 0.0) {
        float a_l = texture(TEXTURE, snapped - vec2(grid.x / tex_size.x, 0.0)).a;
        float a_r = texture(TEXTURE, snapped + vec2(grid.x / tex_size.x, 0.0)).a;
        float a_u = texture(TEXTURE, snapped - vec2(0.0, grid.y / tex_size.y)).a;
        float a_d = texture(TEXTURE, snapped + vec2(0.0, grid.y / tex_size.y)).a;
        float edge = clamp(1.0 - min(min(a_l, a_r), min(a_u, a_d)), 0.0, 1.0) * step(0.05, base.a);
        col = mix(col, outline_color.rgb, edge * outline_strength);
    }

    col = mix(col, flash_color.rgb, flash);
    col = mix(col, col * tint.rgb, tint_strength);

    if (base.a < alpha_cutoff) {
        discard;
    }
    COLOR = vec4(clamp(col, 0.0, 1.0), base.a);
}
