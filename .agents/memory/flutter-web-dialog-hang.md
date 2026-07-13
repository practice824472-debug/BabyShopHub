---
name: Flutter Web dialog-open hang from hover-tracked buttons
description: Why showDialog() called directly from onPressed/onTap can freeze a Flutter Web app, and the fix.
---

Calling `showDialog()` synchronously inside `onPressed`/`onTap` of a hover-tracked
Material widget (`FloatingActionButton`, `InkWell`, `ElevatedButton`, etc.) on
Flutter Web can trip a mouse_tracker.dart re-entrancy assertion:
`Assertion failed ... !_debugDuringDeviceUpdate is not true`. Once it fires,
pointer/hover event dispatch can get stuck, making the whole app look frozen
until it's restarted — with no error dialog or visible crash, just an
unresponsive UI.

**Why:** the dialog swaps out the widget the mouse is currently hovering over
while Flutter's web mouse tracker is mid-update for that same pointer event —
a known Flutter engine bug (still present as of Flutter 3.32 stable/DDC debug
builds), not an app logic bug.

**How to apply:** when a button that opens a dialog seems to "hang" or "do
nothing" specifically on Flutter Web (but works fine on mobile), defer the
`showDialog()` call to the next frame instead of calling it inline in the
handler, e.g. `WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) showDialog(...); })`.
This moves dialog creation outside the pointer-event dispatch that triggers
the assertion. Apply this to every button that opens a dialog directly from
its press/tap handler, not just the one reported broken — they all share the
same risk on web.
