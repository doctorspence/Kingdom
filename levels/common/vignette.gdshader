shader_type canvas_item;
// A soft dark edge to the screen: the eye is pulled to the middle, which is
// what makes fog and firelight feel like a pool of light in the dark.

uniform float strength : hint_range(0.0, 1.0) = 0.5;
uniform float start = 0.38;
uniform float finish = 1.0;

void fragment() {
	vec2 p = (UV - vec2(0.5)) * vec2(1.1, 1.0);
	float edge = smoothstep(start, finish, length(p));
	COLOR = vec4(0.0, 0.0, 0.0, edge * strength);
}
