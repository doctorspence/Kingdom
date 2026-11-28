// Light rays from the moon, worked out on screen: open sky around the moon is the light,
// and anything solid in front of it (trees, moss, roofs) cuts dark gaps in the rays.
// Drawn by game/world/moon_rays.gd.
shader_type spatial;
render_mode unshaded, blend_add, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform vec2 moon_uv = vec2(0.5);
uniform float aspect = 1.777;
uniform float visible_k = 1.0;
uniform float on = 1.0;
uniform vec3 ray_col : source_color = vec3(0.55, 0.68, 0.82);
uniform float intensity = 1.3;
uniform float reach = 0.85;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

// Open sky near the moon is the light source; anything solid in front of it blocks it.
float source(vec2 uv) {
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
		return 0.0;
	}
	float sky = texture(depth_tex, uv).r <= 0.000001 ? 1.0 : 0.0;
	vec2 d = (uv - moon_uv) * vec2(aspect, 1.0);
	float r = length(d);
	return sky * (1.0 - smoothstep(0.02, 0.45, r));
}

void fragment() {
	const int STEPS = 64;
	vec2 uv = SCREEN_UV;
	vec2 delta = (uv - moon_uv) * reach / float(STEPS);
	// A random start offset per pixel hides the step pattern (no visible stripes).
	float jitter = fract(sin(dot(FRAGCOORD.xy, vec2(12.9898, 78.233))) * 43758.5453);
	vec2 p = uv + delta * jitter;
	float decay = 1.0;
	float sum = 0.0;
	for (int i = 0; i < STEPS; i++) {
		p -= delta;
		sum += source(p) * decay;
		decay *= 0.965;
	}
	sum /= float(STEPS);
	// Rays fade with distance from the moon on screen, so they reach out but never fill the frame.
	float r = length((uv - moon_uv) * vec2(aspect, 1.0));
	float fall = 1.0 - smoothstep(0.15, 1.1, r);
	ALBEDO = ray_col;
	ALPHA = clamp(sum * intensity * fall * visible_k * on, 0.0, 1.0);
}
