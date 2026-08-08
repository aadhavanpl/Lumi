# Glossary

Terms are grounded in what actually exists on disk, verified 2026-08-07.

## Skill
One directory containing a `SKILL.md`. The atomic unit of agent knowledge.

Frontmatter fields defined by the [Agent Skills](https://agentskills.io) spec and Claude
Code's extensions: `name`, `description`, `when_to_use`, `argument-hint`, `arguments`,
`disable-model-invocation`, `user-invocable`, `allowed-tools`, `disallowed-tools`,
`model`, `effort`, `metadata`, `license`, `compatibility`.

**There is no `version` field.** A loose skill has no version. This is the single most
consequential fact for this product.

## Plugin
A git repo packaged as a bundle, containing skills *and* hooks, agents, MCP servers,
scripts. Declares a real semver `version` in `.claude-plugin/plugin.json`.

Example: `superpowers@6.0.3` ships 14 skills plus a `hooks/` directory.

The plugin is the unit of install/update/remove. **An individual skill inside a plugin
cannot be removed or moved** — it lives in a version-numbered cache directory and would
reappear on the next plugin update.

## Marketplace
A git repo whose `.claude-plugin/marketplace.json` is a catalog: a list of plugins with a
fetch source (`url` + pinned `sha`) for each. Analogous to a package registry index.

`claude-plugins-official` lists 37 plugins.

## Origin
*(working term — was "Source")* What put a skill on disk, and therefore what actions are
legal on it. Four kinds observed:

| Origin | Real version? | Update mechanism | Delete one skill? | Move? |
| --- | --- | --- | --- | --- |
| Plugin (via marketplace) | yes, semver | refresh marketplace → reinstall plugin | no | no |
| Repo install (skills.sh) | no, git sha only | `npx skills update` (blind overwrite) | yes | yes |
| Hand-written / local | none | n/a — the user is upstream | yes | yes |
| Agent built-in | ships with the CLI | update the CLI | no | no |

## Scope
Where an install applies:
- **Global / user** — `~/.claude/skills`, `~/.agents/skills`, `~/.codex/skills`
- **Project** — `<project>/.claude/skills`, `<project>/.agents/skills`
- **Agent-specific** — a given agent's directory, at either scope

Plugins carry scope independently: `installed_plugins.json` records `scope: "user"` or
`scope: "local"` with a `projectPath`.

## Installed vs Enabled
Two independent states for plugins. `installed_plugins.json` records what is on disk;
`enabledPlugins` in `settings.json` records what is active. A plugin can be installed but
off.

## Canonical store + link farm
The skills.sh install pattern: the real directory lives in `.agents/skills/<name>`, and
each agent directory holds a symlink to it. Consequence: one skill appears at N paths, and
moving the canonical directory breaks every symlink pointing at it.

## Workspace
A directory the user registers with the app as a place to look for project-scoped skills.
Necessary because project skills can live anywhere on disk and no reliable cross-agent
registry of project locations exists.
