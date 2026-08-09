# Illustration generation — cost & capability research

**Researched: 2026-08-04.** Every price below was pulled live on this date. Image-model
pricing moves monthly and several models on this page have published shutdown dates
inside the next four months. **Re-verify before you commit to anything.**

Where a number could not be read off the provider's own page, it is marked
**[UNVERIFIED]** with an explanation of why. Do not treat those as facts.

---

## 0. The use case, restated as constraints

| Constraint | Value |
|---|---|
| Volume | ~13 images/user/year (1 at signup + 1 per 28 days) |
| Style | 19th-c. engraving / woodcut, fine cross-hatched black linework |
| Composition | Subject isolated, plain background, knocked out to alpha, recomposited over app colour |
| Style consistency | High priority — every user's image must look like one hand drew it |
| Latency budget | <20s acceptable, <5s nicer (user is mid-onboarding) |
| Backend | Vercel serverless |
| Budget | Free-to-use hobby app, unknown user count |

**Derived budget maths** (use this to read the table):

| $/image | $/user/year | 1,000 users/yr | 10,000 users/yr |
|---|---|---|---|
| $0.003 | $0.04 | $39 | $390 |
| $0.005 | $0.065 | $65 | $650 |
| $0.04 | $0.52 | $520 | $5,200 |
| $0.08 | $1.04 | $1,040 | $10,400 |
| $0.17 | $2.21 | $2,210 | $22,100 |

At this volume, **anything at or under ~$0.04/image is affordable**; anything at or above
~$0.15/image (the "high" tier of the GPT Image family) is not, for a free app.

---

## 1. Hosted API pricing per image — cheapest to most expensive

All figures are USD for a single ~1024×1024 image unless noted. Ranges reflect
size variation (1024×1024 vs 1024×1536 / 1536×1024) or resolution tiers.

