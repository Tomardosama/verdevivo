shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec4 shallow_tint : source_color = vec4(0.28, 0.58, 0.56, 0.90);
uniform vec4 deep_tint : source_color = vec4(0.035, 0.20, 0.28, 0.94);
uniform float ripple_strength = 0.035;
uniform float ripple_speed = 0.78;
uniform float ripple_frequency = 34.0;
uniform float water_radius_uv = 1.0;
uniform bool circular_mask = true;

varying float radial_distance;

void vertex() {
	vec2 centered_uv = UV * 2.0 - 1.0;
	radial_distance = circular_mask ? length(centered_uv) : UV.x;
	float shore_fade = circular_mask ? 1.0 - smoothstep(0.78, 0.995, radial_distance) : 1.0;
	float circular_wave = sin(radial_distance * ripple_frequency - TIME * ripple_speed);
	float secondary_wave = cos(radial_distance * ripple_frequency * 0.57 + TIME * ripple_speed * 0.72 + UV.y * 1.7);
	VERTEX.y += (circular_wave * 0.72 + secondary_wave * 0.28) * ripple_strength * shore_fade;
}

void fragment() {
	vec2 centered_uv = UV * 2.0 - 1.0;
	float radius = circular_mask ? length(centered_uv) : UV.x;
	if (circular_mask && radius > water_radius_uv) {
		discard;
	}
	float edge = circular_mask ? 1.0 - smoothstep(0.94, 1.0, radius) : 1.0;
	float radial_depth = circular_mask ? clamp(radius * 0.74 + 0.16, 0.0, 1.0) : clamp(0.12 + UV.y * 0.44, 0.0, 1.0);
	float rings = sin(radius * ripple_frequency - TIME * ripple_speed);
	float ring_highlight = circular_mask ? smoothstep(0.78, 0.96, rings) * (1.0 - smoothstep(0.82, 1.0, radius)) : smoothstep(0.76, 0.98, rings) * 0.35;
	vec3 water_color = mix(shallow_tint.rgb, deep_tint.rgb, radial_depth);
	water_color += vec3(0.07, 0.10, 0.075) * ring_highlight;
	ALBEDO = water_color;
	ROUGHNESS = mix(0.24, 0.12, ring_highlight);
	METALLIC = 0.08;
	ALPHA = mix(shallow_tint.a, deep_tint.a, radial_depth) * edge;
}
