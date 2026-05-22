---
name: Academic Clarity
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
  on-surface-variant: '#424750'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#737781'
  outline-variant: '#c3c6d1'
  surface-tint: '#335f99'
  primary: '#003466'
  on-primary: '#ffffff'
  primary-container: '#1a4b84'
  on-primary-container: '#93bcfc'
  inverse-primary: '#a6c8ff'
  secondary: '#006e2c'
  on-secondary: '#ffffff'
  secondary-container: '#86f898'
  on-secondary-container: '#00722f'
  tertiary: '#4a2e00'
  on-tertiary: '#ffffff'
  tertiary-container: '#694200'
  on-tertiary-container: '#fbaa27'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d5e3ff'
  primary-fixed-dim: '#a6c8ff'
  on-primary-fixed: '#001c3b'
  on-primary-fixed-variant: '#144780'
  secondary-fixed: '#89fa9b'
  secondary-fixed-dim: '#6ddd81'
  on-secondary-fixed: '#002108'
  on-secondary-fixed-variant: '#005320'
  tertiary-fixed: '#ffddb5'
  tertiary-fixed-dim: '#ffb957'
  on-tertiary-fixed: '#2a1800'
  on-tertiary-fixed-variant: '#643f00'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  headline-lg:
    fontFamily: Manrope
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Manrope
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Manrope
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 8px
  container-padding-mobile: 16px
  container-padding-desktop: 32px
  gutter: 16px
  stack-gap-sm: 8px
  stack-gap-md: 16px
  stack-gap-lg: 24px
---

## Brand & Style

The design system is centered on the concept of "Academic Clarity"—a philosophy that balances the serious nature of education with the supportive warmth required for parental engagement. The target audience consists of busy parents who need to digest complex student data quickly and reliably.

The aesthetic follows a **Corporate / Modern** approach with **Minimalist** influences. It avoids unnecessary ornamentation to reduce cognitive load, instead relying on high-quality typography and a structured information hierarchy. The emotional response should be one of "controlled calm"—the parent feels that their child's education is organized, transparent, and within reach. The interface mimics the responsiveness and tactile feedback of a premium native mobile application.

## Colors

The palette is anchored by **Academic Blue**, a deep, trustworthy primary shade that evokes stability and institutional authority. 

- **Primary (Academic Blue):** Used for navigation, primary actions, and branding.
- **Secondary (Attendance Green):** Reserved specifically for positive status indicators, attendance records, and "on-track" notifications.
- **Tertiary (Progress Amber):** Used for grades, pending items, or areas requiring parent attention without immediate urgency.
- **Neutral (Slate):** A cool-toned grey used for body text and secondary UI elements to maintain a professional, modern feel.

Backgrounds should remain primarily white or very light grey (#F8FAFC) to ensure a clean "paper-like" digital environment.

## Typography

This design system utilizes a dual-font strategy to maximize legibility and professional character. **Manrope** is used for headlines to provide a modern, slightly geometric personality that feels friendly yet structured. **Inter** is utilized for all functional text, body copy, and data points due to its exceptional readability and systematic feel.

Hierarchy is strictly enforced through weight and color contrast. Labels use an uppercase treatment with slight letter spacing to differentiate metadata from actionable body text. Mobile headlines are scaled down to prevent awkward line breaks in narrow data views.

## Layout & Spacing

The layout follows a **Fluid Grid** model with strict horizontal constraints to mirror native mobile patterns. On desktop, content is centered within a maximum width of 1200px to maintain readability.

A 8px base unit drives the spacing rhythm. Components and containers should use 16px or 24px padding to create an airy, organized feel. Vertical stacking of information cards should utilize a 16px gap to ensure distinct separation of "events" or "subjects." Mobile views utilize a single-column stack, while tablet and desktop views transition to a 12-column grid to allow for side-by-side comparisons of grades or schedules.

## Elevation & Depth

Visual hierarchy is established through **Tonal Layers** and **Ambient Shadows**. This design system avoids heavy shadows, opting instead for a "Soft Lift" effect. 

- **Level 0 (Background):** Solid white or #F8FAFC.
- **Level 1 (Cards/Containers):** White surface with a 1px border (#E2E8F0) and a very soft, diffused shadow (0px 4px 12px rgba(0, 0, 0, 0.05)).
- **Level 2 (Modals/Overlays):** White surface with a more pronounced shadow (0px 10px 25px rgba(0, 0, 0, 0.1)) to indicate focus.

Interactive elements use subtle hover states—decreasing the shadow blur or slightly darkening the background—to provide tactile feedback without breaking the clean aesthetic.

## Shapes

The shape language is defined by **Rounded** geometry to evoke friendliness and approachability. The standard radius for primary containers and cards is 12px-16px (`rounded-lg` or `rounded-xl`). 

Buttons and input fields follow a consistent 8px (`rounded-md`) radius to maintain a professional "software" feel, while "Chips" and "Status Badges" use a fully rounded/pill shape to distinguish them as non-button status indicators.

## Components

- **Buttons:** Primary buttons use a solid Academic Blue fill with white text. Secondary buttons use an Academic Blue outline. All buttons should have a minimum height of 48px for mobile tap targets.
- **Cards:** The primary vehicle for information. Cards must include a clear header, 16px internal padding, and use the Level 1 elevation style.
- **Status Chips:** Small, pill-shaped indicators. Use light background tints of the categorization colors (e.g., light green background with dark green text for "Present").
- **Input Fields:** Clean, 1px bordered boxes with 12px horizontal padding. Labels should always be visible above the field, never just as placeholder text.
- **Lists:** Use "In-card" lists with subtle dividers (#F1F5F9). Each list item should have a chevron icon if it leads to a detail view.
- **Progress Indicators:** Use the Tertiary Amber for "In Progress" bars and Secondary Green for "Completed" bars to provide instant visual feedback on student tasks.