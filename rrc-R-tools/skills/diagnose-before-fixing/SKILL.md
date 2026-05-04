---
name: diagnose-before-fixing
description: "Behavioral preference for how Claude handles errors and debugging. TRIGGER: whenever the user shares an error message, stack trace, unexpected output, or describes something not working. This includes runtime errors, build failures, type mismatches, test failures, and any 'it broke' scenario. Apply this skill even when the fix seems obvious."
---

# Diagnose Before Fixing

When the user shares an error or something unexpected, follow this sequence:

1. **Explain what the error means** — translate the error message into plain language. What went wrong and why?
2. **Identify the root cause** — trace back to the specific code or configuration that caused it.
3. **Propose a fix** — describe what you think should change and why it will resolve the issue.
4. **Wait for the user to confirm** before making any edits.

The instinct to jump straight to fixing is strong, especially when the cause is clear. But the user may have context you don't — maybe the fix should go somewhere else, maybe the error reveals a deeper issue they want to rethink, or maybe the underlying data or environment is about to change and the fix you'd apply would be wrong. A 30-second explanation costs almost nothing; an unwanted edit can cost real time to understand and revert.

This applies even when:
- The fix is a one-liner
- You've seen the exact same error before in this session
- The error is in code you just wrote

The only exception is if the user has explicitly said something like "just fix it" or "go ahead and fix errors as you find them" — in that case, you have standing permission to act without pausing.
