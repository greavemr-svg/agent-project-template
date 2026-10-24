# UX design: <title>

- Run: `<run-id>`
- Spec: `docs/specs/<run-id>.md`
- Design source: Figma | exports in docs/ux/figma/ | designed here
- Figma file: <link, or "none">

## 1. User flows
### F1: <task name> (AC1, AC2)
1. …
2. …

## 2. Screen inventory
| ID | Screen | Purpose | Source (Figma frame / export / designed here) | ACs |
|---|---|---|---|---|
| S1 | … | … | … | AC1 |

### S1: <screen name>
- Content and components: …
- Primary action: …
- Copy: heading "…", button "…"
- States:
  - Loading: …
  - Empty: …
  - Error: … ("added by UX, not in Figma" where applicable)
  - Offline: …
  - Permission denied: …

## 3. Accessibility
- Touch targets ≥ 48dp; contrast ≥ 4.5:1 (3:1 large text); text scales to 200%.
- Content descriptions: …
- Focus order: …

## 4. Design system
| Token | Value | Source |
|---|---|---|
| color.primary | #… | Figma variable / estimated |
| type.body | 16sp / 24sp | … |
| space.m | 16dp | … |

## 5. Privacy and security touchpoints
| Screen | What happens | What the user is told |
|---|---|---|
| S2 | Location permission request | "…" |

## 6. Figma discrepancies
| # | Figma says | Spec says | Needs decision from |
|---|---|---|---|
| 1 | … | … | Owner |

## 7. Traceability
| AC | Flow | Screens |
|---|---|---|
| AC1 | F1 | S1, S2 |
