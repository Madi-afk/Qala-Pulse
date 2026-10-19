# QalaPulse — Lab 5 & 6 demonstration

## Two-minute presentation script

**00:00–00:20 — Design system**

“QalaPulse helps residents report local problems and follow their progress. I developed the visual design from our Lab 4 wireframes and existing Flutter application. Forest green identifies the main actions, a warm background supports readability, and amber marks issues that need attention.”

Show the color and typography board. Point out one font family: Noto Sans.

**00:20–00:35 — Components**

“Buttons, inputs, navigation, cards, icons and dialogs are reusable components. The same sizes, corner radii and spacing are used throughout. Buttons include disabled and loading states.”

Show the component specimen board and one component instance.

**00:35–01:25 — Complete user task**

Start **01 · Report a city issue** in Figma Present.

1. Home → Report an issue.
2. Choose photo → Choose from gallery.
3. Continue → Confirm location.
4. Analyse issue → wait for the suggestion.
5. Explain that “Find similar issues” is disabled until the person reviews the suggestion.
6. Tap the review confirmation → Find similar issues.
7. Explain the choice: confirm an existing problem or create a new one.
8. Create a new report → Publish report → View my report.

“The report is now published inside QalaPulse. This does not mean it was submitted to a government agency.”

**01:25–01:45 — Additional interaction**

Restart at the duplicate screen. Open the publication dialog, press Cancel, reopen it, and use the clearly labelled network-error demonstration. Show Keep as draft → Resume draft.

**01:45–02:00 — Testing and scope**

“I checked the complete flow, review gate, duplicate branch, cancellation and draft recovery. This is a prototype: camera, AI and network actions use demonstration data.”

Mention native Figma checks and human testing only after actually completing them.

## Native Figma acceptance checklist

- [ ] The plugin finishes without an error window.
- [ ] Palette, text styles, components and 20 mobile states are visible.
- [ ] Text remains editable; repeated UI elements are component instances.
- [ ] The complete main task works in Present mode.
- [ ] A disabled button cannot advance past AI review.
- [ ] Overlay → Cancel returns to the underlying screen.
- [ ] A second overlay replaces the first rather than trapping the user.
- [ ] Confirm existing issue reaches the updated confirmation state.
- [ ] Network error → saved draft / retry works.
- [ ] Map filters and bottom navigation have correct destinations.
- [ ] No text or controls overlap or fall outside their frames.
- [ ] Dissolve and Smart Animate play as described.
- [ ] Existing Lab 4 objects and flow starting points are preserved; new Lab 5–6 frames are placed to their right on the current page.
- [ ] Share access for the instructor is verified.

## User-testing worksheet — not yet conducted

Recruit three classmates. Give the same task without explaining the button sequence:

> “You notice road damage beside a pedestrian crossing. Report it, check the AI suggestion, review similar reports, and publish a new report.”

| Participant | Completed without help? | Time | Wrong taps / hesitation | Feedback | Change made |
|---|---|---|---|---|---|
| P1 | Not tested | — | — | — | — |
| P2 | Not tested | — | — | — | — |
| P3 | Not tested | — | — | — | — |

Follow-up questions:

1. Was it clear whether the report was sent to a government agency?
2. What did the AI-review checkbox mean to you?
3. Was the duplicate decision understandable?
4. Did you know what happened to the report after a connection failure?

Use anonymous participant labels. Record actual observations; do not fill this table with invented results.
