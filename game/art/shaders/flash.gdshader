shader_type canvas_item;
// Hit flash: blends the sprite toward a solid colour without touching transparency.
uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0);

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	COLOR = vec4(mix(c.rgb, flash_color.rgb, amount), c.a) * vec4(1.0, 1.0, 1.0, COLOR.a);
}
