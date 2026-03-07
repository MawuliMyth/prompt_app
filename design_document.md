# Prompt App Design Document

## Product Character
Prompt is a friendly AI writing assistant for non-technical users who want better results without learning prompt engineering. The app should feel calm, visual, and guided. It should never look like a tooling dashboard.

This design system is based on the supplied reference image, not the legacy app UI.

## Core UX Principles
- Lead with one obvious next action on every screen.
- Favor large, conversational entry points over dense controls.
- Keep advanced capability visible, but never overwhelming.
- Show premium value through visible locked states instead of hiding it.
- Make editing feel focused and distraction-free.
- Treat voice input as a distinct mode, not a minor control.
- Respect native platform behavior while keeping a consistent spatial system.

## Visual Language
- Airy layouts with strong whitespace and low visual noise.
- Large conversational headings near the top of primary screens.
- Asymmetrical modular cards for hero actions.
- Floating bottom composer above a light dock-like navigation shell.
- Soft rounded surfaces instead of sharp utility panels.
- Illustration-led hero moments for voice, premium, and analytics.
- One visually dominant action per screen.

## Platform Rules
- iOS uses Cupertino navigation, back affordances, and sheet behavior where appropriate.
- Android uses Material page transitions, back affordances, and feedback behavior.
- Both platforms share layout hierarchy, spacing, card treatment, motion timing, and icon rules.

## Tokens

### Spacing
- `4, 8, 12, 16, 20, 24, 32, 40, 48`

### Radii
- Small: `12`
- Control: `18`
- Card: `26`
- Floating surfaces: `30`

### Icon Sizes
- Inline: `18`
- Standard: `20`
- Navigation: `22`
- Hero: `48-72`

### Typography
- Hero greeting: `36-44`
- Page title: `20`
- Section label: `13`
- Card title: `16-18`
- Body: `14`
- Caption: `12`

### Borders and Shadows
- Borders stay low-contrast in both themes.
- Dark mode must not use bright white borders.
- Shadows are soft, blurred, and used sparingly.
- Floating composer, hero cards, and premium CTA are the main elevated surfaces.

### Motion
- Micro state change: `180ms`
- Layout morph: `280ms`
- Route/page transition: `420ms`

## Iconography
- Use platform-native icons for shell and navigation controls.
- Use a single unified icon style for content modules.
- Do not mix heavy filled and thin outline styles in the same local group.

## Color Strategy
- Canvas stays soft and neutral.
- Feature modules use pastel accent blocks.
- The main compose/voice actions use a more vivid gradient accent.
- Dark mode uses layered charcoal surfaces with muted separators.

## Imagery
- Home uses decorative image or 3D-icon support inside feature modules.
- Voice mode uses a central orb/blob illustration.
- Premium and analytics use hero illustrations or synthetic visuals.
- First pass can use placeholders, but image slots must be part of the layout.

## Screen Patterns

### Home
- No redundant product-title header.
- Small utility row at the top.
- Large greeting.
- One large primary action card and smaller supporting cards.
- Quick feature tiles below the hero cards.
- Floating composer anchored above the navigation shell.

### Composer
- Full-screen route, never a modal.
- Small top back row.
- Usage summary at the top.
- Large prompt editing area.
- Visible categories and visible locked tones.
- Sticky primary enhance button at the bottom.

### Voice Mode
- Small top header.
- Centered listening prompt.
- Large animated orb/blob illustration.
- Supporting transcript/help text below.
- Bottom control cluster with mic as the dominant action.

### Templates
- Same chip language and spacing as home.
- Cards feel visual and browsable, not utilitarian.
- Applying a template must return focus to the composer.

### Analytics
- Full-page experience.
- Premium locked state feels aspirational, not disabled.
- Premium unlocked state includes a deliberate hero graph and secondary metric cards.

### Premium
- Gradient hero.
- Short value framing.
- Reduced comparison clutter.
- Floating or sticky primary CTA.

### Settings
- Smaller headers.
- Grouped preference cards.
- Premium block feels elevated.
- About section is simplified to product identity and version.
