shader_type spatial;
render_mode cull_disabled;

void vertex() {
	float blade_tip = clamp((VERTEX.y + 0.19) / 0.38, 0.0, 1.0);
	float wind_phase = INSTANCE_CUSTOM.r;
	VERTEX.x += sin(TIME * 1.35 + wind_phase + VERTEX.z * 8.0) * 0.055 * blade_tip;
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 0.96;
}
