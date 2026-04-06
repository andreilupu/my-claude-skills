# Block Conversion Rules

Read this file before generating any WordPress block markup. It contains the mapping rules, syntax examples, and gotchas that prevent editor validation errors.

## Iron Rules

1. **wp:html is a last resort, not a shortcut.** Only use it when there is genuinely no native block equivalent. Never use it to avoid proper block conversion. When used, document why.
2. **No plain HTML comments** inside block containers — WordPress parser treats them as invalid content between blocks.
3. **Always use `wp:navigation`** with `wp:navigation-link` children for nav menus — never wp:list for navigation.
4. **Block comment JSON must be valid** — no single quotes, no trailing commas, no unquoted keys. The JSON inside `<!-- wp:blockname {...} -->` must parse cleanly.
5. **Opening and closing block comments must match exactly** — `<!-- wp:group -->` requires `<!-- /wp:group -->`.
6. **Decorative/non-content elements belong in CSS** — use `::before`/`::after` pseudo-elements for icons, dots, blurs, badges. Not extra blocks.
7. **Dynamic elements injected via PHP** `render_block` filter — never hardcode runtime-dependent HTML in templates.
8. **WordPress adds classes at render time** — blocks get extra classes like `is-layout-flex`, `wp-container-*`, `wp-block-*-is-layout-*`. PHP string matching must use regex or `strpos`, never exact `str_replace` on class attributes.

## HTML to Block Mapping

| HTML Element | WordPress Block | Key Attributes | Notes |
|---|---|---|---|
| `<section>`, `<div>` (container) | `wp:group` | `className`, `tagName`, `layout` | Use `tagName: "main"` for main content |
| `<h1>` - `<h6>` | `wp:heading` | `level`, `textAlign`, `className` | Level must match the HTML heading number |
| `<p>` | `wp:paragraph` | `align`, `className` | `align` for text-align, not layout |
| `<img>` | `wp:image` | `sizeSlug`, `className` | Must be wrapped in `<figure>` |
| `<a>` as button | `wp:button` inside `wp:buttons` | `className`, `style.border.radius` | Never use button without buttons wrapper |
| `<nav>` with links | `wp:navigation` | `className`, `overlayMenu`, `layout` | Children are `wp:navigation-link` blocks |
| `<ul>/<li>` (content) | `wp:list` / `wp:list-item` | `className` | Only for content lists, never navigation |
| Column layouts | `wp:columns` / `wp:column` | `style.spacing.blockGap`, `verticalAlignment` | Column width via `width` attribute or `style.flexBasis` |
| Social links | `wp:social-links` / `wp:social-link` | `service`, `url` | Service values: "x", "linkedin", "facebook", etc. |
| Site title / text logo | `wp:site-title` | `level`, `isLink`, `className` | Self-closing. `level:0` renders as `<p>`. Use instead of `wp:paragraph` for logo text. |
| Site logo (image) | `wp:site-logo` | `width`, `className` | Self-closing. Use when design has an image logo. |
| `<template>` areas | `wp:template-part` | `slug`, `area` | area: "header", "footer", or "uncategorized" |
| Repeating card sections | `wp:query` or `wp:latest-posts` | `taxQuery`, `inherit:false` | See `patterns/repeating-content.md` |

## Block Syntax Examples

Exact copy-paste syntax for every common block. Follow these patterns precisely.

**wp:group (container)**
```html
<!-- wp:group {"className":"section-name","layout":{"type":"constrained","contentSize":"1200px"}} -->
<div class="wp-block-group section-name">
  <!-- inner blocks here -->
</div>
<!-- /wp:group -->
```

**wp:group with tagName (semantic HTML)**
```html
<!-- wp:group {"tagName":"main"} -->
<main class="wp-block-group">
  <!-- inner blocks here -->
</main>
<!-- /wp:group -->
```
Use `tagName` to preserve semantic elements: `main` for page content, `section` for major sections, `aside` for sidebars. Header/footer get semantics from their template-part area, not tagName.

**wp:group with flex layout (Row)**
```html
<!-- wp:group {"layout":{"type":"flex","flexWrap":"nowrap","justifyContent":"space-between"},"style":{"spacing":{"blockGap":"1.5rem"}}} -->
<div class="wp-block-group">
  <!-- inner blocks arranged horizontally -->
</div>
<!-- /wp:group -->
```

