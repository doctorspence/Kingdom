shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, specular_schlick_ggx;
// Dark, slow river water: two layers of ripples drifting past each other, a
// cold fresnel sheen at low angles, and clearer water near the banks.

uniform sampler2D ripples_a : repeat_enable, filter_linear_mipmap;
uniform sampler2D ripples_b : repeat_enable, filter_linear_mipmap;
uniform vec3 deep_color : source_color = vec3(0.045, 0.075, 0.08);
uniform vec3 sheen_color : source_color = vec3(0.32, 0.36, 0.38);
uniform float flow_speed = 0.035;
uniform float ripple_scale = 0.11;
uniform float ripple_strength = 0.55;
uniform float opacity = 0.9;

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = wpos.xz;
	// The river runs mostly east-west; drift the ripples that way.
	vec3 a = texture(ripples_a, uv * ripple_scale + vec2(TIME * flow_speed, TIME * 0.01)).xyz * 2.0 - 1.0;
	vec3 b = texture(ripples_b, uv * ripple_scale * 2.3 + vec2(TIME * flow_speed * 1.7, -TIME * 0.02)).xyz * 2.0 - 1.0;
	vec3 n = normalize(vec3((a.xy + b.xy) * ripple_strength, 1.0));
	NORMAL = normalize((VIEW_MATRIX * vec4(normalize(vec3(n.x, n.z, n.y)), 0.0)).xyz);
	float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 3.0);
	ALBEDO = mix(deep_color, sheen_color, fresnel * 0.55);
	ROUGHNESS = 0.07;
	SPECULAR = 0.7;
	METALLIC = 0.0;
	ALPHA = clamp(opacity + fresnel * 0.1, 0.0, 1.0);
}
