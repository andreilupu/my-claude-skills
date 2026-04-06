---
name: html-to-wp-fse
description: Use when converting HTML design exports (Stitch, Figma, etc.) into WordPress Full Site Editing block themes — handles block markup conversion, theme.json generation, and editor validation
---

# HTML to WordPress FSE Theme

Convert HTML design exports into production-ready WordPress Full Site Editing block themes. Execute the 6 phases below in order — do not skip ahead.

## Checklist

- [ ] Phase 1: Analyze Designs
- [ ] Phase 2: Plan Conversion
- [ ] Phase 3: Generate Theme Files
- [ ] Phase 4: Verify in Editor
- [ ] Phase 5: Fix Loop
- [ ] Phase 6: Finalize

## Phase 1: Analyze Designs

1. Check if the working directory already has partial theme files (theme.json, templates/, parts/). If so, ask the user whether to extend or overwrite.
2. Scan for HTML design files. Ask the user for the location if not obvious.
3. Parse each HTML file and extract:
   - **Page structure** — sections, hierarchy, semantic elements
   - **Color palette** — all unique colors (backgrounds, text, borders, accents)
   - **Typography** — font families, sizes, weights, line heights
   - **Images** — URLs, alt text, aspect ratios
   - **Navigation** — menu structure, link targets. Note whether links are internal page anchors (`#services`) or separate pages
   - **Interactive elements** — toggles, modals, animations, carousels
   - **Repeating content sections** — groups of cards with the same structure (e.g. "Case Studies", "Team Members", "Testimonials", "Blog Posts"). For each, extract: section title, number of items, per-item data (title, description, image URL, meta text, link)
4. Detect if multiple color schemes exist (e.g. light.html + dark.html).
5. Present a structured summary of findings to the user before proceeding.

## Phase 2: Plan Conversion

Present the user with a conversion plan covering:

- **Pages/templates** — which WordPress templates to create. Always plan the full set: `front-page`, `index`, `single`, `page`, `archive`, `404`. Skipping any causes WordPress to fall back to `index.html` for all content types, which breaks the site.
- **Template parts** — header, footer, sidebar, or custom reusable parts
- **Sections per page** — each section mapped to WordPress block types with proposed `className` values and `anchor` IDs for navigable sections
- **Navigation strategy** — if nav links are internal anchors (`#services`), read `patterns/anchor-navigation.md` and plan anchor IDs for all target sections. If they are separate pages, plan which pages to create.
- **Color palette** — extracted colors mapped to theme.json palette slugs and CSS custom properties
- **Typography** — fonts mapped to theme.json fontFamilies and fontSizes
- **Interactive elements** — for toggles, accordions, modals, and nav: prefer the WordPress Interactivity API (`patterns/interactivity-api.md`). Fall back to `render_block` PHP injection or `wp:html` only when the Interactivity API is insufficient (document why).
- **Repeating content sections** — which card groups should become WordPress posts. For each section, plan: category name, number of posts to seed, and which block to display them (`wp:latest-posts` or `wp:query`). See `block-rules.md` § "Repeating Content Sections → WordPress Posts" for the full pattern.
- **Dark/light toggle** — only if design provides both variants or user explicitly requests it. Use the Interactivity API pattern (`patterns/interactivity-api.md`).
- **Deployment target** — ask the user: do they have WP-CLI access, or will they deploy via REST API? This determines which seed script to generate.

**Wait for user approval before proceeding to Phase 3.**

## Phase 3: Generate Theme Files

**CRITICAL: Read `block-rules.md` before generating any template or part file.**

Generate files in this order. Each step depends on information from the previous:

1. **style.css** — theme metadata header. Use `theme-scaffolding.md` style.css template.
2. **theme.json** — version 3 config (WP 6.6+) with colors, typography, layout, spacing from the plan. Use `theme-scaffolding.md` theme.json template as skeleton.
3. **assets/css/custom.css** — all visual styling using CSS custom properties. Use `theme-scaffolding.md` CSS architecture template. Implement:
   - CSS custom properties for all colors, with `:root`/`html[data-theme="light"]` and `html[data-theme="dark"]` if applicable
   - Pseudo-elements (`::before`/`::after`) for decorative content (icons, dots, blurs)
   - Responsive breakpoints at 768px and 1024px
   - No framework classes (no Tailwind, no Bootstrap)
4. **Template parts** (`parts/*.html`) — header, footer, etc. using only native WordPress blocks. Follow `block-rules.md` syntax examples exactly.
5. **Templates** (`templates/*.html`) — always generate the full set:
   - `front-page.html` — static homepage content
   - `index.html` — blog listing fallback (wp:query loop, no static content)
   - `single.html` — individual post (wp:post-title, wp:post-content, etc.)
   - `page.html` — static pages (wp:post-title, wp:post-content)
   - `archive.html` — category/tag archives (wp:query loop with wp:query-pagination)
   - `404.html` — not found page
