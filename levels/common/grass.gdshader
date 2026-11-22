shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_schlick_ggx;
// Grass tufts: dark at the root, paler at the tip, swaying in a slow wind.
// COLOR.r is the height along the blade (0 root, 1 tip), COLOR.g a random shade.

uniform vec3 base_color : source_color = vec3(0.07, 0.1, 0.04);
uniform vec3 tip_color : source_color = vec3(0.4, 0.43, 0.2);
uniform float sway = 0.12;
uniform float wind_speed = 1.4;
global uniform float wetness;  // 0 dry .. 1 soaked (set by DayNight)

void vertex() {
	float h = COLOR.r;
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float gust = sin(TIME * wind_speed + wp.x * 0.35 + wp.z * 0.22);
	VERTEX.x += (gust * 0.7 + sin(TIME * 2.3 + wp.z * 0.9) * 0.3) * sway * h * h;
	VERTEX.z += cos(TIME * wind_speed * 0.8 + wp.z * 0.3) * sway * 0.6 * h * h;
	NORMAL = vec3(0.0, 1.0, 0.0);
}

void fragment() {
	// Blades are two-sided: keep the normal pointing up on the back face too
	// (Godot flips it there, which made half the blades black).
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	ALBEDO = mix(base_color, tip_color, COLOR.r) * (0.8 + 0.4 * COLOR.g) * (1.0 - 0.3 * wetness);
	ROUGHNESS = mix(0.9, 0.5, wetness);
	SPECULAR = 0.04;
	BACKLIGHT = vec3(0.12, 0.14, 0.05) * COLOR.r;
}
