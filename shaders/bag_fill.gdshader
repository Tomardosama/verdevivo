shader_type canvas_item;

uniform float fill_ratio : hint_range(0.0, 1.0) = 0.0;
uniform vec4 empty_color : source_color = vec4(0.72, 0.76, 0.65, 1.0);
uniform vec4 filled_color : source_color = vec4(0.28, 0.68, 0.40, 1.0);

void fragment() {
	vec4 silhouette = texture(TEXTURE, UV);
	float edge = 1.0 - clamp(fill_ratio, 0.0, 1.0);
	float fill_mask = smoothstep(edge - 0.008, edge + 0.008, UV.y);
	if (fill_ratio <= 0.0) {
		fill_mask = 0.0;
	} else if (fill_ratio >= 1.0) {
		fill_mask = 1.0;
	}
	vec3 tint = mix(empty_color.rgb, filled_color.rgb, fill_mask);
	COLOR = vec4(tint * silhouette.rgb, silhouette.a);
}
