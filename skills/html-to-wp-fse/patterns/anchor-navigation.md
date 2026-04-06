# Pattern: Anchor Navigation

Use this pattern when nav links point to sections on the same page (e.g. `href="#services"`, `href="/#about"`). Do not use it for multi-page navigation.

## How to detect

During Phase 1 analysis, look for:
- Nav links with `href="#..."` or `href="/#..."` values
- A single-page design where all content lives on one scrollable page
- No separate pages in the HTML for Services, About, Contact, etc.

## Implementation

### 1. Add `anchor` to target section blocks

The block's `"anchor"` attribute renders as an `id` on the HTML element. Without it, the link scrolls nowhere.

```html
<!-- wp:group {"anchor":"services","className":"services-section","layout":{"type":"constrained","contentSize":"1200px"}} -->
<div class="wp-block-group services-section" id="services">
  <!-- section content -->
</div>
<!-- /wp:group -->
```

Use lowercase slugs with no spaces. Common anchors: `services`, `about`, `work`, `case-studies`, `contact`.

### 2. Update nav links to use `/#anchor` format

```html
<!-- wp:navigation {"className":"main-nav","overlayMenu":"mobile","layout":{"type":"flex"},"style":{"spacing":{"blockGap":"2rem"}}} -->
  <!-- wp:navigation-link {"label":"Services","url":"/#services","kind":"custom","isTopLevelLink":true} /-->
  <!-- wp:navigation-link {"label":"Case Studies","url":"/#case-studies","kind":"custom","isTopLevelLink":true} /-->
  <!-- wp:navigation-link {"label":"Contact","url":"/#contact","kind":"custom","isTopLevelLink":true} /-->
<!-- /wp:navigation -->
```

Use `/#anchor` (with leading slash) rather than `#anchor` so the link works correctly when the user is on an inner page like `/blog/post-name/`.

### 3. Add smooth scroll CSS

Add to `custom.css`. The `scroll-padding-top` value must match the actual rendered height of the sticky header.

```css
html {
  scroll-behavior: smooth;
  scroll-padding-top: 80px; /* adjust to match sticky header height */
}
```

## Validation checklist

Before marking Phase 4 complete, verify:
- [ ] Every nav link with `/#anchor` has a matching `"anchor"` attribute on a block in the template
- [ ] `scroll-behavior: smooth` and `scroll-padding-top` are in `custom.css`
- [ ] Links work from inner pages (use `/#services` not `#services`)
