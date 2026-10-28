---
name: restarengine-devlog
description: Write and maintain evidence-based RestArtEngine Zhihu development logs. Use for 写知乎、下一期、阶段总结、把这阶段写成分享, or when the user asks to turn a completed engine phase into a DevLog.
---

# RestArtEngine DevLog

Use this skill for the repository's ongoing development-log series. It defines the Codex workflow; the article rules and current writing state remain in the project documents below.

## Source of truth

Read these before collecting changes or drafting:

1. The public repository `AGENTS.md`, its private `local/docs/AgentEntry.md`, and the machine-local output root in ignored `local/machine/Paths.md`. If the machine path file is missing, confirm the current machine's output root before writing; never infer it from historical notes.
2. [`local/docs/ZhihuSeries.md`](../../../local/docs/ZhihuSeries.md) for the normative format, evidence rules, privacy rules, and publishing checklist.
3. [`local/docs/ZhihuSeriesLedger.md`](../../../local/docs/ZhihuSeriesLedger.md) for the current issue, previous coverage, evidence inventory, and commitments.
4. The relevant `README.md`, `docs/Architecture.md`, source files, tests, logs, and screenshots for evidence.
5. The previous issue's actual Markdown and referenced media in the configured external root. Inspect its section structure, image placement, captions, filenames, and media dimensions; do not infer these from the ledger alone. DevLog01 was prepared with the supplementary model; reuse the series conventions, not unverified historical claims or model configuration.

Private workspace synchronization for Codex and supplementary models follows [`WorkspaceSync.md`](../../../local/docs/WorkspaceSync.md). Keep invoking this skill from the engine root at its original path; the private Git mirror is storage, not another execution location. Writing rules and ledgers are versioned only in the private workspace; final articles and media stay external.

If this issue actually uses a project or global skill, agent, or `agents/openai.yaml`, read that file and record the real file path. Do not claim a skill or agent that was not used in this run. Model/provider configuration is execution infrastructure, not article content; never copy tokens, gateway URLs, or machine configuration into either repository or the article.

## Workflow

1. Determine the issue boundary: previous published endpoint to the current engine endpoint. Check `git status --short` first. List dated Markdown files in the configured output root by filename; if today's issue already exists, ask whether to edit it or create another issue before overwriting it.
2. Resolve the start commit from the previous article's recorded endpoint, then fall back to the documented date rule. For the first issue include the root commit. Use `git log`, `git diff --stat`, and targeted diffs to collect changes; include uncommitted work as unverified evidence until it is run.
3. Update the ledger before writing prose. Group changes by system/module, mark every claim A/B/C, and give each selected item a source path plus command, log, screenshot, formula, or reproducible step. A means this run executed and observed it; B means present but not run now; C means planned or speculative. C belongs only in the next-step boundary.
4. Select three to six coherent technical modules. Fold the ledger into the article instead of publishing a separate checklist. Each module explains the previous limitation, the change and its trade-off, then ends with its evidence and boundary. The opening must explain how this issue was done with AI: the actual task path, inputs, agents/skills used, human review, and rework.
5. Before prose, map each selected visual claim to a shot: source/run, observable action, article insertion point, final relative filename and caption. Follow the media rules in `local/docs/ZhihuSeries.md` §6 and the current ledger's shot list. GUI/interaction claims need real visual evidence; logs alone are not a replacement. For preparation-only requests, finish this plan and mark uncaptured media pending without writing the article.
6. Draft the article in the configured external output root as `YYYY-MM-DD_第NN期_短标题.md`; put final PNG/GIF media in `YYYY-MM-DD_第NN期_assets/`. Keep raw captures/recordings as separate evidence. Insert each image immediately beside its explanation with a relative link and informative caption. Use real continuous recordings for motion claims, never interpolate or stage unrelated stills as a live demonstration. Every final GIF must be **at most 5,000,000 bytes**, measured from the encoded file. This is the user's series rule, not a claim about a platform's current upload limit.
7. Run [scripts/validate_media.py](scripts/validate_media.py) against the actual article (Python 3 + Pillow) to check local references, image decoding, dimensions, animation metadata and GIF byte limits. Then visually inspect final PNGs, play each GIF through its loop, and check privacy, readable text, timing and article placement. The script does not certify those manual checks. Apply the remaining publication checks in `local/docs/ZhihuSeries.md`; the handoff is ledger + article + final media + evidence references + self-check result. Do not call a shot list or a passing file-size check a finished article.
8. After publication, record the actual date, link, covered range, endpoint commit, next start, and tag in the ledger. Do not rewrite the historical coverage of a published issue.

## Boundaries

- Do not invent completed behavior, verification, collaboration steps, or screenshots.
- Do not turn plans, code that was not run, or old unverified notes into “现在能”.
- Do not expose credentials, provider endpoints, private chat content, or machine-specific absolute paths.
- Do not publish the ledger or evidence checklist as a second article; they are internal working metadata.
- This skill drafts and validates content. It does not publish externally or change model/provider configuration unless the user explicitly asks for that separate task.
