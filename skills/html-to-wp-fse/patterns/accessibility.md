# Pattern: Accessibility

Reference this when generating templates, CSS, and block markup. These issues appear in Lighthouse accessibility audits and affect WCAG 2.1 AA compliance.

## Contrast ratios (most common failure)

WCAG AA requirements:
- **Normal text** (< 18px regular or < 14px bold): **4.5:1 minimum**
- **Large text** (≥ 18px regular or ≥ 14px bold): **3:1 minimum**
- **UI components** (borders, icons, interactive elements): **3:1 minimum**

### Common failures in FSE themes

| Color | Background | Ratio | Status |
|---|---|---|---|
| `#64748b` | `#ffffff` | 4.36:1 | FAILS normal text |
| `#94a3b8` | `#ffffff` | 2.43:1 | FAILS badly |
| `#64748b` | `#16161a` | 3.75:1 | FAILS normal text |
| `#475569` | `#0a0a0c` | 2.54:1 | FAILS |

### Safe secondary text values

| Mode | Variable | Value | Contrast on bg |
|---|---|---|---|
| Light | secondary text | `#475569` | 7.8:1 on white ✓ |
| Light | muted/meta text | `#4b5563` | 7.5:1 on white ✓ |
| Light | copyright/footnote | `#475569` | 7.8:1 on white ✓ |
| Dark | secondary text | `#94a3b8` | 6.7:1 on #16161a ✓ |
| Dark | muted/meta text | `#94a3b8` | 6.7:1 on #16161a ✓ |
| Dark | copyright/footnote | `#64748b` | 4.5:1 on #0a0a0c ✓ |

**Key rule:** Never use `#64748b` or lighter as normal-size text on white backgrounds. Use `#4b5563` or darker.

### Checking contrast during design

Use the formula: contrast = (L1 + 0.05) / (L2 + 0.05) where L1 > L2.

Quick test: if the color looks "light gray" on white, it probably fails. Gray text needs to be noticeably dark to pass WCAG AA.

---

## Heading hierarchy

Headings must descend sequentially — you cannot skip levels.

**Valid:** h1 → h2 → h3 → h4
**Invalid:** h1 → h3 (skips h2), h2 → h4 (skips h3)

### Common mistake: footer headings

Footer column headings are often styled at h4 or h5 for visual reasons, but if the last heading before the footer is h2, jumping to h4 fails the check.

**Fix:** Use h3 for footer section headings:
```html
<!-- wp:heading {"level":3,"className":"footer-heading"} -->
<h3 class="wp-block-heading footer-heading">Services</h3>
<!-- /wp:heading -->
```

Apply visual sizing via CSS, not heading level:
```css
.footer-heading {
    font-size: 0.875rem !important;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.05em;
}
```

### Heading hierarchy checklist for front-page.html

```
<h1> — one per page, hero or page title
  <h2> — major sections (Services, About, Case Studies, CTA)
    <h3> — cards within sections, footer section headings
      <h4> — sub-items within cards (rare)
```

If a section uses `wp:post-title {"level":3}`, ensure the containing section has an `h2` heading above it.

---

## Alt text for images

Every `wp:image` must have a non-empty `alt` attribute unless the image is purely decorative.

```html
<!-- Informative image — describe what it shows -->
<figure class="wp-block-image"><img src="..." alt="ModalityAI integration dashboard showing AI model connections"/></figure>

<!-- Decorative image — empty alt, role=presentation -->
<figure class="wp-block-image"><img src="..." alt="" role="presentation"/></figure>
```

For `wp:post-featured-image`, the alt text comes from the media library attachment. Remind the user to set alt text when uploading images.

---

## Interactive elements

### Buttons must have accessible labels

If a button contains only an icon (no visible text), it needs `aria-label`:

```html
<button class="theme-toggle-btn" aria-label="Toggle dark mode" data-wp-on--click="actions.toggle">
    <span class="material-symbols-outlined">dark_mode</span>
</button>
```

### Navigation landmark

The `wp:navigation` block renders as `<nav>`. If there are multiple nav elements on the page (main nav + footer nav), add `aria-label` to distinguish them:

```html
<!-- wp:navigation {"className":"main-nav","ariaLabel":"Main navigation",...} -->
```

---

## Lighthouse accessibility score impact

| Issue | Points lost (approx) |
|---|---|
| Contrast failures (multiple elements) | 10–20 pts |
| Heading hierarchy | 3–7 pts |
| Missing alt text | 5–10 pts |
| Missing button labels | 3–5 pts |
| Missing form labels | 5–10 pts |

Fixing contrast + heading hierarchy is typically worth +6 points and addresses ~80% of common FSE theme accessibility failures.

---

## Phase 3 checklist

- [ ] All secondary/muted text colors pass 4.5:1 on their backgrounds
- [ ] Copyright/footnote colors pass 4.5:1 (often overlooked)
- [ ] Heading levels are sequential: h1 → h2 → h3 (footer headings are h3, not h4)
- [ ] All `wp:image` blocks have meaningful `alt` text
- [ ] Icon-only buttons have `aria-label`
- [ ] Navigation blocks have `aria-label` if multiple navs exist on the page
