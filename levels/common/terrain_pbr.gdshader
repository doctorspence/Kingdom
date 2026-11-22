shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
// The ground of a zone: real photographed textures (ambientCG / Poly Haven, CC0)
// blended by the terrain's vertex colors (R grass, G mud, B road, A rock), with
// noise to break up the edges and the repetition, moss and dark-soil patches,
// and rock projected from three sides so cliffs don't stretch.
// UV (from the land script): x = leaf litter under the broadleaf canopy,
// y = how much the rock is warm sandstone instead of pale limestone.
// Rock is graded to the Greenwood palette and shows horizontal bedding (strata)
// that lines up across whole cliffs; soil slopes that are not quite cliffs show
// dark crumbly mudstone.

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
uniform sampler2D litter_c : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D litter_n : hint_normal, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D noise_tex : hint_default_white, repeat_enable, filter_linear_mipmap;

// Repeats per meter.
uniform float grass_scale = 0.22;
uniform float mud_scale = 0.28;
uniform float path_scale = 0.3;
uniform float rock_scale = 0.13;
uniform float litter_scale = 0.35;
// Overall mood: multiplies each ground type.
uniform vec3 grass_tint : source_color = vec3(0.62, 0.66, 0.5);
uniform vec3 mud_tint : source_color = vec3(0.6, 0.55, 0.5);
uniform vec3 path_tint : source_color = vec3(0.72, 0.66, 0.58);
uniform vec3 litter_tint : source_color = vec3(0.62, 0.56, 0.48);
// Rock palette (brief: dark rock #555957, weathered limestone #777C78, pale limestone #B5B1A3).
uniform vec3 lime_dark : source_color = vec3(0.333, 0.349, 0.341);
uniform vec3 lime_mid : source_color = vec3(0.467, 0.486, 0.471);
uniform vec3 lime_pale : source_color = vec3(0.71, 0.694, 0.639);
uniform vec3 sand_dark : source_color = vec3(0.40, 0.31, 0.24);
uniform vec3 sand_pale : source_color = vec3(0.66, 0.56, 0.44);
uniform vec3 mudstone : source_color = vec3(0.35, 0.29, 0.24);
uniform float rock_brightness = 0.82;
uniform float strata_height = 0.85;  // meters per bed
uniform float normal_strength = 1.0;
global uniform float wetness;  // 0 dry .. 1 soaked (set by DayNight)
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

