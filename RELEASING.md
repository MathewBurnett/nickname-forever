# Releasing

Releases are built and uploaded by GitHub Actions using the
[BigWigs packager](https://github.com/BigWigsMods/packager).

## Every push

`.github/workflows/build.yml` runs the tests (Lua 5.1, stubbed WoW API) and
builds the zip without uploading it. Download it from the run's **Artifacts**
to try the exact files a release would contain.

## Making a release

1. Add the new version to the top of `CHANGELOG.md` and commit.
2. Tag the commit with the version and push the tag:

   ```sh
   git tag 1.0.0-beta2
   git push origin 1.0.0-beta2
   ```

The tag name becomes the version (`## Version: @project-version@` in the TOCs)
and decides the release type:

| Tag contains | CurseForge file type |
|---|---|
| `alpha` (e.g. `1.1.0-alpha1`) | Alpha |
| `beta` (e.g. `1.0.0-beta2`) | Beta |
| neither (e.g. `1.0.0`) | Release |

`.github/workflows/release.yml` then runs the tests, builds
`NicknameForever-<version>.zip` (containing `NicknameForever/` and
`CustomNames/`), uploads it to CurseForge and creates a GitHub release.

Game versions are detected from `## Interface:` in `NicknameForever.toc`
(`16001` = WoW Forever, `1201xx` = Retail). Keep that line current.

## One-time setup

- **CurseForge project ID:** `## X-Curse-Project-ID: 1833014` in
  `NicknameForever/NicknameForever.toc` (done).
- **CurseForge API token:** create one at
  <https://authors.curseforge.com/#/settings/api-tokens> and add it to this repo
  as the Actions secret `CF_API_TOKEN` (Settings → Secrets and variables →
  Actions).

Without both, the release still builds and goes to GitHub, but nothing is
uploaded to CurseForge.