6. **functions.php** — asset enqueuing for frontend and editor, `render_block` filters for dynamic elements. Use `theme-scaffolding.md` functions.php template. If Interactivity API is used, register modules with `wp_enqueue_script_module()` here.
7. **assets/js/*.js** — only if interactive features are needed. For Interactivity API features, read `patterns/interactivity-api.md` for the store pattern. For dark/light toggle, use the Interactivity API store + a tiny `wp_head` inline script for flash prevention.
8. **Content seed script** — if repeating content sections were identified, generate the appropriate script based on the deployment target:
   - WP-CLI access: generate `seed-content.sh` (see `block-rules.md` § "Seed Script: WP-CLI")
   - REST API only: generate `seed-content-api.sh` (see `block-rules.md` § "Seed Script: REST API")
   - The corresponding template sections must use `wp:query` with `"inherit":false` and `"taxQuery"` filtered by category

## Phase 4: Verify in Editor

### If browser MCP is available (preferred):

1. Set up wp-env if not running, or ask user to confirm their local WordPress environment.
2. Navigate to the site editor: `wp-admin/site-editor.php?canvas=edit&p=%2Fwp_template%2F{theme-slug}%2F%2Findex`
3. Wait for the editor to fully load.
4. Check for:
   - Block validation errors (yellow warning bars, "unexpected or invalid content" messages)
   - Console errors and warnings (filter out unrelated WordPress core warnings)
   - All blocks rendering as native editor blocks (no wp:html showing raw code when a native block should have been used)
5. Take a screenshot for visual confirmation.
6. Also check the frontend for correct rendering.

### If browser MCP is unavailable (static validation fallback):

1. Parse all template/part HTML files to verify block comment syntax:
   - Every `<!-- wp:blockname -->` has a matching `<!-- /wp:blockname -->`
   - Self-closing blocks use `<!-- wp:blockname {...} /-->` syntax
2. Validate that JSON inside block comments is parseable (no trailing commas, valid keys).
3. Check structural rules:
   - Every `wp:button` is inside a `wp:buttons` container
   - Every `wp:image` has a `<figure class="wp-block-image">` wrapper
   - No plain HTML comments inside block containers
   - Navigation uses `wp:navigation` not `wp:list`
   - Every section targeted by a nav anchor has a matching `"anchor"` attribute in the block JSON
4. Ask the user to manually open the editor and report any errors.

## Phase 5: Fix Loop

If Phase 4 found errors:

1. Diagnose the root cause from the error message or console output.
2. Fix the specific file.
3. Reload the editor and re-check.
4. Repeat until clean — **maximum 5 iterations**.
5. If still failing after 5 attempts, surface the issue to the user with:
   - What was tried
   - What failed
   - Suggested next steps

Common fixes:
- Invalid block comment syntax (mismatched JSON, wrong attribute types)
- Missing or mismatched closing block comments
- `wp:html` used where a native block exists
- Class name mismatches between block markup and CSS selectors
- `str_replace` failing due to WordPress adding extra classes at render time (switch to `preg_replace`)
- Nav links pointing to `#section` but the target block missing `"anchor":"section"` in its JSON

## Phase 6: Finalize

1. Take frontend screenshots showing the rendered theme.
2. If dark/light toggle exists, screenshot both modes.
3. **Optional:** Generate a distributable zip file (excluding dev files: .wp-env.json, designs/, .playwright-mcp/, node_modules/, seed-content*.sh, .env).
4. **Optional:** Set up wp-env for local development if the user wants it.
5. Present a summary to the user:
   - Files generated
   - What to check manually (e.g. navigation menu needs to be saved in WP admin)
   - Any wp:html blocks used and why
   - If a seed script was generated:
     - WP-CLI: remind to run `bash seed-content.sh`
     - REST API: remind to fill in `.env` and run `bash seed-content-api.sh`
     - **Category ID warning:** the category ID is environment-specific. After seeding on the live site, query the live ID with `wp term get category {slug} --by=slug --field=term_id` (WP-CLI) or `GET /wp-json/wp/v2/categories?slug={slug}` (REST API), then push the updated template via `POST /wp-json/wp/v2/templates/{theme-slug}//{template-slug}`

## Success Criteria

1. Theme loads in WordPress site editor with zero block validation errors
2. All content uses native WordPress blocks (wp:html only when no native equivalent exists, with documented justification)
3. Theme is fully editable in the block editor — text, images, buttons, navigation all editable inline
4. CSS uses custom properties for all colors/spacing, enabling easy theming
5. Frontend is visually faithful to the source HTML designs
6. All anchor navigation links scroll to the correct section
7. Every content type (post, page, archive, 404) has its own template — none fall back to index.html unintentionally
8. Dark/light toggle works when applicable (CSS variable swap, localStorage persistence)
9. Editor preview matches frontend appearance (same CSS loaded in both contexts)

## Out of Scope

Do not attempt these in v1:
- WooCommerce template support
- Custom block development (PHP block registration)
- Pattern library generation
- Internationalization / translation-ready strings
- Custom post type templates
- Plugin dependencies
