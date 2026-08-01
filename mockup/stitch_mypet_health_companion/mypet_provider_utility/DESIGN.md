---
name: MyPet Provider Utility
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
  secondary: '#1b6d24'
  on-secondary: '#ffffff'
  secondary-container: '#a0f399'
  on-secondary-container: '#217128'
  tertiary: '#005faf'
  on-tertiary: '#ffffff'
  tertiary-container: '#519dfb'
  on-tertiary-container: '#003363'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#94f990'
  primary-fixed-dim: '#78dc77'
  on-primary-fixed: '#002204'
  on-primary-fixed-variant: '#005313'
  secondary-fixed: '#a3f69c'
  secondary-fixed-dim: '#88d982'
  on-secondary-fixed: '#002204'
  on-secondary-fixed-variant: '#005312'
  tertiary-fixed: '#d4e3ff'
  tertiary-fixed-dim: '#a5c8ff'
  on-tertiary-fixed: '#001c3a'
  on-tertiary-fixed-variant: '#004786'
  background: '#f9f9f9'
  on-background: '#1a1c1c'
  surface-variant: '#e2e2e2'
typography:
  headline-lg:
    fontFamily: Work Sans
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Work Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Work Sans
    fontSize: 20px
    fontWeight: '500'
    lineHeight: 28px
  body-lg:
    fontFamily: Work Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Work Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.05em
  label-sm:
    fontFamily: JetBrains Mono
    fontSize: 10px
    fontWeight: '500'
    lineHeight: 14px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  gutter: 16px
  margin: 24px
  container-max: 1440px
---

## Brand & Style
The design system is engineered for utility, efficiency, and clarity, specifically tailored for service providers and tradespeople. It pivots from the consumer-facing playfulness of the brand toward a high-performance workspace that prioritizes workflow over decoration.

The personality is **dependable, efficient, and transparent**. It utilizes a **Modern Corporate** style with a focus on functional minimalism. The interface should feel like a high-quality tool: sturdy, responsive, and easy to navigate under pressure. Whitespace is used moderately to ensure high information density without clutter, allowing professionals to manage appointments and records at a glance.

## Colors
The palette is rooted in a functional neutral base to reduce eye strain during prolonged use. 

- **Primary (#4CAF50):** Used for "Success" states and high-priority action buttons (e.g., "Complete Job," "Confirm Appointment"). 
- **Secondary (#2E7D32):** A deeper green used for hover states and active navigation markers to ensure sufficient contrast.
- **Tertiary (#1976D2):** A professional blue reserved for secondary actions, information links, and "In Progress" status indicators.
- **Neutral:** A range of cool grays. Backgrounds use `#F5F5F5` to separate the canvas from the white `#FFFFFF` surface cards. Text uses `#212121` for maximum legibility.

## Typography
This design system utilizes **Work Sans** for its exceptional legibility and professional, grounded character. It feels authoritative yet approachable. 

For technical data—such as timestamps, ID numbers, and currency—**JetBrains Mono** is used as the label font. This monospaced choice assists in rapid data scanning and emphasizes the "utility" nature of the provider platform. 

Hierarchy is established through weight rather than dramatic size shifts to keep the interface compact and data-rich.

## Layout & Spacing
The layout follows a **12-column fluid grid** with a maximum container width of 1440px for desktop. 

- **Grid:** 16px gutters provide enough breathing room between functional modules while maintaining a tight, efficient feel.
- **Rhythm:** All spacing is based on a 4px baseline grid. 
- **Logic:** Padding within cards is consistently 20px (5 units) to balance information density with touch/click targets. 
- **Sidebar:** A fixed 240px left-hand navigation is standard for desktop, providing persistent access to core workflows (Schedule, Clients, Invoicing).

## Elevation & Depth
To maintain a "practical" feel, the design system avoids heavy shadows and floating elements. 

- **Tonal Layers:** Depth is primarily communicated through color. The base background is light gray, while active workspace "cards" are white. 
- **Outlines:** Low-contrast 1px borders (`#E0E0E0`) are used to define boundaries for inputs and containers.
- **Subtle Shadows:** A single level of elevation is used for interactive cards upon hover: `0px 4px 12px rgba(0, 0, 0, 0.05)`. This provides a tactile "lift" without appearing overly decorative or "soft."

## Shapes
A **Rounded (0.5rem)** logic is applied to the design system. This strikes a balance between the precision of sharp corners and the friendliness of the consumer brand.

- **Standard Elements:** Buttons, input fields, and small modules use 8px (0.5rem) corner radii.
- **Large Containers:** Main content cards and modals use 16px (1rem) radii to feel distinct and approachable.
- **Status Tags:** Use a fully rounded pill shape to distinguish them from interactive buttons.

## Components

- **Buttons:** Primary buttons use a solid #4CAF50 fill with white text. Secondary buttons use a 1px border of the same color. For utility actions (e.g., "Edit"), use a neutral gray border button to avoid visual competition with primary workflows.
- **Cards:** Rounded cards are the primary vessel for data. They feature a white background and a 1px #E0E0E0 border. Headers within cards should have a subtle gray bottom border to separate titles from content.
- **Input Fields:** Form fields are rectangular with 8px rounded corners. The border thickens to 2px and turns Primary Green on focus. Labels use `body-md` bold for clarity.
- **Data Tables:** High-density tables are essential. Rows should use alternating zebra-striping or a clear 1px divider. Hover states on rows should highlight the entire row in a very light green (`#F1F8E9`).
- **Status Chips:** Use a pill shape with a 10% opacity background of the status color (e.g., light green for "Active", light orange for "Pending") and dark text in the corresponding color for high legibility.
- **Activity Feed:** A vertical list component with small icons (using the primary green) to track pet history and service updates, ensuring providers have a chronological view of all interactions.