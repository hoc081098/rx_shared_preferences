# Issue tracker: GitHub

Issues and specs live in GitHub Issues for `hoc081098/rx_shared_preferences`.
Use the `gh` CLI from this checkout. Outside it, pass `--repo hoc081098/rx_shared_preferences`.

## Conventions

- **Create:** `gh issue create --title '<title>' --body-file <path>`.
- **Read:** `gh issue view <number> --json number,title,body,labels,comments,state,url`.
- **List:** `gh issue list --state open`, with `--label` and `--state` filters as needed.
- **Update the body:** `gh issue edit <number> --body-file <path>`.
- **Comment:** `gh issue comment <number> --body-file <path>`.
- **Apply or remove labels:** `gh issue edit <number> --add-label '<label>'` or `--remove-label '<label>'`. Use the mapping in `triage-labels.md`.
- **Close:** post any explanation as a comment, then run `gh issue close <number>`.

Write multiline bodies and comments to a temporary file and pass `--body-file`.

Use native GitHub sub-issues through `gh api` to link child issues to a parent. If unavailable, add the child to a task list in the parent and put `Part of #<parent>` at the top of the child body.

## Pull requests as a triage surface

**PRs as a request surface: no.**

GitHub shares issue and PR numbers. Resolve an ambiguous reference with `gh pr view <number>`, falling back to `gh issue view <number>`.

## Skill operations

- **Publish to the issue tracker:** create a GitHub issue.
- **Fetch the relevant ticket:** read the issue body, labels and comments with the read command above.

## Wayfinding operations

For `/wayfinder`, the map is a single issue with child issues as tickets.

- **Map:** an issue labelled `wayfinder:map`, containing Notes, Decisions-so-far and Fog.
- **Child ticket:** link it to the map using the sub-issue convention above. Apply `wayfinder:<type>`, where the type is `research`, `prototype`, `grilling` or `task`.
- **Blocking:** use native GitHub issue dependencies through `gh api`. These require the blocker's numeric database ID, not its issue number or node ID. Fetch it with `gh api repos/hoc081098/rx_shared_preferences/issues/<number> --jq .id`. If dependencies are unavailable, put `Blocked by: #<number>, #<number>` at the top of the child body.
- **Frontier:** among the map's open children, choose the first in map order with no open blockers and no assignee.
- **Claim:** assign the issue with `gh issue edit <number> --add-assignee @me` before starting work.
- **Resolve:** comment with the answer, close the ticket, then append a short explanation and link to the map's Decisions-so-far.
