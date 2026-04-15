shader_type canvas_item;
uniform vec4 blink_color: source_color;
uniform float blink_intensity = 0;
uniform vec4 buff_color: source_color = vec4(1.0, 0.75, 0.2, 1.0);
uniform float buff_intensity = 0.0;
uniform float buff_pulse_speed = 6.0;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	color = mix(color, blink_color, blink_intensity * color.a);
	
	if (buff_intensity > 0.0) {
		float pulse = 0.5 + (0.5 * sin(TIME * buff_pulse_speed));
		float glow = buff_intensity * pulse * color.a;
		color.rgb = mix(color.rgb, buff_color.rgb, clamp(glow, 0.0, 1.0));
		color.rgb += buff_color.rgb * glow * 0.25;
	}
	
	COLOR = color;
	
}
