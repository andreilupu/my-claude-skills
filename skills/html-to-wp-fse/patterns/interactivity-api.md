# Pattern: WordPress Interactivity API

Use for client-side UI state in FSE themes: dark/light toggle, mobile nav, accordions, modals, carousels. This is the WordPress-native alternative to custom JS files + `render_block` injection.

**Requires WordPress 6.5+** (already within our 6.6+ target). Uses ES modules via `wp_enqueue_script_module()`.

## When to use vs custom JS

| Situation | Use |
|---|---|
| Toggle, accordion, modal — tied to DOM state | Interactivity API |
| Animation, scroll effects, third-party library integration | Custom JS |
| Simple one-liner (e.g. smooth scroll) | CSS or custom JS |

## How it works in FSE themes

FSE templates are `.html` files — no PHP. The interactive markup goes in a `wp:html` block (this is one of the valid reasons to use `wp:html`), and the store logic lives in an ES module registered via `functions.php`.

For FSE themes, you do **not** need `wp_interactivity_process_directives()` unless you need server-rendered initial state (e.g. hiding content before JS loads). For purely client-driven state like theme toggle, skip it.

---

## Example: Dark/Light Toggle

### 1. Flash prevention (still required)

The Interactivity API loads as a deferred ES module — it runs after HTML is parsed. Without a synchronous inline script, the page briefly renders in the wrong theme. This tiny script must stay in `wp_head`:

```php
// functions.php
function {prefix}_theme_init_script() {
    echo '<script>(function(){var t=localStorage.getItem("{prefix}-theme")||"light";document.documentElement.setAttribute("data-theme",t);})();</script>';
}
add_action( 'wp_head', '{prefix}_theme_init_script', 1 );
```

### 2. Register the ES module

```php
// functions.php
function {prefix}_enqueue_modules() {
    wp_enqueue_script_module(
        '@{prefix}/theme-toggle',
        get_template_directory_uri() . '/assets/js/theme-toggle.js',
        array( '@wordpress/interactivity' ),
        wp_get_theme()->get( 'Version' )
    );
}
add_action( 'wp_enqueue_scripts', '{prefix}_enqueue_modules' );
```

### 3. The store (`assets/js/theme-toggle.js`)

```javascript
import { store, getContext } from '@wordpress/interactivity';

store( '{prefix}/theme-toggle', {
    actions: {
        toggle() {
            const context = getContext();
            context.isDark = ! context.isDark;
            const theme = context.isDark ? 'dark' : 'light';
            document.documentElement.setAttribute( 'data-theme', theme );
            localStorage.setItem( '{prefix}-theme', theme );
        },
    },
    callbacks: {
        init() {
            const context = getContext();
            const saved = localStorage.getItem( '{prefix}-theme' ) || 'light';
            context.isDark = saved === 'dark';
            // data-theme already set by the inline script — no need to set it again
        },
    },
} );
```

### 4. Toggle button markup (inside `parts/header.html`, using `wp:html`)

```html
<!-- wp:html -->
<div
  data-wp-interactive="{prefix}/theme-toggle"
  data-wp-context='{"isDark": false}'
  data-wp-init="callbacks.init"
  class="theme-toggle-wrapper"
>
  <button
    class="theme-toggle-btn"
    data-wp-on--click="actions.toggle"
    aria-label="Toggle dark mode"
  >
    <span class="theme-toggle-icon" data-wp-class--hidden="context.isDark">dark_mode</span>
    <span class="theme-toggle-icon" data-wp-class--hidden="!context.isDark">light_mode</span>
  </button>
</div>
<!-- /wp:html -->
```

Note: `wp:html` is justified here — there is no native block for a custom interactive element.

### 5. CSS (add to `custom.css`)

```css
.theme-toggle-icon.hidden {
  display: none;
}
```

---

## Other use cases

**Mobile nav toggle:**
```html
<div data-wp-interactive="{prefix}/nav" data-wp-context='{"isOpen": false}'>
  <button data-wp-on--click="actions.toggle" aria-label="Toggle menu">Menu</button>
  <ul data-wp-class--is-open="context.isOpen" data-wp-bind--aria-hidden="!context.isOpen">
    <!-- nav items -->
  </ul>
</div>
```

**Accordion:**
```html
<div data-wp-interactive="{prefix}/accordion" data-wp-context='{"isOpen": false}'>
  <button data-wp-on--click="actions.toggle">Section title</button>
  <div data-wp-bind--hidden="!context.isOpen">Content</div>
</div>
```

Each interactive region gets its own `data-wp-context` so multiple instances on the page stay independent.

---

## Gotchas

- **`data-wp-ignore` is deprecated** in WP 6.9 — do not use it
- **`wp_enqueue_script_module()`** not `wp_enqueue_script()` — using the wrong function means the store never loads
- **Namespace must match** between `data-wp-interactive` in HTML and `store()` call in JS — a mismatch means directives are silently ignored
- **Flash prevention still requires an inline script** — there is no Interactivity API solution for synchronous localStorage reads before DOM paint
- **Icon visibility flash on load** — the Interactivity API loads as a deferred ES module, so `data-wp-class--hidden` directives are not applied until after first paint. Icon spans using text ligatures (Material Symbols) will briefly flash as raw text ("light_mode", "dark_mode"). Fix with CSS tied to `data-theme` on `<html>` (which is set synchronously by the flash-prevention inline script):
  ```css
  [data-theme="light"] .icon-light-mode,
  [data-theme="dark"]  .icon-dark-mode { display: none; }
  ```
  Add matching classes to the icon spans in HTML. This hides the correct icon at paint time without waiting for JS.
