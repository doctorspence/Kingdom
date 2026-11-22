shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
// Cave floor: gravel scree broken up with packed dark dirt and wet mud, blended by large
// noise and the vertex weathering, two scales of each so the tiling never shows.

uniform sampler2D scree_c : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D scree_n : hint_normal, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D scree_r : repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D dirt_c : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D dirt_n : hint_normal, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D dirt_r : repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D mud_c : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D patch_tex : repeat_enable, filter_linear_mipmap;
uniform vec3 tint : source_color = vec3(0.85, 0.76, 0.68);

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 w = wpos.xz;
	float big = texture(patch_tex, w * 0.021).r;
	float mid = texture(patch_tex, w * 0.087 + 3.1).r;
	// Where dirt wins over gravel: broad patches with ragged edges.
	float dmask = smoothstep(0.50, 0.66, big * 0.75 + mid * 0.35);
	// Wet mud follows the dark vertex tint (damp hollows).
	float wet = clamp((0.78 - COLOR.r) * 3.0, 0.0, 1.0);

	vec2 s1 = w * 0.34;
	vec2 s2 = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * w * 0.113 + 7.3;
	float k = smoothstep(0.35, 0.65, mid);
	vec3 sc = mix(texture(scree_c, s1).rgb, texture(scree_c, s2 * 2.7).rgb, k * 0.55);
	vec3 sn = mix(texture(scree_n, s1).xyz, texture(scree_n, s2 * 2.7).xyz, k * 0.55);
	float sr = mix(texture(scree_r, s1).r, texture(scree_r, s2 * 2.7).r, k * 0.55);

	vec2 d1 = w * 0.27 + 1.7;
	vec3 dc = mix(texture(dirt_c, d1).rgb, texture(dirt_c, d1 * 0.37).rgb, 0.5);
	vec3 dn = texture(dirt_n, d1).xyz;
	float dr = texture(dirt_r, d1).r;
	vec3 mc = texture(mud_c, w * 0.23 + 5.0).rgb;

	// Gravel pokes through the dirt: use the scree brightness as a height cue.
	float hgt = dot(sc, vec3(0.33));
	float dm = clamp(dmask + (0.5 - hgt) * 0.5 * dmask, 0.0, 1.0);

	vec3 alb = mix(sc * tint, dc * 0.85, dm);
	alb = mix(alb, mc * 0.55, wet * 0.7);
	ALBEDO = alb * COLOR.rgb * 1.15;
	vec3 nn = mix(sn, dn, dm);
	NORMAL_MAP = nn;
	NORMAL_MAP_DEPTH = 1.35;
	float rough = mix(sr, dr, dm);
	ROUGHNESS = clamp(mix(rough, 0.28, wet * 0.8), 0.0, 1.0);
	SPECULAR = 0.5 + wet * 0.4;
}