**wp:group with sticky positioning**
```html
<!-- wp:group {"className":"site-header","style":{"position":{"type":"sticky","top":"0px"}},"layout":{"type":"flex","justifyContent":"space-between","flexWrap":"nowrap"}} -->
<div class="wp-block-group site-header">
  <!-- header content -->
</div>
<!-- /wp:group -->
```

**wp:heading**
```html
<!-- wp:heading {"level":2,"textAlign":"center","className":"section-title"} -->
<h2 class="wp-block-heading has-text-align-center section-title">Heading Text</h2>
<!-- /wp:heading -->
```

**wp:paragraph**
```html
<!-- wp:paragraph {"align":"center","className":"hero-subheading"} -->
<p class="has-text-align-center hero-subheading">Paragraph text here.</p>
<!-- /wp:paragraph -->
```

**wp:image**
```html
<!-- wp:image {"sizeSlug":"full","className":"my-image-class"} -->
<figure class="wp-block-image size-full my-image-class"><img src="https://example.com/image.jpg" alt="Alt text"/></figure>
<!-- /wp:image -->
```

**wp:buttons + wp:button**
```html
<!-- wp:buttons {"layout":{"type":"flex","justifyContent":"center"}} -->
<div class="wp-block-buttons">
  <!-- wp:button {"style":{"border":{"radius":"8px"}}} -->
  <div class="wp-block-button"><a class="wp-block-button__link wp-element-button" style="border-radius:8px">Button Text</a></div>
  <!-- /wp:button -->

  <!-- wp:button {"className":"is-style-outline","style":{"border":{"radius":"8px"}}} -->
  <div class="wp-block-button is-style-outline"><a class="wp-block-button__link wp-element-button" style="border-radius:8px">Outline Button</a></div>
  <!-- /wp:button -->
</div>
<!-- /wp:buttons -->
```

**wp:navigation + wp:navigation-link**
```html
<!-- wp:navigation {"className":"main-nav","overlayMenu":"mobile","layout":{"type":"flex"},"style":{"spacing":{"blockGap":"2rem"}}} -->
  <!-- wp:navigation-link {"label":"Services","url":"/#services","kind":"custom","isTopLevelLink":true} /-->
  <!-- wp:navigation-link {"label":"About","url":"/#about","kind":"custom","isTopLevelLink":true} /-->
<!-- /wp:navigation -->
```

**wp:columns + wp:column**
```html
<!-- wp:columns {"style":{"spacing":{"blockGap":{"left":"2rem","top":"2rem"}}}} -->
<div class="wp-block-columns">
  <!-- wp:column {"className":"card-class"} -->
  <div class="wp-block-column card-class">
    <!-- inner blocks -->
  </div>
  <!-- /wp:column -->

  <!-- wp:column {"verticalAlignment":"center","width":"50%"} -->
  <div class="wp-block-column is-vertically-aligned-center" style="flex-basis:50%">
    <!-- inner blocks -->
  </div>
  <!-- /wp:column -->
</div>
<!-- /wp:columns -->
```

**wp:list + wp:list-item**
```html
<!-- wp:list {"className":"feature-list"} -->
<ul class="feature-list"><!-- wp:list-item -->
<li>List item text</li>
<!-- /wp:list-item -->

<!-- wp:list-item -->
<li>Another item</li>
<!-- /wp:list-item --></ul>
<!-- /wp:list -->
```

**wp:social-links + wp:social-link**
```html
<!-- wp:social-links {"className":"footer-social","style":{"spacing":{"blockGap":{"left":"1rem"}}}} -->
<ul class="wp-block-social-links footer-social"><!-- wp:social-link {"url":"#","service":"x"} /--><!-- wp:social-link {"url":"#","service":"linkedin"} /--></ul>
<!-- /wp:social-links -->
```

**wp:site-title (text logo)**
```html
<!-- wp:site-title {"level":0,"isLink":true,"className":"site-logo-text","style":{"typography":{"fontSize":"1.25rem","fontWeight":"700"}}} /-->
```
Self-closing block. Pulls the site name from WordPress Settings > General. `level:0` renders as `<p>`, `level:1` as `<h1>`, etc. Always use this instead of `wp:paragraph` for the site name/logo text — it integrates with WordPress identity settings and updates everywhere when changed.

**wp:site-logo (image logo)**
```html
<!-- wp:site-logo {"width":120,"className":"custom-logo"} /-->
```
Self-closing block. Uses the logo set in Appearance > Customize > Site Identity. Use when the design has an image logo.

**wp:template-part**
```html
<!-- wp:template-part {"slug":"header","area":"header"} /-->
<!-- wp:template-part {"slug":"footer","area":"footer"} /-->
```

