#version 460 core
#include <flutter/runtime_effect.glsl>

// Force — the breathing field.
//
// A domain-warped value-noise field in the Force monochrome palette, plus a
// vignette, a slow radial "breath", and per-frame grain. Deliberately almost
// invisible: it should read as the room the type is standing in, never as a
// graphic. Nothing here is a rainbow gradient.
//
// Cost budget: 2-octave fbm called 3x (warp, warp, field) = 6 value-noise
// samples = 24 hashes per pixel. Cheap enough for 120 Hz at 3x on an A-series.

precision highp float;

uniform vec2  uSize;      // logical size of the paint area
uniform float uTime;      // seconds since scene start
uniform float uIntensity; // 0..1 global amount — scenes fade this
uniform float uBreath;    // 0..1 extra swell, driven by the hold gesture
uniform vec2  uFocus;     // 0..1 normalised focal point of the field
uniform float uMode;      // 0 = background greys, 1 = ink range (used as a text fill)

out vec4 fragColor;

// --- Force palette (sRGB 0..1) ---------------------------------------------
const vec3 kBase      = vec3(0.078, 0.082, 0.082); // #141515
const vec3 kLow       = vec3(0.106, 0.110, 0.114); // #1B1C1D
const vec3 kContainer = vec3(0.133, 0.137, 0.141); // #222324
const vec3 kStone     = vec3(0.376, 0.392, 0.416); // #60646A

float hash(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

float vnoise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f); // smoothstep
  float a = hash(i);
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));
  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Two octaves. Three would be prettier and 50% dearer; at this contrast
// nobody can tell.
float fbm(vec2 p) {
  return 0.62 * vnoise(p) + 0.31 * vnoise(p * 2.17 + 11.3);
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 uv = frag / uSize;

  // Correct for aspect so the field doesn't smear on a tall phone.
  float aspect = uSize.x / max(uSize.y, 1.0);
  vec2 p = vec2(uv.x, uv.y / max(aspect, 0.0001)) * 1.9;

  float t = uTime * 0.035;               // very slow. This is a room, not a lava lamp.
  float breath = 0.5 + 0.5 * sin(uTime * 0.28);

  // Domain warp — two levels. Gives the field a fluid, non-repeating drift
  // that a CSS gradient animation physically cannot produce.
  vec2 q = vec2(fbm(p + vec2(0.0, t)), fbm(p + vec2(5.2, 1.3 - t)));
  vec2 r = vec2(fbm(p + 1.7 * q + vec2(1.7, 9.2) + t * 0.7),
                fbm(p + 1.7 * q + vec2(8.3, 2.8) - t * 0.5));
  float f = fbm(p + 1.4 * r);

  // Focal swell: a soft lobe under the type, breathing.
  vec2 fp = (uv - uFocus) * vec2(1.0, 1.0 / max(aspect, 0.0001));
  float d = length(fp);
  float lobe = exp(-d * d * (3.2 - 1.1 * breath - 1.4 * uBreath));

  // Mode 1: the same field remapped into the ink range, so it can be used as
  // the *fill* of the display serif. Same warp, same grain, same breath — the
  // type ends up made of the room it is standing in. Doing this in a webview
  // means rasterising text to a texture and compositing it in WebGL; here it
  // is a ShaderMask and one extra program instance.
  if (uMode > 0.5) {
    // Keep the swing wide enough to actually see inside a 30 px glyph, but
    // never let the darkest tone fall below `mute` — this is a claim about who
    // you are, and it has to stay legible while it moves.
    float ink = smoothstep(0.08, 0.78, f * 1.15 + lobe * 0.16);
    vec3 tone = mix(vec3(0.604, 0.620, 0.624), vec3(0.949, 0.949, 0.941), ink);
    tone += (hash(frag + fract(uTime) * 91.0) - 0.5) * 0.050;
    fragColor = vec4(tone, 1.0);
    return;
  }

  // Compose in the greys only. Total swing is ~4% luminance.
  float amt = uIntensity;
  vec3 col = kBase;
  col = mix(col, kLow, clamp(f * 1.25, 0.0, 1.0) * 0.85 * amt);
  col = mix(col, kContainer, lobe * (0.30 + 0.34 * breath + 0.55 * uBreath) * amt);
  // A whisper of stone in the warp ridges — keeps it from reading as flat grey.
  float ridge = smoothstep(0.55, 0.92, f + 0.25 * lobe);
  col = mix(col, kStone, ridge * 0.055 * amt * (0.6 + 0.4 * uBreath));

  // Vignette: pull the corners under so the type always sits in the light.
  float vig = 1.0 - 0.42 * smoothstep(0.28, 1.05, length((uv - 0.5) * vec2(1.0, 1.25)) * 1.55);
  col *= vig;

  // Grain. Per-frame, tiny, and the single thing that stops the gradient
  // banding on an OLED at these luminances.
  float g = hash(frag + fract(uTime) * 137.0) - 0.5;
  col += g * 0.016 * (0.55 + 0.45 * amt);

  fragColor = vec4(col, 1.0);
}
