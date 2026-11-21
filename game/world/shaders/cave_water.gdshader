shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, shadows_disabled;
// Still or slowly flowing cave water: two scrolling ripple layers, soft foam, glassy highlights.

uniform sampler2D normal_tex : hint_normal, repeat_enable, filter_linear_mipmap;
uniform sampler2D noise_tex : repeat_enable, filter_linear_mipmap;
uniform vec2 flow = vec2(1.0, 0.0);
uniform float speed = 0.22;
uniform vec3 deep : source_color = vec3(0.03, 0.08, 0.11);
uniform vec3 shallow : source_color = vec3(0.10, 0.20, 0.24);

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = wpos.xz * 0.33;
	vec2 f = flow * TIME * speed;
	vec3 n1 = texture(normal_tex, uv - f).xyz;
	vec3 n2 = texture(normal_tex, uv * 1.9 - f * 1.7 + vec2(0.37, 0.11)).xyz;
	NORMAL_MAP = normalize(vec3(n1.xy + n2.xy - 1.0, 1.0)) * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 1.5;
	float nz = texture(noise_tex, uv * 0.6 - f * 0.8).r;
	float foam = smoothstep(0.74, 0.92, nz) * 0.45;
	ALBEDO = mix(deep, shallow, nz) + vec3(foam);
	ALPHA = clamp(0.8 + foam * 0.3, 0.0, 0.95);
	ROUGHNESS = 0.05;
	SPECULAR = 0.9;
}
