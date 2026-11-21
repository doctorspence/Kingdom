shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
// The ground of a zone: real photographed textures (ambientCG, CC0) blended by
// the terrain's vertex colors (R grass, G mud, B road, A rock), with noise to
// break up the edges and the repetition, moss and dark-soil patches, and rock
// projected from three sides so cliffs don't stretch.

uniform sampler2D grass_c : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D grass_n : hint_normal, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D grass_r : hint_roughness_r, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D mud_c : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D mud_n : hint_normal, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D mud_r : hint_roughness_r, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D path_c : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D path_n : hint_normal, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D path_r : hint_roughness_r, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D rock_c : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D rock_n : hint_normal, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D rock_r : hint_roughness_r, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D moss_c : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D dirt_c : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D noise_tex : hint_default_white, repeat_enable, filter_linear_mipmap;

// Repeats per meter.
uniform float grass_scale = 0.22;
uniform float mud_scale = 0.28;
uniform float path_scale = 0.3;
uniform float rock_scale = 0.13;
// Overall mood: multiplies each ground type (darker, washed out).
uniform vec3 grass_tint : source_color = vec3(0.62, 0.66, 0.5);
uniform vec3 mud_tint : source_color = vec3(0.6, 0.55, 0.5);
uniform vec3 path_tint : source_color = vec3(0.72, 0.66, 0.58);
uniform vec3 rock_tint : source_color = vec3(0.62, 0.62, 0.64);
uniform float normal_strength = 1.0;
uniform float blend_sharpness = 3.0;

varying vec3 wpos;
varying vec3 wnorm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

// A top-down normal map turned into a world-space normal.
vec3 planar_normal(sampler2D tex, vec2 uv, vec3 base) {
	vec3 t = texture(tex, uv).xyz * 2.0 - 1.0;
	t.xy *= normal_strength;
	return normalize(vec3(t.x + base.x, base.y * max(t.z, 0.2), -t.y + base.z));
}

// Rock from three directions, blended by how much the surface faces each way.
void rock_triplanar(vec3 p, vec3 n, out vec3 albedo, out float rough, out vec3 wn) {
	vec3 b = pow(abs(n), vec3(6.0));
	b /= (b.x + b.y + b.z);
	vec2 ux = p.zy * rock_scale;
	vec2 uy = p.xz * rock_scale;
	vec2 uz = p.xy * rock_scale;
	albedo = texture(rock_c, ux).rgb * b.x + texture(rock_c, uy).rgb * b.y + texture(rock_c, uz).rgb * b.z;
	rough = texture(rock_r, ux).r * b.x + texture(rock_r, uy).r * b.y + texture(rock_r, uz).r * b.z;
	vec3 tx = texture(rock_n, ux).xyz * 2.0 - 1.0;
	vec3 ty = texture(rock_n, uy).xyz * 2.0 - 1.0;
	vec3 tz = texture(rock_n, uz).xyz * 2.0 - 1.0;
	tx = vec3(tx.xy + n.zy, abs(tx.z) * n.x);
	ty = vec3(ty.xy + n.xz, abs(ty.z) * n.y);
	tz = vec3(tz.xy + n.xy, abs(tz.z) * n.z);
	wn = normalize(tx.zyx * b.x + ty.xzy * b.y + tz.xyz * b.z);
}

void fragment() {
	vec2 uv = wpos.xz;
	// Slow noise at two sizes: it roughens the blends and breaks the repetition.
	float n1 = texture(noise_tex, uv * 0.011).r;
	float n2 = texture(noise_tex, uv * 0.047 + vec2(0.31, 0.7)).r;
	float n3 = texture(noise_tex, uv * 0.21 + vec2(0.6, 0.2)).r;

	vec4 w = COLOR;
	w = max(w * (0.55 + 0.9 * vec4(n2, n3, n2 * 0.5 + n3 * 0.5, 0.5 + 0.5 * n3)), vec4(0.0001));
	w = pow(w, vec4(blend_sharpness));
	w /= (w.x + w.y + w.z + w.w);

	// Each ground type, with a big soft brightness change over it so no tile shows.
	float macro = 0.8 + 0.4 * n1;
	vec3 grass = texture(grass_c, uv * grass_scale).rgb * grass_tint;
	vec3 moss = texture(moss_c, uv * grass_scale * 1.3).rgb * grass_tint;
	grass = mix(grass, moss, smoothstep(0.52, 0.72, n1) * 0.85);
	grass *= macro;
	vec3 mud = texture(mud_c, uv * mud_scale).rgb * mud_tint;
	vec3 dirt = texture(dirt_c, uv * mud_scale * 0.9).rgb * mud_tint;
	mud = mix(mud, dirt, smoothstep(0.4, 0.65, n2)) * (0.85 + 0.3 * n1);
	vec3 path = texture(path_c, uv * path_scale).rgb * path_tint * (0.85 + 0.3 * n2);
	vec3 rock;
	float rock_rough;
	vec3 rock_normal;
	rock_triplanar(wpos, wnorm, rock, rock_rough, rock_normal);
	rock *= rock_tint;

	vec3 ground_n = wnorm;
	vec3 gn = planar_normal(grass_n, uv * grass_scale, wnorm);
	vec3 mn = planar_normal(mud_n, uv * mud_scale, wnorm);
	vec3 pn = planar_normal(path_n, uv * path_scale, wnorm);
	ground_n = normalize(gn * w.x + mn * w.y + pn * w.z + wnorm * 0.0001);
	// Rock takes over the more it is a rock vertex (steep ground or pits).
	vec3 n_world = normalize(mix(ground_n, rock_normal, w.w));

	ALBEDO = grass * w.x + mud * w.y + path * w.z + rock * w.w;
	ROUGHNESS = clamp(texture(grass_r, uv * grass_scale).r * w.x + texture(mud_r, uv * mud_scale).r * w.y
			+ texture(path_r, uv * path_scale).r * w.z + rock_rough * w.w, 0.3, 1.0);
	SPECULAR = 0.25;
	NORMAL = normalize((VIEW_MATRIX * vec4(n_world, 0.0)).xyz);
}
