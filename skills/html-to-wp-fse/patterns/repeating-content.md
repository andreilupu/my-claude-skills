# Pattern: Repeating Content Sections → WordPress Posts

Use this pattern when the HTML design contains a section with repeating cards of the same structure (e.g. "Case Studies", "Team Members", "Portfolio", "Testimonials"). Do not hardcode these as static columns — convert them to real WordPress posts displayed dynamically.

## How to detect

A repeating content section has:
- A section heading (e.g. "Case Studies")
- 2+ cards with identical structure (image + title + description/meta)
- Often inside `wp:columns` / `wp:column` blocks in the HTML

## The pattern

1. Create a **category** for the section
2. Create **posts** with the card content (title, body, featured image)
3. **Replace the hardcoded columns** in the template with `wp:query` filtered by that category

## Template replacement

**Before (hardcoded — avoid this):**
```html
<!-- wp:columns -->
<div class="wp-block-columns">
  <!-- wp:column {"className":"portfolio-card"} -->
  <div class="wp-block-column portfolio-card">
    <!-- wp:image ... /-->
    <!-- wp:heading ... /-->
    <!-- wp:paragraph ... /-->
  </div>
  <!-- /wp:column -->
</div>
<!-- /wp:columns -->
```

**After (dynamic — use this):**
```html
<!-- wp:query {"queryId":10,"query":{"perPage":3,"postType":"post","order":"desc","orderBy":"date","inherit":false,"taxQuery":{"category":[CATEGORY_ID]}},"className":"portfolio-query","layout":{"type":"constrained"}} -->
<div class="wp-block-query portfolio-query">
  <!-- wp:post-template {"layout":{"type":"grid","columnCount":3},"style":{"spacing":{"blockGap":"2rem"}}} -->
    <!-- wp:group {"className":"portfolio-card"} -->
    <div class="wp-block-group portfolio-card">
      <!-- wp:post-featured-image {"isLink":true,"style":{"border":{"radius":"12px"}},"className":"portfolio-card-image"} /-->
      <!-- wp:post-title {"level":3,"isLink":true,"className":"portfolio-card-title"} /-->
      <!-- wp:post-excerpt {"className":"portfolio-card-meta"} /-->
    </div>
    <!-- /wp:group -->
  <!-- /wp:post-template -->
</div>
<!-- /wp:query -->
```

**CRITICAL:** always set `"inherit":false` — without it the query block ignores all filters and shows the page's main query instead.

## wp:query vs wp:latest-posts

| Scenario | Block | Why |
|---|---|---|
| Need custom card layout per post | `wp:query` | Full control over inner blocks and HTML structure |
| Need pagination | `wp:query` | `wp:latest-posts` doesn't support it |
| Simple list, minimal customization | `wp:latest-posts` | Self-closing, less markup |

## CSS for the dynamic grid

The original card styles generally still work since you're using the same `className` values. You may need to adjust selectors:

```css
/* wp:query renders as .wp-block-query, post-template as ul.wp-block-post-template */
.portfolio-query .wp-block-post-template {
  list-style: none;
  padding: 0;
}

.portfolio-query .portfolio-card {
  /* matches the wp:group className inside wp:post-template */
}
```

## Seeding content

See `patterns/rest-api-deployment.md` for seed scripts (both WP-CLI and REST API versions).

## Known gotchas

- **Category IDs differ per environment** — local ID `2` will not match production ID. Always query the live ID after seeding and push the updated template. See `patterns/rest-api-deployment.md § Category ID drift`.
- **`wp:latest-posts` categories** — requires numeric IDs, not slugs: `"categories":[{"id":ID}]`
- **`wp:query` taxQuery** — also requires numeric IDs: `"taxQuery":{"category":[ID]}`
