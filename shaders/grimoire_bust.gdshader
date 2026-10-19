shader_type canvas_item;
render_mode unshaded, blend_mix;

// Grimoire Bust — runtime version of the reference-3 grade.
// Attach to a Sprite2D / TextureRect holding a transparent 3:4 portrait.
// The shader never paints a background and never writes outside the alpha.
//
// Recommended import: nearest filter, virtual_size = native pixel size
// (288 x 384 for the baked set), alpha_cutoff around 0.40.

uniform vec2 virtual_size = vec2(288.0, 384.0);
uniform float palette_mix : hint_range(0.0, 1.0) = 1.0;
uniform float intensity : hint_range(0.0, 2.0) = 1.0;
uniform float dither_strength : hint_range(0.0, 1.0) = 0.10;
uniform float ca_strength : hint_range(0.0, 0.01) = 0.0012;
uniform float alpha_cutoff : hint_range(0.0, 1.0) = 0.40;
uniform float grade_strength : hint_range(0.0, 1.0) = 1.0;
uniform float rim_strength : hint_range(0.0, 2.0) = 0.46;
uniform float scanline_strength : hint_range(0.0, 0.3) = 0.035;
uniform float stipple_strength : hint_range(0.0, 0.4) = 0.14;
uniform float time_wobble : hint_range(0.0, 0.02) = 0.0;
uniform vec4 shadow_tint : source_color = vec4(0.072, 0.034, 0.110, 1.0);
uniform vec4 light_tint : source_color = vec4(0.918, 0.855, 0.710, 1.0);
uniform vec4 rim_color : source_color = vec4(0.58, 0.73, 0.66, 1.0);

const vec3 PALETTE[20] = {
    vec3(0.020, 0.020, 0.035), vec3(0.047, 0.035, 0.071),
    vec3(0.090, 0.063, 0.129), vec3(0.145, 0.086, 0.184),
    vec3(0.224, 0.137, 0.290), vec3(0.043, 0.125, 0.141),
    vec3(0.086, 0.227, 0.224), vec3(0.157, 0.333, 0.282),
    vec3(0.345, 0.451, 0.369), vec3(0.557, 0.561, 0.467),
    vec3(0.702, 0.663, 0.561), vec3(0.847, 0.804, 0.702),
    vec3(0.945, 0.902, 0.812), vec3(0.435, 0.184, 0.239),
    vec3(0.608, 0.294, 0.322), vec3(0.180, 0.251, 0.345),
    vec3(0.659, 0.486, 0.396), vec3(0.765, 0.604, 0.494),
    vec3(0.851, 0.710, 0.584), vec3(0.925, 0.824, 0.702)
};

const float BAYER8[64] = {
     0.0, 32.0,  8.0, 40.0,  2.0, 34.0, 10.0, 42.0,
    48.0, 16.0, 56.0, 24.0, 50.0, 18.0, 58.0, 26.0,
    12.0, 44.0,  4.0, 36.0, 14.0, 46.0,  6.0, 38.0,
    60.0, 28.0, 52.0, 20.0, 62.0, 30.0, 54.0, 22.0,
     3.0, 35.0, 11.0, 43.0,  1.0, 33.0,  9.0, 41.0,
    51.0, 19.0, 59.0, 27.0, 49.0, 17.0, 57.0, 25.0,
    15.0, 47.0,  7.0, 39.0, 13.0, 45.0,  5.0, 37.0,
    63.0, 31.0, 55.0, 23.0, 61.0, 29.0, 53.0, 21.0
};

float bayer8(ivec2 p) {
    int x = p.x & 7;
    int y = p.y & 7;
    return (BAYER8[y * 8 + x] + 0.5) / 64.0 - 0.5;
}

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec3 nearest_palette(vec3 c) {
    vec3 best = PALETTE[0];
    float best_d = 1e9;
    for (int i = 0; i < 20; i++) {
        vec3 d = c - PALETTE[i];
        float dd = dot(d, d);
        if (dd < best_d) {
            best_d = dd;
            best = PALETTE[i];
        }
    }
    return best;
}

