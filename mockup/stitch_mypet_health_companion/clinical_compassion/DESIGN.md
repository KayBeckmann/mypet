---
name: Clinical Compassion
colors:
  surface: '#f9f9f9'
  surface-dim: '#dadada'
  surface-bright: '#f9f9f9'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f3f3'
  surface-container: '#eeeeee'
  surface-container-high: '#e8e8e8'
  surface-container-highest: '#e2e2e2'
  on-surface: '#1a1c1c'
  on-surface-variant: '#3f4a3c'
  inverse-surface: '#2f3131'
  inverse-on-surface: '#f1f1f1'
  outline: '#6f7a6b'
  outline-variant: '#becab9'
  surface-tint: '#006e1c'
  primary: '#006e1c'
  on-primary: '#ffffff'
  primary-container: '#4caf50'
  on-primary-container: '#003c0b'
  inverse-primary: '#78dc77'
  secondary: '#546067'
  on-secondary: '#ffffff'
  secondary-container: '#d7e4ec'
  on-secondary-container: '#5a666d'
  tertiary: '#556158'
  on-tertiary: '#ffffff'
  tertiary-container: '#929e94'
  on-tertiary-container: '#2a352d'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#94f990'
  primary-fixed-dim: '#78dc77'
  on-primary-fixed: '#002204'
  on-primary-fixed-variant: '#005313'
  secondary-fixed: '#d7e4ec'
  secondary-fixed-dim: '#bbc8d0'
  on-secondary-fixed: '#111d23'
  on-secondary-fixed-variant: '#3c494f'
  tertiary-fixed: '#d9e6da'
  tertiary-fixed-dim: '#bdcabe'
  on-tertiary-fixed: '#131e17'
  on-tertiary-fixed-variant: '#3e4a41'
  background: '#f9f9f9'
  on-background: '#1a1c1c'
  surface-variant: '#e2e2e2'
typography:
  h1:
    fontFamily: Public Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  h1-mobile:
    fontFamily: Public Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  h2:
    fontFamily: Public Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  h3:
    fontFamily: Public Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Public Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Public Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Public Sans
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-bold:
    fontFamily: Public Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
  code:
    fontFamily: Public Sans
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 18px
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  unit: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 40px
  gutter: 16px
  margin: 24px
  max-width: 1440px
---

## Brand & Style

The design system balances clinical precision with an approachable, empathetic tone suitable for veterinary professionals. The aesthetic avoids the "softness" of consumer apps in favor of a structured, high-utility interface that prioritizes reliability and speed.

The visual style is **Modern Corporate** with a heavy focus on **Minimalism**. By using whitespace as a structural tool and thin, low-contrast borders instead of shadows, the interface remains calm and focused. The emotional response should be one of competence, clarity, and trust—reducing the cognitive load for clinic staff managing complex medical data and high-stress schedules.

## Colors

The palette is intentionally restrained to keep the focus on patient data.
- **Primary Green (#4CAF50):** Reserved exclusively for successful status indicators, primary "Save" or "Confirm" actions, and active medical alerts.
- **Neutral Core:** A spectrum of cool grays and crisp whites provides the foundation. Surfaces use white (#FFFFFF) for maximum legibility, while background canvases use a light gray (#F5F5F5) to define the workspace.
- **Secondary Slate:** A deep navy-gray (#263238) is used for navigation sidebars and headers to provide a professional, grounded frame.
- **Borders:** Medium-light gray (#E0E0E0) serves as the primary separator, replacing depth effects with clear structural lines.

## Typography

**Public Sans** is the sole typeface, chosen for its institutional clarity and neutral characteristics. 

- **Information Density:** Use `body-md` as the default for medical notes and patient records. 
- **Hierarchy:** Headlines use a tighter letter-spacing and heavier weights to stand out against data-heavy tables.
- **Data Labels:** Use `label-bold` for table headers and form labels to create a clear distinction between metadata and user input.
- **Alignment:** All numerical data in charts or patient weight logs should be right-aligned for quick vertical scanning.

## Layout & Spacing

This design system utilizes a **Fixed Grid** model for desktop to ensure data-heavy dashboards remain predictable and readable. 

- **Grid:** 12-column system with 16px gutters and 24px outer margins.
- **Rhythm:** An 8px baseline grid drives all vertical rhythm. Component heights are standardized (e.g., 32px for compact rows, 40px for standard inputs) to maintain a dense but organized layout.
- **Mobile Adaptation:** On mobile devices, the grid collapses to 4 columns. Spacing between card elements reduces to `sm` (8px) to maximize the amount of medical information visible on screen without scrolling.

## Elevation & Depth

This system avoids traditional drop shadows to maintain a clean, clinical feel. Depth is communicated through **Tonal Layering** and **Borders**:

- **Layer 0 (Background):** Neutral light gray (#F5F5F5).
- **Layer 1 (Cards/Content):** Pure white (#FFFFFF) with a 1px solid border (#E0E0E0).
- **Layer 2 (Modals/Overlays):** White with a slightly darker 1px border and a very subtle, tight 4px blur shadow (opacity 0.05) only to separate the element from the background.
- **Interactive States:** Instead of raising an element on hover, use a subtle background color shift (e.g., White to #F9F9F9) and a 1px primary-colored border stroke.

## Shapes

To convey precision and medical professionalism, the shape language uses **Soft (0.25rem)** roundedness. 

- **Standard Elements:** Buttons, inputs, and small cards use 4px (`rounded`) corners. 
- **Containers:** Larger sections or dashboard panels use 8px (`rounded-lg`) for a slightly softer feel that avoids a purely "brutalist" look.
- **Exceptions:** Status badges (e.g., "Checked In," "In Surgery") may use 100px pill shapes to differentiate them from interactive buttons.

## Components

- **Buttons:** Primary buttons are solid #4CAF50 with white text. Secondary buttons are white with a #E0E0E0 border and #1A1A1A text. Use a 32px height for "Compact" views and 40px for "Standard" views.
- **Input Fields:** Use a 1px #E0E0E0 border. On focus, the border changes to #4CAF50. Labels must be persistent (not floating) to ensure accessibility for busy staff.
- **Data Tables:** The core of the system. Use thin horizontal dividers only (#EEEEEE). Rows should have a subtle hover state (#F5F5F5). Use `body-sm` for secondary metadata within rows.
- **Status Chips:** High-contrast backgrounds for urgency (e.g., red for "Emergency", green for "Stable"). Text should be bold and centered.
- **Medical Cards:** Group patient data in cards with a title bar separated by a 1px horizontal line. Ensure internal padding is consistent at 16px.
- **Navigation:** A vertical sidebar on the left for desktop, using the Secondary Slate color. Icons should be simple, 20px strokes with 2px weight.