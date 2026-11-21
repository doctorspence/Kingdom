shader_type spatial;
render_mode blend_mix, cull_disabled, shadows_disabled, unshaded;
// A waterfall sheet: falls and fans out from the lip, streaky white water with thin
// transparent gaps, fading at the edges. UV.y runs 0 at the lip to 1 at the base.

uniform sampler2D noise_tex : repeat_enable, filter_linear_mipmap;
uniform float speed = 1.5;
uniform vec3 tint : source_color = vec3(0.72, 0.88, 0.96);

void vertex() {
	float t = UV.y;
	VERTEX.z -= t * t * 0.55 + 0.05 * sin(TIME * 3.0 + t * 18.0 + VERTEX.x * 4.0) * t;
}

void fragment() {
	float a = texture(noise_tex, vec2(UV.x * 1.6, UV.y * 0.45 - TIME * speed * 0.3)).r;
	float b = texture(noise_tex, vec2(UV.x * 3.3 + 0.31, UV.y * 0.9 - TIME * speed * 0.62)).r;
	float c = texture(noise_tex, vec2(UV.x * 6.1 + 0.77, UV.y * 1.7 - TIME * speed)).r;
	float streak = smoothstep(0.32, 0.82, a * 0.45 + b * 0.35 + c * 0.3);
	float edge = smoothstep(0.0, 0.14, UV.x) * smoothstep(1.0, 0.86, UV.x);
	float lip = smoothstep(0.0, 0.03, UV.y);
	float spray = smoothstep(0.82, 1.0, UV.y);
	ALBEDO = mix(tint * 0.55, vec3(1.0), streak + spray * 0.4);
	ALPHA = clamp((0.22 + 0.7 * streak + spray * 0.25) * edge * lip, 0.0, 0.92);
}