vec3 grade_colour(vec3 c) {
    float l = dot(c, vec3(0.299, 0.587, 0.114));
    float warmth = c.r - c.b;
    float skin = clamp((warmth - 0.035) / 0.16, 0.0, 1.0)
               * clamp((l - 0.24) / 0.30, 0.0, 1.0);

    c = vec3(l) + (c - vec3(l)) * (0.66 - 0.30 * skin);

    float shadow = pow(clamp(1.0 - l / 0.38, 0.0, 1.0), 1.25);
    float shadow_amt = (0.46 - 0.24 * skin) * grade_strength;
    c = c * (1.0 - shadow * shadow_amt) + shadow_tint.rgb * shadow * shadow_amt;

    float mid = clamp((l - 0.18) / 0.50, 0.0, 1.0) * (1.0 - shadow) * grade_strength;
    c = c * (1.0 - mid * 0.10) + vec3(0.06, 0.15, 0.13) * mid * 0.10;

    float high = pow(clamp((l - 0.55) / 0.45, 0.0, 1.0), 1.2);
    float high_amt = (0.18 + 0.10 * skin) * grade_strength;
    c = c * (1.0 - high * high_amt) + light_tint.rgb * high * high_amt;

    c = (c - 0.40) * 1.14 + 0.42;
    return clamp(c, 0.0, 1.0);
}

void fragment() {
    vec2 tex_size = vec2(textureSize(TEXTURE, 0));
    vec2 grid = max(vec2(1.0), tex_size / virtual_size);

    vec2 uv = (floor(UV * tex_size / grid) + 0.5) * grid / tex_size;
    if (time_wobble > 0.0) {
        uv.x += sin(TIME * 0.7) * time_wobble;
        uv.y += cos(TIME * 0.9) * time_wobble;
    }

    vec2 dir = uv - vec2(0.5);
    vec4 centre = texture(TEXTURE, uv);
    float ca = ca_strength * smoothstep(0.12, 0.55, length(dir));
    float r = texture(TEXTURE, uv + dir * ca).r;
    float g = centre.g;
    float b = texture(TEXTURE, uv - dir * ca).b;
    vec4 src = vec4(r, g, b, centre.a);

    if (src.a < alpha_cutoff) {
        discard;
    }

    vec3 c = grade_colour(src.rgb);

    ivec2 p = ivec2(floor(UV * virtual_size));
    float l = dot(c, vec3(0.299, 0.587, 0.114));
    float d = bayer8(p) * dither_strength * (1.15 - 0.55 * smoothstep(0.2, 0.9, l));
    c = clamp(c + vec3(d), 0.0, 1.0);
    c = mix(c, nearest_palette(c), palette_mix);

    float stipple = step(0.62, hash21(vec2(p) + 19.0));
    c *= 1.0 - stipple * stipple_strength * (1.0 - smoothstep(0.10, 0.55, l));
    c = mix(src.rgb, c, intensity);

    float a_l = texture(TEXTURE, uv - vec2(grid.x / tex_size.x, 0.0)).a;
    float a_r = texture(TEXTURE, uv + vec2(grid.x / tex_size.x, 0.0)).a;
    float a_u = texture(TEXTURE, uv - vec2(0.0, grid.y / tex_size.y)).a;
    float a_d = texture(TEXTURE, uv + vec2(0.0, grid.y / tex_size.y)).a;
    float edge = clamp(1.0 - min(min(a_l, a_r), min(a_u, a_d)), 0.0, 1.0) * step(0.04, centre.a);
    // No silhouette rim: the v2 portraits already define their own edge.
    // c += rim_color.rgb * edge * rim_strength * 0.55;

    float scan = step(0.5, fract(UV.y * virtual_size.y));
    c *= 1.0 - scan * scanline_strength;

    COLOR = vec4(clamp(c, 0.0, 1.0), src.a);
}