float hash1(float x) {
	return fract(sin(x * 127.1) * 43758.5453);
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
	float litter_w = clamp(UV.x * (0.7 + 0.6 * n3), 0.0, 1.0);
	float sand_w = UV.y;
	float worked = UV2.x;  // quarry: cut faces and a dusty floor

	// Each ground type, with a big soft brightness change over it so no tile shows.
	float macro = 0.8 + 0.4 * n1;
	vec3 grass = texture(grass_c, uv * grass_scale).rgb * grass_tint;
	vec3 moss = texture(moss_c, uv * grass_scale * 1.3).rgb * grass_tint;
	grass = mix(grass, moss, smoothstep(0.52, 0.72, n1) * 0.85);
	grass *= macro;
	// Under the broadleaf canopy: last year's leaves, twigs and moss instead of turf.
	vec3 litter = texture(litter_c, uv * litter_scale).rgb * litter_tint * (0.85 + 0.3 * n2);
	grass = mix(grass, litter, litter_w);
	vec3 mud = texture(mud_c, uv * mud_scale).rgb * mud_tint;
	vec3 dirt = texture(dirt_c, uv * mud_scale * 0.9).rgb * mud_tint;
	mud = mix(mud, dirt, smoothstep(0.4, 0.65, n2)) * (0.85 + 0.3 * n1);
	mud = mix(mud, litter * 0.8, litter_w * 0.5);
	vec3 path = texture(path_c, uv * path_scale).rgb * path_tint * (0.85 + 0.3 * n2);
	// The quarry floor: pale stone dust and chippings trodden into the mud.
	mud = mix(mud, lime_mid * 1.05 * (0.8 + 0.35 * n3) * (0.9 + 0.2 * n2), worked * 0.65);

	// Rock: the photographed detail becomes a light/dark value, painted with the palette.
	vec3 rock_src;
	float rock_rough;
	vec3 rock_normal;
	rock_triplanar(wpos, wnorm, rock_src, rock_rough, rock_normal);
	float lum = clamp(dot(rock_src, vec3(0.3, 0.59, 0.11)) * 2.2, 0.0, 1.0);
	// Horizontal beds: each bed a slightly different tone, dark joints between them,
	// gently warped so they don't read as ruled lines.
	float warp = (texture(noise_tex, uv * 0.006).r - 0.5) * 3.0 + (n2 - 0.5) * 0.6;
	float bed_coord = wpos.y / strata_height + warp;
	float bed = floor(bed_coord);
	float in_bed = fract(bed_coord);
	float bed_tone = hash1(bed) * 0.5 + 0.5 * hash1(bed + 7.3);
	float joint = 1.0 - smoothstep(0.0, 0.07, in_bed) * smoothstep(1.0, 0.9, in_bed);
	float vertical = 1.0 - abs(wnorm.y);  // strata only show on faces
	vec3 lime = mix(lime_dark, lime_mid, smoothstep(0.1, 0.5, lum));
	lime = mix(lime, lime_pale, smoothstep(0.45, 0.9, lum) * (0.55 + 0.45 * bed_tone));
	vec3 sand = mix(sand_dark, sand_pale, smoothstep(0.15, 0.85, lum * (0.7 + 0.5 * bed_tone)));
	vec3 rock = mix(lime, sand, smoothstep(0.25, 0.75, sand_w + (hash1(bed + 3.1) - 0.5) * 0.4 * sand_w));
	rock *= mix(1.0, 0.86 + 0.28 * bed_tone, vertical);
	rock *= 1.0 - joint * 0.45 * vertical;
	// Rain streaks darken faces from the top of each bed down.
	rock *= 1.0 - vertical * 0.12 * smoothstep(0.55, 1.0, texture(noise_tex, vec2(uv.x * 0.9 + uv.y * 0.9, wpos.y * 0.04)).r);
	rock *= rock_brightness;
	// Worked stone (the quarry): fresh pale cut faces, a little patchy, with faint tool marks.
	if (worked > 0.01) {
		float along = abs(wnorm.x) > abs(wnorm.z) ? wpos.z : wpos.x;
		float pick = smoothstep(0.6, 1.0, sin((along * 0.8 + wpos.y) * 22.0) * 0.5 + 0.5) * (0.5 + 0.5 * n3);
		vec3 fresh = mix(lime_mid, lime_pale, 0.45 + 0.4 * lum) * (0.9 + 0.15 * n2) * rock_brightness;
		fresh *= 1.0 - pick * 0.06;
		rock = mix(rock, fresh, worked * smoothstep(0.3, 0.7, vertical) * 0.8);
	}
	// Moss and soil on ledges and tops (faces up, in damp or shade).
	float ledge = smoothstep(0.55, 0.85, wnorm.y);
	rock = mix(rock, moss * 0.9, ledge * smoothstep(0.35, 0.7, n3) * 0.75);
	// Not-quite-cliff soil slopes: crumbling dark mudstone.
	rock = mix(rock, mudstone * (0.7 + 0.6 * lum), (1.0 - smoothstep(0.35, 0.8, w.w)) * vertical * 0.7);

	vec3 gn = planar_normal(grass_n, uv * grass_scale, wnorm);
	vec3 ln = planar_normal(litter_n, uv * litter_scale, wnorm);
	gn = normalize(mix(gn, ln, litter_w));
	vec3 mn = planar_normal(mud_n, uv * mud_scale, wnorm);
	vec3 pn = planar_normal(path_n, uv * path_scale, wnorm);
	vec3 ground_n = normalize(gn * w.x + mn * w.y + pn * w.z + wnorm * 0.0001);
	// Rock takes over the more it is a rock vertex (steep ground or pits).
	vec3 n_world = normalize(mix(ground_n, rock_normal, w.w));

	ALBEDO = (grass * w.x + mud * w.y + path * w.z + rock * w.w) * (1.0 - 0.35 * wetness);
	ROUGHNESS = clamp(texture(grass_r, uv * grass_scale).r * w.x + texture(mud_r, uv * mud_scale).r * w.y
			+ texture(path_r, uv * path_scale).r * w.z + rock_rough * w.w, 0.55, 1.0);
	// Wet ground shines, most on mud and roads.
	ROUGHNESS = mix(ROUGHNESS, 0.3, wetness * clamp(0.4 + 0.6 * w.y + 0.6 * w.z, 0.0, 1.0));
	SPECULAR = 0.1;
	NORMAL = normalize((VIEW_MATRIX * vec4(n_world, 0.0)).xyz);
}
