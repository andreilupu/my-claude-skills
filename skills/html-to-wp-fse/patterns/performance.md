# Pattern: Performance Optimization

Reference this when generating `functions.php` and `custom.css`. These issues consistently appear in Lighthouse audits of FSE themes.

## Font loading (biggest wins)

### Always add preconnect hints

Reduces DNS + TLS handshake time for font CDNs. Add to `wp_head` at priority 1 (before everything else):

```php
function {prefix}_head_hints() {
    echo '<link rel="preconnect" href="https://fonts.googleapis.com">' . "\n";
    echo '<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>' . "\n";
}
add_action( 'wp_head', '{prefix}_head_hints', 1 );
```

If you have other wp_head hooks (e.g. flash-prevention script), combine them into a single function at priority 1.

### Always add `display=swap` to font URLs

Add `&display=swap` to **every** Google Fonts URL. Without it, the browser blocks text rendering until the font loads (FOIT).

```php
// Good
'https://fonts.googleapis.com/css2?family=Inter:wght@400;700&display=swap'
'https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@24,400,0,0&display=block'

// Bad — missing display param
'https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@24,400,0,0'
```

### font-display choice

| Font role | Use | Reason |
|---|---|---|
| Body / heading font | `display=swap` | Shows text immediately with fallback, swaps when loaded |
| Icon font (decorative) | `display=block` | Hides text ligature fallback during load — blank > "light_mode" text flash |
| Critical brand font | `display=block` | Hides text briefly, shows correct font — only for very short load times |

### Non-blocking body font loading (removes from critical render path)

`wp_enqueue_style` always outputs `<link rel="stylesheet">` which is render-blocking. For body/heading fonts (e.g. Inter), FOUT is acceptable — system font shows immediately, swaps when loaded. Output manually in `wp_head` at priority 1 using the `preload` + `onload` pattern:

```php
function {prefix}_head_hints() {
    // ... flash prevention script, preconnect hints ...

    // Non-blocking body font — FOUT acceptable, removes render-blocking CSS from critical path
    $inter_url = 'https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap';
    echo '<link rel="preload" href="' . esc_url( $inter_url ) . '" as="style" onload="this.onload=null;this.rel=\'stylesheet\'">' . "\n";
    echo '<noscript><link rel="stylesheet" href="' . esc_url( $inter_url ) . '"></noscript>' . "\n";
}
```

Then remove the corresponding `wp_enqueue_style` for that font from `wp_enqueue_scripts` (leave a comment explaining it's handled above). The editor enqueue stays unchanged.

**Do NOT use this pattern for icon fonts** (Material Symbols, Font Awesome). Icon FOUT shows raw text ligatures ("light_mode") which is worse than a brief render delay. Keep icon fonts as blocking `wp_enqueue_style` with `display=block`.

---

## Images

### Always upload as WebP

WebP is 25–50% smaller than JPEG/PNG at equivalent quality. WordPress serves whatever format you upload — it does not convert automatically on managed hosts like WordPress.com.

**Before running any seed script**, convert source images to WebP. The REST API seed script does this automatically if Python Pillow is installed:

```bash
pip install Pillow  # one-time setup
bash seed-content-api.sh
```

The script tries `python3 -c "from PIL import Image; ..."` and silently falls back to JPEG if Pillow is unavailable. Always check the output — it prints the file size before and after conversion:
```
Converted to WebP: 45K (was 180K)
```

To manually convert a batch of images before uploading:
```bash
# Using Pillow (Python)
python3 -c "
from PIL import Image
import glob, os
for f in glob.glob('designs/images/*.jpg') + glob.glob('designs/images/*.png'):
    out = os.path.splitext(f)[0] + '.webp'
    Image.open(f).save(out, 'webp', quality=85)
    print(f'{f} → {out}')
"

# Using cwebp (if installed)
for f in designs/images/*.jpg; do cwebp -q 85 "$f" -o "${f%.jpg}.webp"; done
```

Use `quality=85` — visually indistinguishable from the original at ~40% the file size.

### Explicit dimensions prevent CLS

Always set `width` and `height` on `wp:image` blocks. Without them, the browser doesn't reserve space and layout shifts as images load (CLS penalty).

```html
<!-- wp:image {"width":1200,"height":800,"sizeSlug":"full"} -->
<figure class="wp-block-image size-full"><img src="..." width="1200" height="800" alt="..."/></figure>
<!-- /wp:image -->
```

### LCP image

The largest above-the-fold image (usually the hero) is the LCP element. If it's slow to load, add `fetchpriority="high"` via a `render_block` filter:

```php
add_filter( 'render_block_core/image', function( $html, $block ) {
    if ( isset( $block['attrs']['className'] ) && strpos( $block['attrs']['className'], 'hero-image' ) !== false ) {
        $html = str_replace( '<img ', '<img fetchpriority="high" loading="eager" ', $html );
    }
    return $html;
}, 10, 2 );
```

---

## What managed hosting controls (not fixable in theme code)

- **TTFB** (Time to First Byte) — server response time. Controlled by hosting infrastructure, caching layer, and PHP performance. A reading of 300–700ms is typical on shared managed hosting.
- **Static asset cache policy** — hosting determines `Cache-Control` headers on CSS/JS/images. Not configurable per-theme.
- **CDN** — whether assets are served from a CDN is a hosting feature, not a theme concern.

If TTFB > 600ms is a persistent problem, recommend the client upgrade their hosting plan or add a page caching plugin (e.g. WP Super Cache, W3 Total Cache — only if not on a host that handles caching automatically).

---

## Core Web Vitals targets

| Metric | Good | Needs Improvement | Poor |
|---|---|---|---|
| LCP | ≤ 2.5s | 2.5–4s | > 4s |
| INP | ≤ 200ms | 200–500ms | > 500ms |
| CLS | ≤ 0.1 | 0.1–0.25 | > 0.25 |
| FCP | ≤ 1.8s | 1.8–3s | > 3s |
| TTFB | ≤ 800ms | 800ms–1.8s | > 1.8s |

---

## Checklist for Phase 3

- [ ] `preconnect` hints for all font CDNs in `wp_head` at priority 1
- [ ] `&display=swap` on every Google Fonts URL
- [ ] Hero images uploaded as `.webp`
- [ ] `wp:image` blocks have explicit width/height when known
- [ ] No unused font weights loaded (only request weights actually used)
