shader_type spatial;
render_mode cull_disabled;

uniform sampler2D earth : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D earth_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D moss : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 terrain_position;

void vertex() {
	terrain_position = VERTEX;
}

void fragment() {
	vec2 uv = terrain_position.xz / 4.0;
	float broad = sin(terrain_position.x * 0.027 + sin(terrain_position.z * 0.038)) * 0.5 + 0.5;
	vec3 dirt = texture(earth, uv).rgb;
	vec3 leaves = texture(moss, uv * 0.74).rgb;
	ALBEDO = mix(dirt * vec3(0.30, 0.39, 0.22), leaves * vec3(0.24, 0.37, 0.17), 0.25 + broad * 0.60);
	NORMAL_MAP = texture(earth_normal, uv).rgb;
	NORMAL_MAP_DEPTH = 0.42;
	ROUGHNESS = 0.98;
}
