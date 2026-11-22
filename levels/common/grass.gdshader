shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_schlick_ggx;
// Grass tufts: dark and damp at the root, brighter green up the blade, a sun-dried yellow at
// the tip, with big soft patches of lush and dry grass across the ground and a slow wind that
// moves in waves. COLOR.r is the height along the blade (0 root, 1 tip), COLOR.g a random shade.

uniform vec3 base_color : source_color = vec3(0.025, 0.05, 0.015);
uniform vec3 mid_color : source_color = vec3(0.13, 0.22, 0.05);
uniform vec3 tip_color : source_color = vec3(0.34, 0.38, 0.13);
uniform vec3 dry_color : source_color = vec3(0.42, 0.36, 0.17);
uniform float sway = 0.1;
uniform float wind_speed = 1.3;
global uniform float wetness;  // 0 dry .. 1 soaked (set by DayNight)

varying float v_patch;
varying float v_gust;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	float h = COLOR.r;
	vec3 root = MODEL_MATRIX[3].xyz;  // the tuft's own position: same patch value for all its blades
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_patch = vnoise(root.xz * 0.045) * 0.65 + vnoise(root.xz * 0.23 + 17.0) * 0.35;
	// Wind: a travelling wave (gusts roll across the field) plus a small flutter.
	float wave = sin(TIME * wind_speed - dot(root.xz, vec2(0.21, 0.13)) * 1.6) * 0.5 + 0.5;
	v_gust = wave;
	float lean = (wave * 0.8 + 0.2) * sway;
	vec2 dir = normalize(vec2(0.8, 0.45));
	float flutter = sin(TIME * 3.1 + wp.x * 1.7 + wp.z * 1.3) * 0.25 * sway * h;
	VERTEX.x += (dir.x * lean + flutter) * h * h;
	VERTEX.z += (dir.y * lean + flutter * 0.6) * h * h;
	VERTEX.y -= lean * 0.25 * h * h;
	NORMAL = vec3(0.0, 1.0, 0.0);
}

void fragment() {
	// Blades are two-sided: keep the normal pointing up on the back face too
	// (Godot flips it there, which made half the blades black).
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	float h = COLOR.r;
	vec3 lush = mix(base_color, mid_color, smoothstep(0.0, 0.5, h));
	lush = mix(lush, tip_color, smoothstep(0.45, 1.0, h));
	// Dry patches go yellower from the middle of the blade up.
	float dry = smoothstep(0.52, 0.8, v_patch);
	vec3 dried = mix(lush, dry_color * (0.6 + 0.4 * h), smoothstep(0.1, 0.9, h));
	vec3 col = mix(lush, dried, dry);
	col *= 0.72 + 0.5 * COLOR.g;
	// Root shadow: where blades crowd together the ground is dark.
	col *= mix(0.45, 1.0, smoothstep(0.0, 0.35, h));
	// Gusts lighten the blades a touch as they turn toward the sky.
	col *= 1.0 + 0.1 * v_gust * h;
	ALBEDO = col * (1.0 - 0.3 * wetness);
	ROUGHNESS = mix(0.85, 0.45, wetness);
	SPECULAR = 0.05;
	BACKLIGHT = vec3(0.1, 0.16, 0.04) * (0.3 + 0.7 * h);
}
