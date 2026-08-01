---
name: MyPet Admin System
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#3f4a3c'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#6f7a6b'
  outline-variant: '#becab9'
  surface-tint: '#006e1c'
  primary: '#006e1c'
  on-primary: '#ffffff'
  primary-container: '#4caf50'
  on-primary-container: '#003c0b'
  inverse-primary: '#78dc77'
  secondary: '#5f5e5e'
  on-secondary: '#ffffff'
  secondary-container: '#e2dfde'
  on-secondary-container: '#636262'
  tertiary: '#a63360'
  on-tertiary: '#ffffff'
  tertiary-container: '#f26f9d'
  on-tertiary-container: '#690034'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#94f990'
  primary-fixed-dim: '#78dc77'
  on-primary-fixed: '#002204'
  on-primary-fixed-variant: '#005313'
  secondary-fixed: '#e5e2e1'
  secondary-fixed-dim: '#c8c6c5'
  on-secondary-fixed: '#1c1b1b'
  on-secondary-fixed-variant: '#474746'
  tertiary-fixed: '#ffd9e2'
  tertiary-fixed-dim: '#ffb1c7'
  on-tertiary-fixed: '#3e001c'
  on-tertiary-fixed-variant: '#861948'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  display-sm:
    fontFamily: Hanken Grotesk
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.02em
  headline-sm:
    fontFamily: Hanken Grotesk
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
  data-mono:
    fontFamily: JetBrains Mono
    fontSize: 13px
    fontWeight: '450'
    lineHeight: 16px
    letterSpacing: -0.01em
  label-caps:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 12px
    letterSpacing: 0.05em
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
  xl: 32px
  container-max: 1600px
  sidebar-width: 240px
  edge-margin: 24px
---

## Brand & Style
The design system is centered on high-density utility and operational efficiency for internal administrative tasks. The brand personality is invisible, prioritizing data clarity and system trust over decorative flair. 

The aesthetic follows a **Functional Minimalist** approach. Every pixel must serve a purpose; whitespace is used strategically to separate data sets rather than as a luxury. The interface uses a systematic layout to handle complex workflows, ensuring that superadmins can process large volumes of information without cognitive overload. Visual embellishments like shadows and gradients are replaced by structural borders and tonal shifts to maintain a professional, no-nonsense environment.

## Colors
This design system utilizes a restricted palette to focus attention on critical data and system statuses.

- **Primary & Accent:** `#4CAF50` is used exclusively for primary "Save/Commit" actions and positive health indicators. It must be used sparingly to maintain its signaling power.
- **Neutrals:** A range of slate grays defines the structural hierarchy. Backgrounds use a very light tint (`#F8FAFC`) to differentiate from white surface containers (`#FFFFFF`).
- **Data States:** 
  - **Success:** `#4CAF50`
  - **Warning:** `#F59E0B`
  - **Critical:** `#EF4444`
  - **Info:** `#3B82F6`

Contrast ratios must always meet WCAG AA standards to ensure legibility during long work sessions.

## Typography
The typography strategy prioritizes horizontal space and numerical alignment. 

- **Primary Typeface:** **Inter** is the workhorse for all body copy and UI labels due to its high legibility at small sizes.
- **Headings:** **Hanken Grotesk** provides a sharp, modern professional feel for page titles and section headers.
- **Data Typeface:** **JetBrains Mono** is utilized for IDs, currency, timestamps, and table data. This ensures tabular numerals align perfectly, facilitating easier scanning of column-based data.

All typography should use "tnum" (tabular figures) OpenType features where available to keep data columns visually stable.

## Layout & Spacing
The design system employs a **Fixed-Fluid Hybrid Grid**. 

- **Sidebar:** A fixed 240px navigation bar remains docked to the left.
- **Main Content:** A fluid area with a maximum width of 1600px to prevent line lengths from becoming unreadable on ultra-wide monitors.
- **Density:** We use a 4px base unit. Component internal padding is tightened (typically 8px or 12px) to maximize the amount of information visible on-screen ("above the fold").

Spacing between distinct data modules should be 24px, while related elements within a card should use 8px or 12px increments.

## Elevation & Depth
In this design system, depth is communicated through **Tonal Layering** and **Low-Contrast Outlines** rather than shadows. 

1. **Level 0 (Background):** `#F8FAFC` – The base canvas.
2. **Level 1 (Cards/Surfaces):** `#FFFFFF` – White surfaces with a 1px solid border of `#E2E8F0`. No shadow is applied unless the element is a floating popover.
3. **Level 2 (Modals/Popovers):** `#FFFFFF` – Uses a sharp 4px or 8px shadow with 5% opacity to indicate temporary focus over the UI.

This flat hierarchy keeps the interface feeling "fast" and lightweight.

## Shapes
Shapes are disciplined and "Soft" (4px radius). 

- **Standard Elements:** Buttons, input fields, and small cards use a 4px (0.25rem) radius.
- **Large Containers:** Large dashboard panels or modals use an 8px (0.5rem) radius.
- **Data Tags:** Status chips use a 2px radius or remain square to look more like systematic labels rather than friendly buttons.

Avoid fully rounded "pill" shapes, as they consume excessive horizontal padding and conflict with the high-density data grid.

## Components
- **Data Tables:** The core of the system. Use a strict horizontal zebra striping or 1px border-bottom (`#F1F5F9`). Headers are in `label-caps` with a subtle gray background. Rows should have a hover state of `#F8FAFC`.
- **Buttons:** 
  - **Primary:** Background `#4CAF50`, white text, 4px radius. 
  - **Secondary:** White background, `#E2E8F0` border, `#1A1A1A` text.
  - **Ghost:** No background/border, used for table row actions.
- **Input Fields:** 1px `#E2E8F0` border, 4px radius. On focus, the border changes to the primary color or a darker neutral. Labels are positioned above the field in `body-sm` bold.
- **Cards:** Minimalist containers. Title at the top-left, actions at the top-right. Padding is 16px or 20px.
- **Status Chips:** Small, rectangular badges with a low-opacity background of the status color (e.g., 10% green) and a high-contrast text color.
- **Sidebar:** Dark neutral background (`#1A1A1A`) with light gray text. Active states indicated by a 2px primary color vertical bar on the left edge.