| $/image | Model | Provider | Notes | Source |
|---|---|---|---|---|
| $0.00 | Gemini free tier (Nano Banana family) | Google AI Studio | ~500 img/day claimed **[UNVERIFIED]** — third-party only | [search](https://www.aifreeapi.com/en/posts/gemini-image-generation-free-api) |
| $0.00 | `FLUX.1-schnell-Free` endpoint | Together | Free endpoint still listed; original offer was "3 months free" from 2024. Current terms **[UNVERIFIED]** | [together.ai](https://www.together.ai/models/flux-1-schnell) |
| **$0.0019** | Stable Diffusion XL | Together | Cheapest metered image gen found | [together.ai/pricing](https://www.together.ai/pricing) |
| **$0.0027** | FLUX.1 [schnell] | Together | 4 steps default | [together.ai/pricing](https://www.together.ai/pricing) |
| $0.003 | FLUX.1 [schnell] | Replicate | Billed $3.00 / 1,000 output images | [replicate.com/pricing](https://replicate.com/pricing) |
| $0.003/MP | FLUX.1 [schnell] | fal | Rounds up to nearest MP | [fal.ai](https://fal.ai/models/fal-ai/flux/schnell) **[PARTIAL]** |
| $0.005–0.006 | gpt-image-2 **low** | OpenAI | | [OpenAI image guide](https://developers.openai.com/api/docs/guides/image-generation) |
| $0.005–0.006 | gpt-image-1-mini **low** | OpenAI | | same |
| $0.005/MP | FLUX.2 Flash | fal | | [fal](https://fal.ai/learn/devs/flux-2-flash-developer-guide) **[PARTIAL]** |
| $0.009–0.013 | gpt-image-1.5 **low** | OpenAI | | [OpenAI image guide](https://developers.openai.com/api/docs/guides/image-generation) |
| $0.011 | Background removal **or** vectorize | Recraft | 10 API units | [recraft.ai/pricing?tab=api](https://www.recraft.ai/pricing?tab=api) |
| $0.011–0.015 | gpt-image-1-mini **medium** | OpenAI | | [OpenAI image guide](https://developers.openai.com/api/docs/guides/image-generation) |
| $0.011–0.016 | gpt-image-1 **low** | OpenAI | | same |
| $0.012/MP | FLUX.2 [dev] | fal | Commercial licence included | [fal](https://fal.ai/models/fal-ai/flux-2) **[PARTIAL]** |
| from $0.014 | FLUX.2 [klein] 4B | BFL | 1st MP flat, then per-MP | [docs.bfl.ai](https://docs.bfl.ai/quick_start/pricing) |
| $0.0154 | FLUX.1 [dev] / FLUX.2 [dev] | Together | | [together.ai/pricing](https://www.together.ai/pricing) |
| from $0.015 | FLUX.2 [klein] 9B | BFL | | [docs.bfl.ai](https://docs.bfl.ai/quick_start/pricing) |
| $0.02 | Imagen 4 Fast | Google / Together | ⚠️ **Google shutting down Imagen 4 on 2026-08-17** | [ai.google.dev pricing](https://ai.google.dev/gemini-api/docs/pricing) |
| $0.025 | FLUX.1 [dev] | Replicate | | [replicate.com/pricing](https://replicate.com/pricing) |
| **$0.03** | Ideogram 4.0 Turbo / 3.0 Turbo / 3.0 Flash | Ideogram | | [ideogram.ai/api-pricing](https://ideogram.ai/api-pricing/) |
| $0.03 | Stable Image Core | Stability | 3 credits @ $0.01 **[UNVERIFIED]** | third-party only, see §6 |
| from $0.03 | FLUX.2 [pro] | BFL | | [docs.bfl.ai](https://docs.bfl.ai/quick_start/pricing) |
| $0.03 | FLUX.2 [flex] / [pro] | Together | | [together.ai/pricing](https://www.together.ai/pricing) |
| $0.0336 | Gemini 3.1 Flash Lite Image (Nano Banana 2 Lite) | Google | 1K; batch $0.0168 | [ai.google.dev pricing](https://ai.google.dev/gemini-api/docs/pricing) |
| $0.034–0.050 | gpt-image-1.5 **medium** | OpenAI | | [OpenAI image guide](https://developers.openai.com/api/docs/guides/image-generation) |
| $0.035 | Recraft V4.1 (raster) | Recraft | 35 units | [recraft.ai/pricing?tab=api](https://www.recraft.ai/pricing?tab=api) |
| $0.036–0.052 | gpt-image-1-mini **high** | OpenAI | | [OpenAI image guide](https://developers.openai.com/api/docs/guides/image-generation) |
| $0.039 | Gemini 2.5 Flash Image (Nano Banana) | Google | batch $0.0195 | [ai.google.dev pricing](https://ai.google.dev/gemini-api/docs/pricing) |
| $0.04 | Recraft V4 (raster) | Recraft | | [recraft.ai/pricing?tab=api](https://www.recraft.ai/pricing?tab=api) |
| $0.04 | FLUX 1.1 [pro] / FLUX.1 Kontext [pro] | BFL | | [docs.bfl.ai](https://docs.bfl.ai/quick_start/pricing) |
| **$0.04** | **Ideogram 3.0 Turbo — TRANSPARENT BACKGROUND** | Ideogram | native alpha, see §4 | [ideogram.ai/api-pricing](https://ideogram.ai/api-pricing/) |
| $0.041–0.053 | gpt-image-2 **medium** | OpenAI | | [OpenAI image guide](https://developers.openai.com/api/docs/guides/image-generation) |
| $0.042–0.063 | gpt-image-1 **medium** | OpenAI | | same |
| $0.045–0.151 | Gemini 3.1 Flash Image (Nano Banana 2) | Google | scales 0.5K→4K | [ai.google.dev pricing](https://ai.google.dev/gemini-api/docs/pricing) |
| $0.06 | Ideogram 4.0 / 3.0 Default | Ideogram | | [ideogram.ai/api-pricing](https://ideogram.ai/api-pricing/) |
| from $0.05 | FLUX.2 [flex] | BFL | | [docs.bfl.ai](https://docs.bfl.ai/quick_start/pricing) |
| $0.065 | SD3.5 | Stability | **[UNVERIFIED]** | third-party only |
| $0.07 | Ideogram 3.0 Default — transparent | Ideogram | | [ideogram.ai/api-pricing](https://ideogram.ai/api-pricing/) |
| from $0.07 | FLUX.2 [max] | BFL | | [docs.bfl.ai](https://docs.bfl.ai/quick_start/pricing) |
| **$0.08** | **Recraft V4.1 Vector / V4 Vector — native SVG** | Recraft | see §2 | [recraft.ai/pricing?tab=api](https://www.recraft.ai/pricing?tab=api) |
| $0.08 | Stable Image Ultra | Stability | **[UNVERIFIED]** | third-party only |
| $0.09 | Ideogram V3 Quality | Replicate | | [replicate.com/pricing](https://replicate.com/pricing) |
| $0.10 | Ideogram 4.0 Quality / 3.0 Quality-transparent | Ideogram | | [ideogram.ai/api-pricing](https://ideogram.ai/api-pricing/) |
| $0.133–0.200 | gpt-image-1.5 **high** | OpenAI | | [OpenAI image guide](https://developers.openai.com/api/docs/guides/image-generation) |
| $0.134 | Gemini 3 Pro Image (Nano Banana Pro) | Google | 1K/2K; $0.24 at 4K | [ai.google.dev pricing](https://ai.google.dev/gemini-api/docs/pricing) |
| $0.165–0.211 | gpt-image-2 **high** | OpenAI | | [OpenAI image guide](https://developers.openai.com/api/docs/guides/image-generation) |
| $0.167–0.250 | gpt-image-1 **high** | OpenAI | | same |
| $0.20 | Ideogram Instructional Edit | Ideogram | | [ideogram.ai/api-pricing](https://ideogram.ai/api-pricing/) |
| $0.21 | Recraft V4.1 Pro (raster) | Recraft | | [recraft.ai/pricing?tab=api](https://www.recraft.ai/pricing?tab=api) |
| $0.30 | Recraft V4.1 Pro Vector | Recraft | | same |

### Model lifecycle warnings (verified from providers' own deprecation pages)

- **`gpt-image-1-mini` and `gpt-image-1.5` shut down 2026-12-01**, replacement `gpt-image-2`.
  Announced 2026-06-02. ([OpenAI deprecations](https://developers.openai.com/api/docs/deprecations))
- **`dall-e-2` and `dall-e-3` shut down 2026-05-12** — already gone.
- **`gpt-image-1` is NOT on OpenAI's deprecations page** as of today. Several third-party
  blogs claim a 2026-10-23 retirement; I could not corroborate that from OpenAI. Treat
  the blog claim as wrong until OpenAI says otherwise.
- **Google's Imagen 4 (fast/standard/ultra) shuts down 2026-08-17** — thirteen days from
  now. Do not build on Imagen. ([Gemini pricing page](https://ai.google.dev/gemini-api/docs/pricing))

### OpenAI's pricing is token-metered, not per-image

OpenAI's [pricing page](https://developers.openai.com/api/docs/pricing) only publishes
per-1M-token rates (gpt-image-1: $5/1M text in, $10/1M image in, $40/1M image out, batch
–50%). The per-image figures above come from the calculator in OpenAI's own
[image generation guide](https://developers.openai.com/api/docs/guides/image-generation),
which is authoritative but derived.

---

## 2. Which models actually do engraving / line art — and the vector question

### 🚩 LOUD FLAG: Recraft is the only provider found that emits **true SVG**, and it ships a literal `Engraving` style

Recraft's API has dedicated vector models that return **real SVG, not a traced raster**.
Any model ID ending in `_vector` produces SVG.
([API reference](https://www.recraft.ai/docs/api-reference/endpoints))

- Base URL: `https://external.api.recraft.ai/v1`, endpoint `/images/generations/vector`
- Model IDs: `recraftv2_vector`, `recraftv3_vector`, `recraftv4_vector`,
  `recraftv4_1_vector`, `recraftv4_1_pro_vector`

The **Recraft V3 Vector** style list includes, verbatim:
**`Engraving`**, **`Line art`**, **`Linocut`**, `Bold stroke`, `Thin`, `Marker outline`,
`Colored stencil`, `Editorial`.
The **V3 raster** list additionally has `Digital engraving`, `Color engraving`,
`Crosshatch`, `Antiquarian`, `Noir`, `Bold Sketch`.
([Recraft styles docs](https://www.recraft.ai/docs/api-reference/styles))

`Engraving` + `Line art` + `Crosshatch` + `Antiquarian` is an almost literal description
of the brief. Nobody else has named styles this close.

**Why SVG would be the ideal outcome for this use case:**
- No background removal step at all — an SVG simply has no background unless one is drawn.
- Recolour by rewriting `fill`/`stroke`, or by setting `fill="currentColor"` and letting
  the app's CSS drive it. This is exactly the "recomposite over the app's own colour"
  requirement, solved for free.
- Scales to any device pixel ratio; one asset serves phone, tablet, OG image, print.
- Tiny to store and cache versus a 1024px PNG.

**The honest caveat, and why you must spike this before committing:** fine cross-hatching
is the single worst thing to represent in vector. Every hatch stroke is a path. A dense
19th-c. engraving could produce an SVG with tens of thousands of anchor points, and
reviewers report Recraft vectors emerging as "chaotic collections of excessive anchor
points and redundant layers" where "native SVG does not always mean immediately usable
SVG" ([Z.Tools review](https://z.tools/blog/recraft-v4-vector-image),
[Ropewalk](https://ropewalk.ai/blog/recraft-v4-pro-svg-guide-2026)). It may come back
beautiful and 40 KB, or it may come back 4 MB and unrenderable. **Generate five and
measure the file size and path count before you build on it.**

**Version trap:** Recraft's docs say plainly that "Styles are not yet supported for V4
models" and "Style creation is not yet supported in Recraft V4"
([styles docs](https://www.recraft.ai/docs/api-reference/styles),
[V4 model docs](https://www.recraft.ai/docs/recraft-models/recraft-V4)). The named
`Engraving` / `Line art` styles therefore require **`recraftv3_vector`**, not V4. But
Recraft's public pricing page only lists V4 and V4.1 rows. **[UNVERIFIED]** — V3 Vector
pricing is not on the current pricing page. Recraft has priced vector at **$0.08 across
V2, V3, V4 and V4.1** and stated "$0.04 per raster image, $0.08 per vector image" for V3
([Recraft, X](https://x.com/recraftai/status/1861131720008900753)), so $0.08 is the
near-certain figure, but confirm against your actual billing on the first call.

### Ideogram — strong for graphic/design work, raster only

Ideogram's reputation for graphic and design output holds up: `style_type` exposes a
`DESIGN` mode, and the V3 line is widely rated top-tier for flat/editorial illustration.
But **Ideogram does not emit true vector**. Its SVG export converts a raster output to
vector after the fact; the model produces raster images
([review](https://www.recraft.ai/ai-models/ideogram)). That trace step is exactly where
cross-hatching degrades.

What Ideogram *does* have that nobody else does at this price: **a native
transparent-background generation endpoint** (§4) and **style codes / style reference
images** (§5). For a raster pipeline it's the strongest single option.

### The rest, judged on engraving specifically

- **FLUX.1 [schnell] / FLUX.2** — good general line-art capability, but no style presets,
  no named engraving mode, and consistency depends entirely on your prompt. Fine if you
  lock a prompt + seed; weak if you need the look guaranteed.
- **GPT Image family** — excellent instruction following, so a long, precise engraving
  prompt works well. But it is the most expensive family here at usable quality, it has
  a documented consistency weakness ("may occasionally struggle to maintain visual
  consistency for recurring characters or brand elements across multiple generations" —
  [OpenAI guide](https://developers.openai.com/api/docs/guides/image-generation)), and
  the same guide warns "complex prompts may take up to 2 minutes to process", which
  breaks the onboarding latency budget.
- **Gemini / Nano Banana** — fast and cheap, up to 3 style-reference images on 3.1 Flash
  Image, but **no alpha channel at all** (§4), which is disqualifying-ish here.
- **Stability** — nothing distinctive for engraving, pricing unverifiable (§6). Skip.

---

## 3. Open-source / self-hosted

### Licences (all verified)

| Model | Licence | Commercial use? |
|---|---|---|
| **FLUX.1 [schnell]** | Apache-2.0 | ✅ Yes, unrestricted |
| **FLUX.2 [klein] 4B** | Apache-2.0 | ✅ Yes, royalty-free ([HF](https://huggingface.co/black-forest-labs/FLUX.2-klein-4B)) |
| FLUX.2 [klein] 9B | Non-commercial | ❌ Research only |
| FLUX.1 / FLUX.2 [dev] | BFL non-commercial | ❌ Not for self-hosting commercially — but ✅ fine via Replicate/Together/fal, who license it |
| **Qwen-Image 2.0** (7B, Feb 2026) | Apache-2.0 | ✅ Yes |
| **Z-Image Turbo** (6B, Tongyi) | Apache-2.0 | ✅ Yes |
| SDXL | CreativeML Open RAIL++-M | ✅ Yes |
| **SD3.5** | Stability Community Licence | ✅ Free commercial **under $1M annual revenue**; above that you must buy an Enterprise licence ([Stability](https://stability.ai/license)) — fine for a hobby app |

### Inference speed on cheap GPUs

- **FLUX.2 [klein] 4B**: 0.57s for 1024×1024 at 4 steps on a single H100; ~13 GB VRAM,
  runs on consumer cards ([InferenceBench](https://inferencebench.io/blog/flux2-klein-4b-image-generation-benchmark/))
- **Z-Image Turbo 6B**: ~2.3s for 1024×1024 at 8 steps on an RTX 4090 (Alibaba's own figure)
- **FLUX.1 [dev]**: ~26s at 28 steps on H100 — too slow and the wrong licence
- **FLUX.1 [schnell]**: 4 steps, comfortably sub-2s on L40S-class hardware

### Serverless GPU rates (verified from providers' pricing pages)

| GPU | Modal $/s | Replicate $/s | RunPod Serverless $/hr |
|---|---|---|---|
| T4 | $0.000164 | $0.000225 | — |
| L4 / A5000 / 3090 (24GB) | $0.000222 | — | $0.69 |
| A10 | $0.000306 | — | — |
| L40S (48GB) | $0.000542 | $0.000975 | $1.75 |
| A100 40GB | $0.000583 | — | — |
| A100 80GB | $0.000694 | $0.001400 | $2.72 |
| H100 | $0.001097 | $0.001525 | $4.55 |
| H200 | $0.001261 | — | $5.93 |
| B200 | $0.001736 | — | $8.64 |

Sources: [Modal](https://modal.com/pricing) · [Replicate](https://replicate.com/pricing) ·
[RunPod](https://www.runpod.io/pricing). Modal's Starter tier includes **$30/month free
credits**. Replicate bills private models for setup + idle + active time, *except*
"fast booting fine-tunes", which are billed for active processing only.

### 🔴 Where "rent a GPU" crosses over: it doesn't, at this volume

**Cold starts eat you alive.** At 13 images/user/year, arrivals are sparse and random —
in practice *almost every request is a cold start*. A 13 GB diffusion checkpoint takes
roughly 20–60s to pull and load. On Modal's L40S at $0.000542/s that's **$0.011–0.033 of
pure cold-start cost per image**, before any inference. Worse, it blows the 20s latency
budget outright, which is the thing the brief explicitly says is not negotiable.

**Always-on GPU:** the cheapest serverless-class 48 GB card is RunPod's A40/A6000 at
$1.22/hr = **$10,700/year**. Against Together's FLUX.1 [schnell] at $0.0027/image that
buys 4.0M images — **~305,000 users/year**. Against a $0.04/image API it buys 267,000
images — **~20,500 users/year**.

**Conclusion: hosted API wins outright below roughly 20,000 active users, and below
~300,000 users if you're comparing against the cheap open-weight endpoints.** For a hobby
app this crossover is never reached. Self-hosting is only worth it if you need something
the hosted APIs cannot sell you — which, for this use case, means one thing only: a
**custom LoRA** trained on your exact engraving reference set (§5).

### And it cannot run on Vercel regardless

Vercel Functions have no GPU. Bundle limit is 250 MB (5 GB with the
[large functions](https://vercel.com/docs/functions/limitations) beta, still no GPU). A
self-hosted model always means a second provider — Modal/Replicate/RunPod/fal — called
over HTTP from the Vercel function, at which point you've reintroduced the cold-start
problem with extra steps.

**Good news on the Vercel side:** with Fluid Compute (default on new projects), **Hobby
gets 300s max duration**, Pro gets 300s default / 800s max
([Vercel Functions Limits](https://vercel.com/docs/functions/limitations), last updated
2026-07-01). A 20s image API call is completely fine even on the free plan, and I/O wait
doesn't count toward billed Active CPU time. **No hosted API in this document is blocked
by Vercel serverless.**

One gotcha: **request/response body cap is 4.5 MB**. Don't return the PNG inline from the
function — stream the provider's URL straight into Blob storage and return the blob URL.

---

## 4. Background removal / transparency

### Native transparent output — verified

| Provider | Native alpha? | Detail |
|---|---|---|
| **Ideogram 3.0** | ✅ **Yes** | Dedicated endpoint `POST /v1/ideogram-v3/generate-transparent`. "Clean alpha channel in a single step — no post-processing." **Note: `rendering_speed=FLASH` returns 400 on this endpoint**; use TURBO/DEFAULT/QUALITY. Priced $0.04 / $0.07 / $0.10 ([docs](https://developer.ideogram.ai/api-reference/api-reference/generate-transparent-v3), [pricing](https://ideogram.ai/api-pricing/)) |
| **OpenAI gpt-image-1, -1-mini, -1.5** | ✅ Yes | `background: "transparent"`, `output_format` must be `png` or `webp` |
| **OpenAI gpt-image-2** | ❌ **No** | Verified verbatim: "`gpt-image-2` and `gpt-image-2-2026-04-21` do not support transparent backgrounds" ([API reference](https://developers.openai.com/api/reference/python/resources/images/methods/generate)). ⚠️ **Since 1.5 and mini both die 2026-12-01 and gpt-image-2 is their replacement, OpenAI's transparency path has a four-month shelf life.** |
| **Recraft `_vector` models** | ✅ N/A — better | SVG has no background unless drawn. Nothing to remove. |
| **Google Gemini / Nano Banana (all)** | ❌ **No** | "Google's image models output flat RGB pixels with no alpha channel." Confirmed by absence from [Google's own image-gen docs](https://ai.google.dev/gemini-api/docs/image-generation), which list only JPEG and PNG output with no transparency parameter. |
| FLUX (all), Stability, SDXL | ❌ No | Post-process required |

### Cheap post-hoc removal, if the model can't do it

| Tool | Cost | Source |
|---|---|---|
| **Recraft `/images/removeBackground`** | **$0.011/image** (10 API units) | [recraft.ai/pricing?tab=api](https://www.recraft.ai/pricing?tab=api) |
| **BiRefNet v2 on fal** | $0.0008 per compute-second — pennies per image | [fal](https://fal.ai/models/fal-ai/birefnet/v2) **[PARTIAL]** |
| rembg on Replicate | ~$0.0038/run | [replicate.com/cjwbw/rembg](https://replicate.com/cjwbw/rembg) **[PARTIAL]** |
| **rembg self-hosted** | **$0.00** — but 250 MB Vercel bundle limit makes bundling ONNX weights awkward; use the 5 GB large-functions beta or a separate service | — |
| Ideogram `Replace Background` | $0.03–0.06 | [ideogram.ai/api-pricing](https://ideogram.ai/api-pricing/) |

**The trick that makes any model work:** because your subject is black linework on a plain
background, you don't strictly need an ML matte. Prompt for a **pure white** (or
chroma-key `#00FF00`) background and threshold it out in `sharp` inside the Vercel function
— zero marginal cost, sub-100ms, and for high-contrast black-on-white engraving it's
*more* reliable than a segmentation model, which will happily eat thin hatch lines it
mistakes for background. This is a real advantage of the chosen style. Chroma-key + HSV
detection is the documented workaround for Gemini's missing alpha, and it applies equally
to FLUX.

---

## 5. Style consistency across separate generations

Ranked by how strong the guarantee is:

| Mechanism | Provider | Strength | Cost |
|---|---|---|---|
| **Custom LoRA** trained on your own engraving set | Replicate / fal, on FLUX | 🟢 Strongest — the style is baked into weights | Train: ~$1.46–2.00 one-off ([Replicate](https://replicate.com/docs/get-started/fine-tune-with-flux), [fal](https://fal.ai/models/fal-ai/flux-lora-fast-training)). Inference: Replicate "fast booting fine-tunes" bill active time only |
| **`style_id`** — custom style from reference images | **Recraft** | 🟢 Strong, persistent ID reused on every call | $0.044 to create (40 units). ⚠️ API-created styles are **V3 / V3 Vector only** ([docs](https://www.recraft.ai/docs/api-reference/styles)) |
| **Named `Engraving` / `Line art` style** | **Recraft V3 (Vector)** | 🟢 Strong — it's a first-class trained style, not a prompt | $0 extra |
| **`style_code`** — 8-char hex style handle | **Ideogram V3** | 🟢 Strong — a stable, reusable style token. Mutually exclusive with `style_type` and `style_reference_images` | $0 extra |
| **`style_reference_images`** (up to 3, ≤10 MB total) | **Ideogram V3** | 🟡 Good | $0 extra |
| **Style reference images** (up to 3) | Gemini 3.1 Flash Image | 🟡 Good — but 3 Pro Image has *no* style refs, only character refs | $0 extra |
| **Input reference images** | OpenAI gpt-image-* | 🟡 Mixed — OpenAI's own docs admit consistency wobble | Reference images bill as image *input* tokens |
| **Character reference** | Ideogram 3.0 only | 🟡 For subjects, not style | +$0.07–0.10/image |
| Locked prompt + fixed seed | FLUX, everything | 🔴 Weakest — prompt-level only | $0 |

**Practical read:** Recraft's `style_id` and Ideogram's `style_code` are the two "persistent
style ID" mechanisms the brief asks about, and both exist. Recraft's is stronger because
it's derived from *your* reference images and pinned to a UUID; Ideogram's `style_code` is
a handle you capture from a generation you liked and replay. Either beats prompt
engineering by a wide margin. A LoRA beats both but costs a $2 training run plus the
operational burden of a second provider — worth it only if the off-the-shelf styles fail
your taste test.

---

## 6. Recommendation

### Primary pick — **Ideogram 3.0 Turbo, `generate-transparent` endpoint — $0.04/image**

`POST https://api.ideogram.ai/v1/ideogram-v3/generate-transparent`

Why it wins for *this* app:

1. **One call, alpha included.** No rembg step, no thresholding, no second provider, no
   extra latency. Native alpha produced during the render, so hatch lines aren't chewed up
   by a segmentation model.
2. **$0.52/user/year.** 1,000 users = $520/yr. Affordable for a free hobby app.
3. **`style_code` gives you the persistent style ID.** Generate until you love one, capture
   its 8-char code, replay it forever. That's the "came from the same hand" requirement,
   solved with a string constant.
4. **TURBO is the fast tier** and is permitted on the transparent endpoint (FLASH is not —
   it 400s). Comfortably inside 20s.
5. **No published deprecation.** Unlike OpenAI's transparency path (dead 2026-12-01) and
   Imagen (dead 2026-08-17).
6. Ideogram's design/graphic reputation is real — `style_type: DESIGN` is a first-class mode.

Plain HTTPS REST, so it runs from a Vercel function with zero friction.

### 🚩 Spike this first — **Recraft V3 Vector, `Engraving` / `Line art` — $0.08/image**

`POST https://external.api.recraft.ai/v1/images/generations/vector`, `model: recraftv3_vector`

**If the SVG comes back clean, this is strictly better than the primary pick and you should
switch.** It gives you: literal named `Engraving` and `Line art` styles; true vector so it
scales and recolours via `currentColor`; no background to remove; tiny payloads; plus
`style_id` custom styles trained on your own references.

The risk is specific and testable: **fine cross-hatching may produce a pathological SVG**
(tens of thousands of anchor points, multi-MB files). Spend an hour: generate five images,
check file size and `<path>` count. If they're under ~200 KB and render fast in Flutter's
SVG renderer, take it. If they're 4 MB monsters, fall back to the primary pick and move on.

Double it as $0.08/image = $1.04/user/year = $1,040 per 1,000 users. Still affordable, just
2× the primary.

### Cheap fallback — **FLUX.1 [schnell] on Together — $0.0027/image** + white-key removal

15× cheaper than the primary. $0.04/user/year; **1,000 users costs $39/year**. 4 steps, so
it's fast (Together quote 315 ms on their Turbo endpoint). Apache-2.0, no licensing worry.

What you give up: no style presets and no persistent style ID — consistency comes only from
a locked prompt + fixed seed, which is the weakest guarantee in §5. And you must do your own
background knockout — but as noted in §4, prompting for a pure-white background and
thresholding in `sharp` costs nothing and works *well* for black-on-white engraving.

**Use this if:** cost genuinely becomes a problem, or if a prompt-locked schnell output
turns out to look good enough. Test it against the primary before assuming it won't.

### Explicitly not recommended

- **GPT Image family** — usable quality (medium/high) costs $0.04–0.25, its own docs warn
  of up to 2-minute latency on complex prompts, it self-reports consistency wobble, and the
  only variants with transparency support die on 2026-12-01.
- **Google Gemini / Nano Banana** — fast (Nano Banana 2 Lite ~4s) and cheap ($0.0336), but
  **zero alpha channel support across the entire family**, which forces a second call. If
  you use it, chroma-key green and threshold.
- **Imagen 4** — shuts down 2026-08-17.
- **Stability AI** — nothing distinctive for engraving, and I could not verify a single
  price from their own page (see below).

### Suggested implementation shape

```
Vercel function (Fluid Compute, maxDuration 60s — Hobby allows 300s)
  → Claude/GPT: user's sentence → engraving prompt (subject + composition only)
  → Ideogram generate-transparent { rendering_speed: "TURBO", style_code: FORCE_STYLE }
  → stream result URL → Vercel Blob (never inline — 4.5 MB response cap)
  → return blob URL
```

Pin `style_code` as an env var. Cache aggressively — these images are generated once every
28 days and never change, so they belong on a CDN with a long max-age forever after.

---

## 7. What I could not verify — read this before trusting anything above

1. **Stability AI — nothing verified.** `platform.stability.ai/pricing` is a client-rendered
   SPA and returns only a page title to a fetcher; `/docs/getting-started/credits` likewise.
   Every Stability figure here ($0.03 Core / $0.08 Ultra / $0.065 SD3.5 / $0.04 SD3.5 Large
   Turbo / 1 credit = $0.01) is from third-party sources. One of those sources also claims
   Stability **retroactively raised** the per-image credit cost from 1.25 to 8 credits in
   August 2026 — I could not confirm or deny this. **Do not plan around Stability numbers.**
2. **fal.ai — partial.** `fal.ai/pricing` returned HTTP 429 on four separate attempts.
   fal figures ($0.003/MP schnell, $0.012/MP FLUX.2 dev, $0.005/MP FLUX.2 Flash, BiRefNet
   $0.0008/compute-second) come from search results quoting fal's own model pages, not from
   a direct read. Directionally right, digits unconfirmed.
3. **Recraft V3 / V3 Vector pricing** is not on the current public pricing page, which only
   lists V4 and V4.1. $0.08 for vector is a strong inference (constant across V2/V4/V4.1 and
   stated by Recraft for V3), not a verified current quote. **This matters** because the
   `Engraving` style requires V3.
4. **Together's free `FLUX.1-schnell-Free` endpoint** still appears in their model list, but
   the "3 months free" framing dates to a 2024 announcement. Current terms unknown.
5. **Gemini free tier of ~500 images/day** — third-party claim, not read off Google's
   rate-limits page.
6. **Latency figures for Recraft and Ideogram** — artificialanalysis.ai (the one good source
   for median generation time) is client-rendered and returned no numbers. Ideogram TURBO
   and Recraft V3 speeds are inferred from tier naming, not measured. **Time them yourself
   in the spike.**
7. **`gpt-image-1` retirement** — third-party blogs say 2026-10-23; OpenAI's own deprecations
   page does not list it. I believe the blogs are wrong, but if you build on gpt-image-1,
   check.

---

## Every source URL

**Official provider pricing / docs**
- OpenAI pricing — https://developers.openai.com/api/docs/pricing
- OpenAI image generation guide (per-image calculator) — https://developers.openai.com/api/docs/guides/image-generation
- OpenAI images.generate API reference (background param) — https://developers.openai.com/api/reference/python/resources/images/methods/generate
- OpenAI deprecations — https://developers.openai.com/api/docs/deprecations
- Google Gemini API pricing — https://ai.google.dev/gemini-api/docs/pricing
- Google Gemini image generation docs — https://ai.google.dev/gemini-api/docs/image-generation
- Black Forest Labs pricing docs — https://docs.bfl.ai/quick_start/pricing
- Black Forest Labs pricing page / calculator — https://bfl.ai/pricing
- Recraft API pricing — https://www.recraft.ai/pricing?tab=api
- Recraft styles reference — https://www.recraft.ai/docs/api-reference/styles
- Recraft API endpoints reference — https://www.recraft.ai/docs/api-reference/endpoints
- Recraft V4 model docs — https://www.recraft.ai/docs/recraft-models/recraft-V4
- Ideogram API pricing — https://ideogram.ai/api-pricing/
- Ideogram generate-transparent v3 docs — https://developer.ideogram.ai/api-reference/api-reference/generate-transparent-v3
- Ideogram generate v3 docs — https://developer.ideogram.ai/api-reference/api-reference/generate-v3
- Together AI pricing — https://www.together.ai/pricing
- Together AI FLUX.1 [schnell] — https://www.together.ai/models/flux-1-schnell
- Replicate pricing — https://replicate.com/pricing
- Replicate FLUX fine-tuning guide — https://replicate.com/docs/get-started/fine-tune-with-flux
- Modal pricing — https://modal.com/pricing
- RunPod pricing — https://www.runpod.io/pricing
- fal.ai FLUX.1 [schnell] — https://fal.ai/models/fal-ai/flux/schnell
- fal.ai BiRefNet v2 — https://fal.ai/models/fal-ai/birefnet/v2
- fal.ai FLUX LoRA fast training — https://fal.ai/models/fal-ai/flux-lora-fast-training
- Stability AI licence — https://stability.ai/license
- Stability AI developer platform pricing (did not render) — https://platform.stability.ai/pricing
- Vercel Functions limits — https://vercel.com/docs/functions/limitations

**Model weights / licences**
- FLUX.2 [klein] 4B (Apache-2.0) — https://huggingface.co/black-forest-labs/FLUX.2-klein-4B
- SD3.5 Large licence — https://huggingface.co/stabilityai/stable-diffusion-3.5-large/blob/main/LICENSE.md

**Secondary / corroborating (treat with suspicion)**
- FLUX.2-klein-4B H100 benchmark — https://inferencebench.io/blog/flux2-klein-4b-image-generation-benchmark/
- Recraft V4 vector review — https://z.tools/blog/recraft-v4-vector-image
- Recraft V4 Pro SVG guide — https://ropewalk.ai/blog/recraft-v4-pro-svg-guide-2026
- Recraft on X, V3 pricing — https://x.com/recraftai/status/1861131720008900753
- Ideogram in Recraft Studio (raster-not-vector note) — https://www.recraft.ai/ai-models/ideogram
- Best open-source image models 2026 — https://www.thundercompute.com/blog/best-open-source-image-generation-models
- Gemini transparent background limitation — https://transparify.app/blog/gemini-transparent-background
- Nano Banana 2 Lite announcement — https://blog.google/innovation-and-ai/models-and-research/gemini-models/gemini-omni-flash-nano-banana-2-lite/
- Stability API pricing breakdown (unverified source for §6 figures) — https://developer.puter.com/tutorials/stability-ai-api-pricing/
- rembg on Replicate — https://replicate.com/cjwbw/rembg
