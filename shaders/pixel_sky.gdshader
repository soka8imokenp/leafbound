shader_type canvas_item;
render_mode unshaded;
// Living pixel-art sky. Rendered into a tiny SubViewport (one texel = one game pixel) and shown with nearest
// filtering. Ideas borrowed from fluid (enonforetsam, MIT): Bayer-dithered bands, domain-warped noise clouds,
// aurora curtains. Time of day: 0 midnight, 0.25 dawn, 0.5 noon, 0.75 dusk.

uniform vec2 size = vec2(160.0, 90.0);
uniform float tod : hint_range(0.0, 1.0) = 0.5;
uniform float cloud_amount : hint_range(0.0, 1.0) = 0.55;
uniform float cloud_scale = 1.0;
uniform float wind = 1.0;
uniform float star_amount : hint_range(0.0, 1.0) = 1.0;
uniform float aurora_amount : hint_range(0.0, 1.0) = 0.0;
uniform float body_radius = 5.0;
uniform float glow_amount : hint_range(0.0, 1.0) = 0.55;
uniform float horizon = 1.0;
uniform bool overlay_only = false;
uniform float overlay_alpha = 0.6;
uniform vec2 fade_y = vec2(0.55, 0.8);
uniform vec4 hole_a = vec4(0.0);          // overlay: soft holes (x0, y0, x1, y1 in uv) where clouds fade out
uniform vec4 hole_b = vec4(0.0);
uniform vec3 mist_hi = vec3(0.97, 0.99, 0.95);      // overlay colours (menu mist matches the painted sky)
uniform vec3 mist_base = vec3(0.91, 0.95, 0.93);
uniform vec3 mist_shade = vec3(0.82, 0.90, 0.88);
uniform bool use_mask = false;
uniform sampler2D mask : filter_nearest;

const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

float bayer4(vec2 p) {
	ivec2 q = ivec2(mod(floor(p), 4.0));
	return (BAYER[q.x + q.y * 4] + 0.5) / 16.0;
}
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) {
	float a = 0.5, s = 0.0;
	for (int i = 0; i < 4; i++) { s += a * noise(p); p = p * 2.03 + vec2(7.1, 3.7); a *= 0.5; }
	return s;
}

// ---- palettes: midnight, dawn, noon, dusk, midnight
vec3 k_top(float t) {
	const vec3 K[5] = vec3[5](vec3(0.03, 0.05, 0.15), vec3(0.30, 0.32, 0.58), vec3(0.20, 0.48, 0.84), vec3(0.22, 0.16, 0.42), vec3(0.03, 0.05, 0.15));
	float f = clamp(t, 0.0, 1.0) * 4.0; int i = min(int(floor(f)), 3); float s = fract(f); s = s * s * (3.0 - 2.0 * s);
	return mix(K[i], K[i + 1], s);
}
vec3 k_bot(float t) {
	const vec3 K[5] = vec3[5](vec3(0.08, 0.10, 0.28), vec3(1.00, 0.66, 0.48), vec3(0.64, 0.84, 0.97), vec3(0.99, 0.55, 0.38), vec3(0.08, 0.10, 0.28));
	float f = clamp(t, 0.0, 1.0) * 4.0; int i = min(int(floor(f)), 3); float s = fract(f); s = s * s * (3.0 - 2.0 * s);
	return mix(K[i], K[i + 1], s);
}
vec3 k_chi(float t) {
	const vec3 K[5] = vec3[5](vec3(0.40, 0.44, 0.66), vec3(1.00, 0.90, 0.78), vec3(1.00, 1.00, 0.97), vec3(1.00, 0.80, 0.62), vec3(0.40, 0.44, 0.66));
	float f = clamp(t, 0.0, 1.0) * 4.0; int i = min(int(floor(f)), 3); float s = fract(f); s = s * s * (3.0 - 2.0 * s);
	return mix(K[i], K[i + 1], s);
}
vec3 k_cba(float t) {
	const vec3 K[5] = vec3[5](vec3(0.26, 0.30, 0.50), vec3(0.94, 0.74, 0.70), vec3(0.90, 0.95, 1.00), vec3(0.92, 0.58, 0.56), vec3(0.26, 0.30, 0.50));
	float f = clamp(t, 0.0, 1.0) * 4.0; int i = min(int(floor(f)), 3); float s = fract(f); s = s * s * (3.0 - 2.0 * s);
	return mix(K[i], K[i + 1], s);
}
vec3 k_csh(float t) {
	const vec3 K[5] = vec3[5](vec3(0.14, 0.17, 0.34), vec3(0.58, 0.46, 0.62), vec3(0.66, 0.76, 0.90), vec3(0.52, 0.34, 0.52), vec3(0.14, 0.17, 0.34));
	float f = clamp(t, 0.0, 1.0) * 4.0; int i = min(int(floor(f)), 3); float s = fract(f); s = s * s * (3.0 - 2.0 * s);
	return mix(K[i], K[i + 1], s);
}

float dens(vec2 px, float scale, float speed, float seed) {
	vec2 p = px / (30.0 * scale);
	p.x *= 0.6;
	p.x -= TIME * speed * 0.012 * wind;                       // drifts to the right
	p += vec2(seed, seed * 1.7);
	vec2 w = vec2(noise(p * 0.9 + 3.1), noise(p * 0.9 + 9.7)) - 0.5;
	return fbm(p + w * 0.8);
}

