// Graybox surface: thin lines every 1 m, bold lines every 5 m.
// Lets you judge distances and speeds in test maps.
shader_type spatial;

uniform vec3 base_color : source_color = vec3(0.34, 0.34, 0.35);
uniform vec3 line_color : source_color = vec3(0.24, 0.24, 0.25);
uniform vec3 major_color : source_color = vec3(0.18, 0.18, 0.19);
uniform float line_width = 0.015;

varying vec3 world_pos;
varying vec3 world_normal;

float grid(vec2 p, float cell, float width) {
	vec2 g = abs(fract(p / cell - 0.5) - 0.5) * cell;
	float d = min(g.x, g.y);
	float aa = fwidth(d);
	return 1.0 - smoothstep(width - aa, width + aa, d);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = abs(world_normal);
	vec2 uv = n.y > 0.6 ? world_pos.xz : (n.x > n.z ? world_pos.zy : world_pos.xy);
	vec3 col = mix(base_color, line_color, grid(uv, 1.0, line_width));
	col = mix(col, major_color, grid(uv, 5.0, line_width * 2.0));
	ALBEDO = col;
	ROUGHNESS = 0.92;
}
