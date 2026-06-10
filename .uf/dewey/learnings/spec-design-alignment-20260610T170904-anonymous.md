---
tag: spec-design-alignment
author: anonymous
category: pattern
created_at: 2026-06-10T17:09:04Z
identity: spec-design-alignment-20260610T170904-anonymous
tier: draft
---

During the fix-dewey-doctor-check change, the design document specified using errors.As to distinguish memory.UnavailableError from generic errors, but the implementation correctly simplified this since both cases produce the same "warn" status. Multiple spec reviewers (adversary, architect, guard, testing) independently flagged this design-vs-implementation inconsistency as a LOW finding. Lesson: when a design decision is simplified during implementation, update the design artifact immediately to prevent confusion. The design doc is a living document that should reflect what was actually built, not just what was planned.