**wp:separator**
```html
<!-- wp:separator {"className":"is-style-wide"} -->
<hr class="wp-block-separator has-alpha-channel-opacity is-style-wide"/>
<!-- /wp:separator -->
```

**wp:cover (background image/color with overlay)**
```html
<!-- wp:cover {"url":"https://example.com/bg.jpg","dimRatio":50} -->
<div class="wp-block-cover">
  <span class="wp-block-cover__background has-background-dim"></span>
  <img class="wp-block-cover__image-background" src="https://example.com/bg.jpg" alt=""/>
  <div class="wp-block-cover__inner-container">
    <!-- inner blocks -->
  </div>
</div>
<!-- /wp:cover -->
```

## Block JSON style vs CSS className

- Use block JSON `style` attribute for properties WordPress needs for editor rendering: spacing (`blockGap`, `padding`, `margin`), layout, border-radius, typography on individual blocks, position.
- Use CSS classes via `className` for visual styling: colors, backgrounds, shadows, hover effects, animations, transitions.
- When in doubt, prefer `className` + CSS — it is more maintainable and supports dark/light theming via CSS custom properties.

## CSS Custom Properties vs theme.json Palette

Two parallel color systems exist and serve different purposes:

- **theme.json palette** provides editor UI color pickers and generates `--wp--preset--color--{slug}` variables. Reflects light-mode defaults.
- **Custom CSS variables** (`--{prefix}-*`) handle all actual styling in custom.css, because they can switch between light/dark themes. theme.json variables cannot.

Define colors in both places: theme.json for editor integration, custom CSS properties for runtime theming.

## render_block Filter Pattern

For injecting dynamic HTML that should not exist in the static template:

```php
function {prefix}_inject_element( $block_content, $block ) {
    // Never inject in admin/editor — keeps templates clean
    if ( is_admin() ) {
        return $block_content;
    }

    // Target a specific block by its className attribute
    if (
        isset( $block['attrs']['className'] ) &&
        strpos( $block['attrs']['className'], 'target-class' ) !== false
    ) {
        $html = '<div class="injected-element">...</div>';

        // Use preg_replace — WordPress adds extra classes at render time
        $block_content = preg_replace(
            '/(<div class="wp-block-buttons[^"]*">)/',
            $html . '$1',
            $block_content,
            1
        );
    }

    return $block_content;
}
// Hook into the specific block type, not generic render_block
add_filter( 'render_block_core/group', '{prefix}_inject_element', 10, 2 );
```

## Known Gotchas

1. **wp:button must be inside wp:buttons** — a bare button block is invalid
2. **wp:image requires figure wrapper** — `<figure class="wp-block-image"><img .../></figure>`
3. **Sticky header** — use `"style":{"position":{"type":"sticky","top":"0px"}}` in block JSON, not CSS position
4. **Block layout types** — `constrained` (centered with max-width), `flex` (flexbox), `grid` (CSS grid). Use constrained for content sections, flex for inline arrangements.
5. **Editor CSS loading** — use `enqueue_block_assets` hook with `is_admin()` guard, not `enqueue_block_editor_assets` (which doesn't inject into the editor iframe correctly)
6. **Google Fonts** — enqueue with `null` version to prevent `?ver=` query parameter
7. **Material icons or icon fonts** — enqueue the font, use CSS `::before` content or HTML `<span>` inside blocks
8. **render_block regex** — WordPress adds classes to blocks at render time, so `str_replace('class="wp-block-buttons"', ...)` won't match `class="wp-block-buttons is-layout-flex wp-block-buttons-is-layout-flex"`. Always use `preg_replace` with flexible class matching.
9. **Site title/logo** — never use `wp:paragraph` for the site name. Use `wp:site-title` (text) or `wp:site-logo` (image). These are dynamic blocks that pull from WordPress settings and update everywhere when changed.
10. **wp:query requires `"inherit":false` for custom filters** — by default, query blocks inherit the page's main query. If you set `taxQuery`, `author`, or other filters, you MUST set `"inherit":false`, otherwise the filters are ignored.
11. **Repeating cards are not columns** — when the HTML design has 3+ cards with identical structure (image + title + text), don't convert them to `wp:columns`. Create real posts and use `wp:latest-posts` or `wp:query`. See `patterns/repeating-content.md`.
12. **Full template set required** — always generate `front-page`, `index`, `single`, `page`, `archive`, and `404`. If only `index.html` exists, WordPress uses it as the fallback for all content types.
