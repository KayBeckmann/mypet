---
name: Warm Care Narrative
colors:
  surface: '#f8faf8'
  surface-dim: '#d8dad9'
  surface-bright: '#f8faf8'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f4f2'
  surface-container: '#eceeec'
  surface-container-high: '#e6e9e7'
  surface-container-highest: '#e1e3e1'
  on-surface: '#191c1b'
  on-surface-variant: '#3f4a3c'
  inverse-surface: '#2e3130'
  inverse-on-surface: '#eff1ef'
  outline: '#6f7a6b'
  outline-variant: '#becab9'
  surface-tint: '#006e1c'
  primary: '#006e1c'
  on-primary: '#ffffff'
  primary-container: '#4caf50'
  on-primary-container: '#003c0b'
  inverse-primary: '#78dc77'
  secondary: '#835500'
  on-secondary: '#ffffff'
  secondary-container: '#feb64c'
  on-secondary-container: '#704800'
  tertiary: '#b81d27'
  on-tertiary: '#ffffff'
  tertiary-container: '#ff6b67'
  on-tertiary-container: '#6d000d'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#94f990'
  primary-fixed-dim: '#78dc77'
  on-primary-fixed: '#002204'
  on-primary-fixed-variant: '#005313'
  secondary-fixed: '#ffddb4'
  secondary-fixed-dim: '#ffb954'
  on-secondary-fixed: '#291800'
  on-secondary-fixed-variant: '#633f00'
  tertiary-fixed: '#ffdad7'
  tertiary-fixed-dim: '#ffb3ae'
  on-tertiary-fixed: '#410004'
  on-tertiary-fixed-variant: '#930015'
  background: '#f8faf8'
  on-background: '#191c1b'
  surface-variant: '#e1e3e1'
typography:
  display:
    fontFamily: Public Sans
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Public Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Public Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  headline-md:
    fontFamily: Public Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Public Sans
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Public Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: Public Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Public Sans
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  container-padding-mobile: 20px
  container-padding-desktop: 40px
  gutter: 16px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 32px
---

## Brand & Style

The design system is built on a foundation of empathy and reliability. It avoids the cold, sterile aesthetic of traditional medical software in favor of a "nurturing companion" vibe. The style is a blend of **Modern Minimalism** and **Tactile Softness**, utilizing large surface areas, gentle shadows, and an abundance of negative space to ensure the interface feels calm and manageable for pet owners.

The target audience consists of pet parents who view their animals as family members. The UI must evoke a sense of safety and warmth, mirroring the emotional bond between a pet and its owner. This is achieved through organic shapes, a grounded color palette, and clear, jargon-free communication.

## Colors

The palette is anchored by a "Warm Green" that symbolizes vitality and growth. It is supported by soft, warm neutrals to keep the interface feeling light and airy.

- **Primary (#4CAF50):** Used for main actions, progress indicators, and health-positive states.
- **Secondary (#FFB74D):** A soft amber used for non-critical alerts, "reminders," and playful diary-entry highlights.
- **Tertiary (#FF5252):** Reserved for urgent health alerts, missed medications, or delete actions.
- **Surface/Background (#F7F9F7):** A slightly tinted off-white to reduce eye strain and provide a more organic feel than pure white.
- **Text (Neutral-900):** A deep charcoal (#2D3436) for high legibility without the harshness of pure black.

## Typography

The design system utilizes **Public Sans** for its exceptional clarity and friendly, institutional-yet-approachable character. It provides a sense of "official care" that builds trust while remaining soft enough for a lifestyle app.

- **Headlines:** Use tight letter spacing and bold weights to create a strong visual hierarchy for pet names and health categories.
- **Body Text:** Generous line heights are maintained to ensure pet health records and instructions are easy to read during stressful moments.
- **Labels:** Used for metadata (e.g., "Weight," "Last Vaccination") with slightly increased tracking for quick scanning.

## Layout & Spacing

The layout follows a **Fluid Grid** model with a focus on vertical "stacks" that mimic a diary or medical chart. 

- **Mobile:** A single-column layout with 20px side margins. Elements are grouped in high-contrast cards to separate different pets or health events.
- **Desktop:** A max-width container of 1200px. A 12-column grid is used, typically with a 3-column sidebar for navigation and a 9-column main content area for health data.
- **Rhythm:** An 8px base grid is used for all spatial relationships. Card internal padding should be generous (min 24px) to maintain the "airy" brand promise.

## Elevation & Depth

To maintain the approachable and non-clinical feel, the design system avoids harsh borders. Instead, it uses **Ambient Shadows** and **Tonal Layers** to define hierarchy.

- **Level 0 (Background):** The neutral surface color (#F7F9F7).
- **Level 1 (Cards/Surface):** Pure white (#FFFFFF) with a very soft, diffused shadow (0px 4px 20px rgba(0, 0, 0, 0.04)). This is the primary container for all content.
- **Level 2 (Interactive/Floating):** Used for FABs (Floating Action Buttons) or active modals. These feature a slightly deeper shadow (0px 8px 30px rgba(0, 0, 0, 0.08)) to suggest they are closer to the user.
- **Active State:** When pressed, elements should subtly "sink" (reduce shadow and scale slightly) to provide tactile feedback.

## Shapes

The shape language is "Extra-Soft." Sharp corners are strictly avoided as they feel aggressive and clinical.

- **Small Components (Badges, Tags):** Use `rounded-md` (8px).
- **Medium Components (Buttons, Input Fields):** Use `rounded-lg` (12px) to provide a friendly, touchable surface.
- **Large Components (Cards, Modals):** Use `rounded-xl` (16px to 24px) to create the signature "soft-box" appearance of the app.
- **Avatars:** Pet photos should always be housed in a circular frame or a highly rounded "squircle."

## Components

- **Buttons:** Primary buttons use the Warm Green with white text and 12px rounded corners. They should feel substantial, with a vertical height of at least 48px to be "thumb-friendly."
- **Cards:** The most frequent component. Cards must have white backgrounds, 16px+ corner radius, and subtle ambient shadows. Headers within cards should use `label-md` for categorization.
- **Chips/Badges:** Used for pet traits (e.g., "Neutered," "High Energy"). These use a low-opacity version of the primary color (Green 10%) with darker green text.
- **Input Fields:** Use a subtle 1px border (#E0E0E0) that changes to the Primary Green on focus. The background of the input should be slightly grey to differentiate from the card surface.
- **Pet Status Indicator:** A unique component consisting of a pulsing dot and a label (e.g., "Feeling Great") to give users immediate emotional reassurance.
- **Health Timeline:** A vertical line component with "soft-point" nodes to track medical history, using Secondary and Tertiary colors for highlights.