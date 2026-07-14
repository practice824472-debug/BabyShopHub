---
name: Chart color palette sizing
description: Pie/donut charts must have a distinct color per category or repeated colors look like a data bug.
---

When building a pie/donut chart (fl_chart or similar) from a dynamic list of categories, size the color palette to comfortably exceed the expected category count, not just a small fixed set (e.g. 6).

**Why:** With `colors[i % colors.length]`, once the category count exceeds the palette size, unrelated categories silently render with identical colors. A user reported this as "every category looks the same" / suspected mocked data — the underlying counts were real, but the visual made it look fake.

**How to apply:** When adding/reviewing a chart driven by a variable-length category list, check the palette array length against the actual max category count in the domain model, and prefer sorting entries by value (descending) so the legend reads meaningfully instead of arbitrary map order.