// returns rgb + coverage (0 / 1, hard pixel edges, 3-4 tones)
vec4 clouds(vec2 px, float scale, float speed, float seed, float amount) {
	vec2 q = floor(px / 2.0) * 2.0 + 1.0;                     // 2 px blocks
	float d = dens(q, scale, speed, seed);
	float thr = mix(0.74, 0.47, amount);
	if (d < thr) return vec4(0.0);
	float dl = dens(q + vec2(-3.0, -4.0), scale, speed, seed); // towards the light (up-left)
	float db = dens(q + vec2(2.0, 5.0), scale, speed, seed);   // below
	vec3 hi = overlay_only ? mist_hi : k_chi(tod);
	vec3 base = overlay_only ? mist_base : k_cba(tod);
	vec3 sh = overlay_only ? mist_shade : k_csh(tod);
	vec3 col = d > thr + 0.17 ? mix(base, sh, 0.45) : base;
	if (db < thr) col = sh;
	if (dl < thr) col = hi;
	return vec4(col, 1.0);
}

void fragment() {
	vec2 px = floor(UV * size);
	vec2 uv = (px + 0.5) / size;
	float sunh = sin((tod - 0.25) * 6.28318);                  // +1 noon, -1 midnight
	float night = smoothstep(0.12, -0.25, sunh);

	// the two cloud layers (far = small, slow, dimmer; near = bigger)
	vec4 far_c = clouds(px, cloud_scale * 0.55, 0.6, 11.0, cloud_amount * 0.9);
	vec4 near_c = clouds(px, cloud_scale, 1.0, 3.0, cloud_amount);
	float cover = max(far_c.a, near_c.a);

	if (overlay_only) {
		vec4 c = near_c.a > 0.0 ? near_c : far_c;
		float vis = 1.0 - smoothstep(fade_y.x, fade_y.y, uv.y);
		vec4 ha = hole_a, hb = hole_b;
		if (ha.z > ha.x) { vec2 cc = (ha.xy + ha.zw) * 0.5, hs = (ha.zw - ha.xy) * 0.5; vis *= smoothstep(0.0, 0.07, length(max(abs(uv - cc) - hs, 0.0))); }
		if (hb.z > hb.x) { vec2 cc = (hb.xy + hb.zw) * 0.5, hs = (hb.zw - hb.xy) * 0.5; vis *= smoothstep(0.0, 0.07, length(max(abs(uv - cc) - hs, 0.0))); }
		COLOR = vec4(c.rgb, c.a * vis * overlay_alpha);               // smooth alpha: it must read as haze, not noise
	} else {
		float g = clamp(uv.y / horizon, 0.0, 1.0);
		float gq = clamp(floor(g * 9.0 + bayer4(px)) / 9.0, 0.0, 1.0);
		vec3 col = mix(k_top(tod), k_bot(tod), gq);

		// aurora curtains (night only)
		if (aurora_amount > 0.0 && night > 0.0) {
			float x = px.x / size.x;
			float cy = 0.36 + 0.10 * sin(x * 9.0 + TIME * 0.35) + 0.08 * noise(vec2(x * 6.0, TIME * 0.18));
			float prof = smoothstep(cy - 0.26, cy, uv.y) * (1.0 - smoothstep(cy, cy + 0.20, uv.y));
			float streak = 0.35 + 0.65 * noise(vec2(px.x * 0.32, TIME * 0.5));
			float a = prof * streak * aurora_amount * night;
			vec3 ac = mix(vec3(0.25, 1.0, 0.62), vec3(0.62, 0.35, 1.0), smoothstep(cy - 0.10, cy + 0.18, uv.y));
			col = mix(col, ac, step(bayer4(px + 2.0), a * 0.9));
		}

		// stars
		vec2 sc = floor(px / 3.0);
		float h = hash(sc);
		vec2 off = floor(vec2(hash(sc + 1.3), hash(sc + 7.7)) * 3.0);
		if (h > 0.955 && all(equal(px, sc * 3.0 + off))) {
			float tw = step(0.3, 0.5 + 0.5 * sin(TIME * (1.2 + h * 3.0) + h * 60.0));
			float vis = night * star_amount * (1.0 - cover) * smoothstep(0.85, 0.2, uv.y);
			col = mix(col, vec3(1.0, 0.97, 0.86), step(0.2, vis) * (0.55 + 0.45 * tw));
		}

		// sun and moon
		float ang = (tod - 0.25) * 6.28318;
		vec2 sp = vec2(0.5 - cos(ang) * 0.38, 0.62 - sin(ang) * 0.52) * size;
		vec2 mp = vec2(0.5 + cos(ang) * 0.38, 0.62 + sin(ang) * 0.52) * size;
		vec2 p = px + 0.5;
		float ds = length(p - sp);
		float glow = clamp(1.0 - (ds - body_radius) / (body_radius * 2.6), 0.0, 1.0);
		float sun_up = step(-0.04, sunh);                          // the sun is gone after sunset
		col = mix(col, vec3(1.0, 0.88, 0.55), step(bayer4(px + 1.0), glow * glow_amount) * sun_up);
		if (ds < body_radius && sun_up > 0.5) col = vec3(1.0, 0.96, 0.72);
		float dm = length(p - mp);
		float dm2 = length(p - (mp + vec2(body_radius * 0.5, -body_radius * 0.25)));
		if (dm < body_radius && dm2 >= body_radius * 0.9 && night > 0.3) col = vec3(0.94, 0.95, 0.86);

		// clouds on top
		if (far_c.a > 0.0) col = mix(col, far_c.rgb, 0.8);
		if (near_c.a > 0.0) col = near_c.rgb;
		COLOR = vec4(col, 1.0);
	}
	if (use_mask) COLOR.a *= texture(mask, UV).a;
}
