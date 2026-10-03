# P2.7 STALE STATE SEMANTICS

When an upstream node changes, prior derived states are marked `superseded` rather than erased. Historical queries (`getAsOf(timestamp)`) continue to retrieve prior valid states as of that point in time.
