# Theme Scaffolding Templates

Starter templates for generating WordPress FSE theme files. Fill in `{placeholders}` from the conversion plan.

## style.css Template

```css
/*
Theme Name: {theme-name}
Theme URI: {theme-uri}
Author: {author}
Description: {description}
Version: 1.0.0
Requires at least: 6.6
Tested up to: 6.9
Requires PHP: 8.0
Text Domain: {text-domain}
*/
```

## theme.json Template

Skeleton structure — populate each section from the conversion plan. One example entry per section shows the expected format.

**Version 3 targets WordPress 6.6+.** New in v3 vs v2:
- Button hover/focus states can be styled directly in `styles.blocks.core/button.:hover` — no custom CSS needed
- Form elements (`input`, `select`) styleable via `styles.elements`
- Border radius presets via `settings.border.radiusSizes`

```json
{
  "$schema": "https://schemas.wp.org/wp/6.9/theme.json",
  "version": 3,
  "settings": {
    "appearanceTools": true,
    "color": {
      "defaultPalette": false,
      "palette": [
        {
          "slug": "primary",
          "color": "{primary-color}",
          "name": "Primary"
        }
        // populate remaining colors from conversion plan
      ]
    },
    "typography": {
      "fontFamilies": [
        {
          "fontFamily": "{font-stack}",
          "name": "{font-name}",
          "slug": "{font-slug}"
        }
        // populate from design fonts
      ],
      "fontSizes": [
        {
          "slug": "small",
          "size": "0.875rem",
          "name": "Small"
        }
        // populate size scale from design
      ]
    },
    "layout": {
      "contentSize": "{content-max-width}",
      "wideSize": "{wide-max-width}"
    },
    "spacing": {
      "units": ["px", "em", "rem", "%", "vh", "vw"]
    }
  },
  "styles": {
    "typography": {
      "fontFamily": "var(--wp--preset--font-family--{font-slug})",
      "fontSize": "var(--wp--preset--font-size--medium)",
      "lineHeight": "1.6"
    },
    "elements": {
      "link": {
        "color": {
          "text": "inherit"
        },
        ":hover": {
          "color": {
            "text": "var(--wp--preset--color--primary)"
          }
        }
      }
    }
  },
  "templateParts": [
    {
      "name": "header",
      "title": "Header",
      "area": "header"
    },
    {
      "name": "footer",
      "title": "Footer",
      "area": "footer"
    }
    // add additional template parts as needed
  ]
}
```

## functions.php Template

```php
<?php

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

function {prefix}_setup() {
	add_theme_support( 'wp-block-template-part' );
}
add_action( 'after_setup_theme', '{prefix}_setup' );

// Frontend assets
function {prefix}_enqueue_assets() {
	// Google Fonts (if needed) — use null version to avoid ?ver= param
	// wp_enqueue_style( '{prefix}-google-fonts', 'https://fonts.googleapis.com/...', array(), null );

	// Custom CSS
	wp_enqueue_style(
		'{prefix}-custom',
		get_template_directory_uri() . '/assets/css/custom.css',
		array(),
		wp_get_theme()->get( 'Version' )
	);

	// Theme toggle JS (only if dark/light toggle is needed)
	// wp_enqueue_script(
	// 	'{prefix}-theme-toggle',
	// 	get_template_directory_uri() . '/assets/js/theme-toggle.js',
	// 	array(),
	// 	wp_get_theme()->get( 'Version' ),
	// 	true
	// );
}
add_action( 'wp_enqueue_scripts', '{prefix}_enqueue_assets' );

// Editor assets — load same styles for preview consistency
function {prefix}_block_assets() {
	if ( ! is_admin() ) {
		return;
	}

	// Google Fonts (same as frontend, if needed)
	// wp_enqueue_style( '{prefix}-google-fonts-editor', 'https://fonts.googleapis.com/...', array(), null );

	wp_enqueue_style(
		'{prefix}-custom-editor',
		get_template_directory_uri() . '/assets/css/custom.css',
		array(),
		wp_get_theme()->get( 'Version' )
	);
}
add_action( 'enqueue_block_assets', '{prefix}_block_assets' );

// render_block filters for dynamic elements (uncomment and adapt as needed)
// See block-rules.md "render_block Filter Pattern" for the full pattern
```

## CSS Architecture Template

```css
/* ==========================================================================
   {Theme Name} - Custom Styles
   ========================================================================== */

/* --- CSS Custom Properties --- */
:root,
html[data-theme="light"] {
	/* Colors — populate from design palette */
	--{prefix}-bg: #ffffff;
	--{prefix}-surface: #f8fafc;
	--{prefix}-text: #0f172a;
	--{prefix}-text-secondary: #475569;
	--{prefix}-heading: #0f172a;
	--{prefix}-border: #e2e8f0;
	--{prefix}-primary: {primary-color};
	--{prefix}-primary-dark: {primary-dark-color};

	/* Glass effect (for sticky header) */
	--{prefix}-glass-bg: rgba(255, 255, 255, 0.8);
	--{prefix}-glass-border: rgba(0, 0, 0, 0.05);

	/* Populate remaining variables from design */
}

/* Dark theme — only if dark/light toggle is needed */
html[data-theme="dark"] {
	/* Override color variables only — structure stays the same */
	--{prefix}-bg: #0a0a0c;
	--{prefix}-surface: #16161a;
	--{prefix}-text: #f8fafc;
	--{prefix}-text-secondary: #94a3b8;
	--{prefix}-heading: #f8fafc;
	--{prefix}-border: #2d2d35;

	/* Populate remaining dark overrides */
}

/* --- Global Transitions (for theme toggle) --- */
*,
*::before,
*::after {
	transition: background-color 0.3s ease, color 0.3s ease, border-color 0.3s ease;
}

/* --- Global --- */
body {
	background-color: var(--{prefix}-bg);
	color: var(--{prefix}-text);
}

/* --- Header --- */
/* --- Footer --- */
/* --- Page Sections --- */
/* --- WordPress Block Overrides --- */

/* --- Responsive --- */
@media (min-width: 768px) {
	/* Tablet breakpoint */
}

@media (min-width: 1024px) {
	/* Desktop breakpoint */
}
```

## Theme Toggle JS Template

Only include this file when the design has dark/light variants or the user requests a toggle.

```javascript
(function () {
	// 1. Apply saved theme immediately (before DOM ready) to prevent flash
	var html = document.documentElement;
	var storageKey = '{prefix}-theme';
	var saved = localStorage.getItem( storageKey ) || 'light';
	html.setAttribute( 'data-theme', saved );

	// 2. Set up toggle button after DOM is ready
	document.addEventListener( 'DOMContentLoaded', function () {
		var toggleBtn = document.querySelector( '.theme-toggle-btn' );
		var icon = document.querySelector( '.theme-toggle-icon' );

		// Set initial icon state
		if ( icon ) {
			icon.textContent = saved === 'dark' ? 'light_mode' : 'dark_mode';
		}

		// Toggle on click
		if ( toggleBtn ) {
			toggleBtn.addEventListener( 'click', function () {
				var current = html.getAttribute( 'data-theme' );
				var next = current === 'dark' ? 'light' : 'dark';
				html.setAttribute( 'data-theme', next );
				localStorage.setItem( storageKey, next );
				if ( icon ) {
					icon.textContent = next === 'dark' ? 'light_mode' : 'dark_mode';
				}
			});
		}
	});
})();
```

The toggle button HTML is injected via `render_block` filter in functions.php (see block-rules.md for the pattern), not hardcoded in templates.
