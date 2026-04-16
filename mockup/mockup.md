# Design System Strategy: The Living Ledger

## 1. Overview & Creative North Star
The design system is built upon the Creative North Star of **"The Living Ledger."** This concept marries the meticulous record-keeping of professional livestock management with the soulful, nurturing care required for domestic pets. 

To move beyond the "template" look of standard management software, this system rejects rigid, boxed-in grids in favor of **Organic Editorialism**. We utilize intentional asymmetry, significant white space, and a sophisticated layering of surfaces to create an interface that feels like a premium digital journal. By overlapping elements—such as an animal's portrait breaking the bounds of its container—we inject life and movement into data-heavy environments.

## 2. Colors & Surface Architecture
The palette is rooted in deep, restorative greens and earthy neutrals, punctuated by professional blues and high-vitality oranges.

### The "No-Line" Rule
To maintain a high-end, modern aesthetic, **1px solid borders are strictly prohibited for sectioning.** Boundaries must be defined through background color shifts. For example, a `surface-container-low` section should sit directly on a `surface` background to define its territory.

### Surface Hierarchy & Nesting
The UI is treated as a series of physical layers, similar to stacked sheets of fine, heavy-weight paper.
*   **Base:** `surface` (#f9faf4) – The wide-open canvas.
*   **Structural Sections:** `surface-container-low` (#f3f4ee) – Used for grouping large content blocks.
*   **Interactive Cards:** `surface-container-lowest` (#ffffff) – Reserved for the most interactive elements (e.g., individual animal cards) to provide a "lifted" appearance.
*   **Utility Panels:** `surface-container-high` (#e7e9e3) – For sidebars or contextual tools.

### The "Glass & Gradient" Rule
Floating elements (modals, dropdowns, or "Quick Action" menus) should utilize **Glassmorphism**. Use a semi-transparent version of `surface` with a `backdrop-filter: blur(20px)`. 

For primary CTAs and hero headers, use a **Signature Texture**: a subtle linear gradient from `primary` (#204e2b) to `primary-container` (#386641) at a 135-degree angle. This adds "soul" and depth that flat color cannot replicate.

## 3. Typography: Editorial Authority
We use **Manrope** across all levels to provide a clean, modern, yet approachable character.

*   **Display (lg, md, sm):** Used for "Big Picture" stats or hero greetings. These should be set with tight letter-spacing (-0.02em) to feel authoritative.
*   **Headlines & Titles:** Used for animal names and section headers. High contrast between a `headline-lg` and a `body-sm` metadata label creates an editorial feel.
*   **Body (lg, md, sm):** Optimized for readability in medical logs and feeding schedules. Ensure line heights are generous (1.5x) to prevent "data fatigue."
*   **Labels:** Use `label-md` in all-caps with increased letter-spacing (+0.05em) when used for categories or status tags.

## 4. Elevation & Depth
Depth is achieved through **Tonal Layering** rather than traditional shadows or lines.

*   **The Layering Principle:** Place a `surface-container-lowest` card on a `surface-container-low` background. The subtle 2% shift in brightness is enough for the human eye to perceive hierarchy without visual clutter.
*   **Ambient Shadows:** When an element must "float" (e.g., a critical medical alert), use a shadow with a 32px blur and 6% opacity, tinted with the `on-surface` color.
*   **The "Ghost Border" Fallback:** If a container requires a boundary for accessibility (e.g., a search input), use a **Ghost Border**: the `outline-variant` (#c1c9be) token at **15% opacity**. Never use 100% opaque borders.

## 5. Components

### Animal Cards
*   **Style:** No borders. Background: `surface-container-lowest`. 
*   **Radius:** `xl` (1.5rem) for a friendly, approachable feel.
*   **Visuals:** The animal’s image should be "uncontained"—either circular or a custom organic shape—slightly overlapping the top-left edge of the card.

### Medical Lists & Feeding Plans
*   **Style:** Forbid the use of divider lines. 
*   **Separation:** Use vertical white space (`1.5rem`) and alternating background tints (`surface` vs `surface-container-low`) to distinguish entries. 
*   **Indicators:** Use `secondary` (Blue) for medical records and `tertiary` (Orange) for nutritional actions.

### Pedigree (Stammbaum) Structures
*   **Nodes:** Small `surface-container-lowest` cards with `md` (0.75rem) corners.
*   **Connectors:** Use "Ghost Border" lines (15% opacity `outline-variant`) with a `2px` thickness to keep the tree airy and readable.

### Inputs & Forms
*   **Fields:** Background should be `surface-container-high` with no border. On focus, transition to a `2px` Ghost Border in `primary`.
*   **Buttons:** 
    *   **Primary:** `primary` background with `on-primary` text. `full` roundedness (capsule shape).
    *   **Secondary:** `secondary-container` background. No border.
    *   **Tertiary:** Ghost border with `primary` text.

### Pedigree Tree & Genealogical Nodes
*   Instead of hard lines, use organic, curved paths to connect parents to offspring. This reinforces the "Natural/Organic" theme of the system.

## 6. Do's and Don'ts

### Do
*   **Do** use asymmetrical layouts (e.g., a large image on the left with staggered text blocks on the right).
*   **Do** use the `tertiary` (Orange) color sparingly for urgent health alerts or "Needs Action" items.
*   **Do** prioritize "Breathing Room." If a layout feels crowded, increase the padding by one step on the spacing scale.

### Don't
*   **Don't** use 1px solid dividers. If you need to separate content, use a `surface-variant` background or white space.
*   **Don't** use pure black for text. Always use `on-surface` (#191c19) to maintain a soft, premium contrast.
*   **Don't** use "Default" shadows. If an element doesn't look like it's lifting off the page naturally, refine the blur and reduce opacity.
