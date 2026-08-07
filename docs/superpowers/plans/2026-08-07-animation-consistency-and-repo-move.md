# Feibi Animation Consistency And Repository Move Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild Feibi's affected atlas rows exclusively from approved existing frames, then place both independent repositories under one new parent directory in `learning`.

**Architecture:** Edit only the existing 1536x2288 v2 atlas on its fixed 192x208 cell grid. Copy row 1 into row 2 with a per-cell horizontal flip, keep row 7's six active cells sourced from existing laptop-holding frames, regenerate deterministic previews/checksums, install the validated package, then move both complete Git directories into `C:\Users\Lenovo\Desktop\learning\repositories` after boundary checks.

**Tech Stack:** PowerShell, bundled Python with Pillow, hatch-pet validation scripts, Git.

## Global Constraints

- Do not generate new visual material.
- Preserve all unaffected atlas rows byte-for-byte at decoded pixel level.
- Row 2 must equal the per-cell horizontal mirror of row 1 while preserving frame order.
- Row 7 must show Feibi holding the laptop in every used frame.
- Keep `feibi-codex-pet` and `automation-summer-learning` as separate Git repositories.
- Stop before moving if either destination exists, either source is a reparse point, or repository roots do not match expectations.

---

### Task 1: Deterministic atlas repair

**Files:**
- Modify: `pet/feibi/spritesheet.webp`
- Modify: `assets/preview-contact-sheet.png`
- Modify: `assets/running-laptop.gif`
- Modify: `assets/happy-bubble.gif` only if preview regeneration requires it
- Modify: `checksums.sha256`
- Modify: `CHANGELOG.md`
- Test: `tests/Test-Package.ps1`

**Interfaces:**
- Consumes: Existing 1536x2288 v2 atlas with 192x208 cells.
- Produces: A validated atlas with deterministic row relationships and updated public previews.

- [ ] **Step 1: Snapshot hashes and verify atlas geometry**

Run the hatch-pet atlas validator and record the source SHA-256 before editing.

- [ ] **Step 2: Rebuild row 2 from row 1**

For columns 0-7, crop `(col*192, 208, (col+1)*192, 416)`, horizontally flip that cell, and paste it at `(col*192, 416)` without reversing column order.

- [ ] **Step 3: Normalize row 7 from existing laptop frames**

Confirm all six active cells contain the approved laptop prop. Reuse only those existing cells; if any cell lacks the laptop, replace it with an existing laptop-holding frame from the same row while retaining a coherent loop. Keep columns 6-7 transparent.

- [ ] **Step 4: Regenerate previews and checksums**

Create the contact sheet and row GIFs from the modified atlas using deterministic scripts; update only the repository's published preview files and package hashes.

- [ ] **Step 5: Validate invariants**

Assert geometry/mode, row 2 equals the horizontal mirror of row 1 cell-by-cell, unused cells remain transparent, all unaffected rows equal the pre-edit atlas, package tests pass, and the installed pet matches the repository package.

### Task 2: Move two independent repositories

**Files:**
- Move: `C:\Users\Lenovo\Desktop\learning\feibi-codex-pet`
- Move: `C:\Users\Lenovo\Desktop\learning\automation-summer-learning`
- Create directory: `C:\Users\Lenovo\Desktop\learning\repositories`

**Interfaces:**
- Consumes: Two verified ordinary directories whose Git roots equal their source paths.
- Produces: `repositories\feibi-codex-pet` and `repositories\automation-summer-learning`, each retaining its own `.git` and remote configuration.

- [ ] **Step 1: Inspect exact sources and destinations**

Verify source type, reparse status, Git root, status, and remotes; verify both destinations do not exist.

- [ ] **Step 2: Create the bounded parent directory**

Create only `C:\Users\Lenovo\Desktop\learning\repositories` and resolve its absolute path.

- [ ] **Step 3: Move each repository atomically within the same volume**

Move each exact source directory with `Move-Item -LiteralPath`; stop immediately on any failure and do not retry with broader targets.

- [ ] **Step 4: Verify repository separation after the move**

Run `git rev-parse --show-toplevel`, `git status -sb`, and `git remote -v` inside each new path. Confirm neither root is the other repository or the shared parent.

### Task 3: Publish Feibi changes

**Files:**
- Commit only files changed by Task 1 plus this plan.

**Interfaces:**
- Consumes: Validated Feibi worktree at its new path.
- Produces: One scoped commit published to the existing Feibi GitHub repository.

- [ ] **Step 1: Review the complete diff and test results**

Confirm no unrelated files or private paths are staged.

- [ ] **Step 2: Commit the scoped update**

Stage explicit Feibi paths and commit with a concise animation-consistency message.

- [ ] **Step 3: Push and verify GitHub Actions**

Push the existing branch to the existing Feibi remote and confirm the package validation workflow succeeds. If native Git transport is unavailable, use the authenticated GitHub API without changing repository contents or history beyond the intended commit.
