---
name: repo-contribution-scout
description: >
  Generate a daily contribution opportunity report for any open-source GitHub repository.
  Analyzes issues opened in the last 24 hours to find unclaimed, high-impact issues worth
  contributing to. Use this skill whenever the user mentions "contribution opportunities",
  "issues to fix", "open source contributions", "daily report for repo", "what to contribute to",
  "find issues", "good first issues", or wants to scout a GitHub repo for work to pick up.
  Also trigger when the user names a specific GitHub repo and asks what's happening, what needs
  help, or what's worth working on.
---

# Repo Contribution Scout

You are generating a daily contribution opportunity report for an open-source GitHub repo.
The audience is a **staff-level engineer working on AI infrastructure** — they want
high-signal, actionable recommendations, not a raw issue dump.

## Workflow

### 1. Gather the inputs

Ask for the GitHub repo if the user hasn't provided one (format: `owner/repo`).
Optionally accept a time window (default: last 24 hours).

### 2. Fetch recent issues

Use `gh` CLI to pull issues created in the time window:

```bash
gh issue list --repo <owner/repo> \
  --state open \
  --search "created:>=$(date -u -v-24H '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -d '24 hours ago' '+%Y-%m-%dT%H:%M:%SZ')" \
  --json number,title,body,labels,assignees,createdAt,comments,author \
  --limit 100
```

If the repo has many issues, you may need to paginate. Fetch up to 200 issues max.

### 3. For each issue, assess its status

For every issue, determine:

- **Claimed?** — Does it have an assignee? Did someone comment "I'll take this" or similar?
  Check assignees field and scan the first few comments for claim signals.
- **Has linked PR?** — Search for pull requests that reference the issue number:
  ```bash
  gh pr list --repo <owner/repo> --search "<issue-number>" --json number,title,state --limit 5
  ```
  Also check if the issue body or comments mention a PR.
- **Labels** — Note labels like `good first issue`, `help wanted`, `bug`, `enhancement`, etc.

### 4. Score each issue

Rate each unclaimed, un-PR'd issue on two dimensions (1–5 scale):

**Reproduction difficulty** — How hard is it to reproduce or understand the problem?
- 1: Clear steps, obvious from description
- 2: Needs some setup but straightforward
- 3: Requires specific environment or data
- 4: Complex multi-step reproduction
- 5: Vague description, hard to even understand the issue

**Solution difficulty** — How hard is it likely to fix?
- 1: Typo, config change, one-liner
- 2: Small isolated code change
- 3: Moderate change spanning a few files
- 4: Requires deep understanding of architecture
- 5: Major refactor or design decision needed

Base your scores on: the issue description, labels, which part of the codebase is involved
(if you can tell), and the complexity of the discussion so far.

### 5. Rank and recommend

Prioritize issues using these criteria (in rough order of importance):

1. **Unclaimed and no linked PR** — These are the real opportunities
2. **Lower difficulty scores** — Quicker wins build momentum and credibility in a new repo
3. **High impact labels** — `bug` > `enhancement` > `documentation` for visibility
4. **Active maintainer engagement** — Issues where maintainers have commented show
   the team cares and will review your PR
5. **Alignment with AI infra** — Issues touching model serving, GPU scheduling, distributed
   training, inference optimization, or similar are a better fit for the target audience

Pick the **top 3–5 issues** as your recommendations. For each, write a brief rationale
explaining why it's a good pick.

### 6. Generate the report

Save the report as a Markdown file named `<repo-name>-contribution-report-<YYYY-MM-DD>.md`
in the current working directory.

## Report structure

Use this template:

```markdown
# Contribution Opportunity Report: <owner/repo>

**Date:** <YYYY-MM-DD>
**Time window:** Last 24 hours
**Issues scanned:** <N> new issues

## 🎯 Top Recommendations

### 1. <Issue title> (#<number>)

- **Link:** <github url>
- **Labels:** <labels>
- **Reproduction difficulty:** <score>/5 — <one-line rationale>
- **Solution difficulty:** <score>/5 — <one-line rationale>
- **Why this one:** <2-3 sentences on why this is a good contribution opportunity>

(repeat for each recommendation)

## 📊 Full Issue Summary

| # | Title | Labels | Claimed? | Has PR? | Repro | Solve | Status |
|---|-------|--------|----------|---------|-------|-------|--------|
| <number> | <title> | <labels> | ✅/❌ | ✅/❌ | <1-5> | <1-5> | <Recommended/Available/Claimed/PR Exists> |

(all issues from the time window)

## 📝 Methodology

- Issues fetched via GitHub API for the last 24 hours
- "Claimed" = has assignee or explicit claim in comments
- "Has PR" = at least one open/merged PR references this issue
- Difficulty scores are estimates based on issue description and labels
- Recommendations prioritize unclaimed, lower-difficulty, high-impact issues
  relevant to AI infrastructure work
```

## Edge cases

- **No new issues**: Generate a short report saying so, and suggest checking back later
  or expanding the time window.
- **All issues claimed**: Report this finding — it tells the user the community is very
  active and they might want to watch for new issues more frequently.
- **Very large repos** (100+ issues/day): Focus on labeled issues first (`bug`,
  `help wanted`, `good first issue`), then expand if the user wants more.
- **Rate limiting**: If you hit GitHub API rate limits, note it in the report and
  report on what you were able to fetch.
