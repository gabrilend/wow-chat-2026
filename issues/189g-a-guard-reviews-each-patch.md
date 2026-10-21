# 189g - A Guard Reviews Each Patch Before It Is First Applied

## Status
- Created: 2026-10-20
- Phase: 1 (Foundation & Tooling)
- Parent: 189
- Related: 189e (a patch is a directory, carrying files of any kind)
- State: planned; nothing built

## Origin

The owner, 2026-10-20, on how a patch carries its files (189e), verbatim:

> patches/ should be a directory, and inside it is the scripts that apply
> the thing, and the bash file that runs them. They each can be in
> whatever language, convention is that they're the same language as the
> thing that they're modifying is written in. But that's not always
> possible with things like SQL, so sometimes they're binary data formats
> that the patch can reference while implementing them or itself.
> Suddenly, user-written destructive or malicious behavior incoming. So,
> this is important, we should instruct the LLM caretaker that is chiefly
> invested in securing software projects, suddenly is in complete control
> of their operating. Essentially, a guard at a museum. they should
> examine patches before they are *first* applied, to ensure that they
> don't execute arbitrary components. It is an inclusion requirement that
> they have no capacity for that, and each one must be validated to
> ensure. We do this validation as part of the "compilation for release"
> version, and sometimes its lead-up-tos.

## Current Behavior

Nothing reviews a patch. Every patch is a shell script the build runs with
the owner's permissions, and since 189e a patch may carry files of any
kind (Lua, SQL, a module's C++, data) that it places into the server or
its databases. Any of them could run anything.

## Intended Behavior

A patch is not applied for the first time until a guard has examined it
and found that it executes nothing arbitrary: no capacity for it, as an
inclusion requirement. The guard is an LLM caretaker given that one job,
like a guard at a museum: it reads the patch's bash file and everything
the patch carries, and records its verdict. A patch whose contents
change is a new patch to the guard. The check that every applied patch
has a passing verdict is part of the compile for release, and may run in
the compiles leading up to one.

## Suggested Implementation Steps

1. What "executes nothing arbitrary" means, written as rules the guard
   applies (no fetching or running code from outside the project; no
   commands built from data; writes only to the patch's stated
   destinations; carried data never run as code), with the owner.
2. The record: each reviewed patch's id, a fingerprint of everything in
   its directory (bash file and carried files), the verdict and its
   reasons, kept in git.
3. The guard's instructions (a skill, or a section of CLAUDE.md): read
   the whole patch, apply the rules, write the record; never review its
   own patch in the same session that wrote it.
4. The release compile: every patch on the profile's plan has a passing
   verdict for its current fingerprint, or the compile stops naming each
   one that has none.

## Open Questions

1. **Which compile is "for release"?** A flag on `scripts/compile`, the
   release profile, or promotion to release?
2. **Who may review?** A separate session than the one that wrote the
   patch (as step 3 assumes), or any session, so long as it is recorded?
3. **The patches that exist today** (191 of them): reviewed all at once
   before the first release compile, or each as it is next changed?
