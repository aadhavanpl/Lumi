# Releasing

Lumi ships as a Developer ID–signed, notarized `.zip` attached to a GitHub release, installed
through a personal Homebrew tap. Cutting a release is one command:

```bash
git tag v0.2.0 && git push origin v0.2.0
```

`.github/workflows/release.yml` does the rest: archive → export → notarize → staple → attach
the zip to a GitHub release → bump `Casks/lumi.rb` in the tap.

The version comes from the tag, not from `project.pbxproj`. `MARKETING_VERSION` and
`CURRENT_PROJECT_VERSION` are passed on the `xcodebuild` command line, so never hand-edit the
project file to cut a release. Tags must be `vMAJOR.MINOR.PATCH`; the workflow rejects
anything else.

## One-time setup

### 1. Developer ID certificate

Requires a paid Apple Developer Program membership.

1. Xcode → Settings → Accounts → your team → Manage Certificates → **+** → **Developer ID
   Application**.
2. Keychain Access → find the new `Developer ID Application: …` identity → right-click →
   Export → `.p12`, with a password.
3. `base64 -i cert.p12 | pbcopy`

### 2. App Store Connect API key (for `notarytool`)

1. [App Store Connect → Users and Access → Integrations → Keys](https://appstoreconnect.apple.com/access/integrations/api),
   create a key with the **Developer** role. The `.p8` downloads once — keep it.
2. Note the **Key ID** and the **Issuer ID** shown on that page.
3. `base64 -i AuthKey_XXXX.p8 | pbcopy`

### 3. Tap repository

Create a public repo named **`homebrew-tap`** under the same owner, containing
`Casks/lumi.rb`:

```ruby
cask "lumi" do
  version "0.1.0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  url "https://github.com/aadhavanpl/Lumi/releases/download/v#{version}/Lumi-#{version}.zip"
  name "Lumi"
  desc "Inventories every agent skill installed on your machine"
  homepage "https://github.com/aadhavanpl/Lumi"

  depends_on macos: ">= :tahoe"

  app "Lumi.app"

  zap trash: [
    "~/Library/Preferences/com.aadhavan.Lumi.plist",
    "~/Library/Caches/com.aadhavan.Lumi",
  ]
end
```

The `version` and `sha256` lines are rewritten by the workflow, so keep them one-per-line at
two-space indent.

### 4. Repository secrets

Settings → Secrets and variables → Actions:

| Secret | Value |
| --- | --- |
| `DEVELOPER_ID_P12_BASE64` | base64 of the exported `.p12` |
| `DEVELOPER_ID_P12_PASSWORD` | password used at export |
| `ASC_KEY_P8_BASE64` | base64 of the `.p8` |
| `ASC_KEY_ID` | API key ID |
| `ASC_ISSUER_ID` | API issuer ID |
| `HOMEBREW_TAP_TOKEN` | fine-grained PAT, Contents: read/write on `homebrew-tap` only |

## Verifying a release

```bash
brew install --cask aadhavanpl/tap/lumi
spctl -a -vvv -t install /Applications/Lumi.app
```

`spctl` must report `source=Notarized Developer ID`. If it doesn't, the app was installed
from an unstapled build and users will hit Gatekeeper on first launch.

## Notes

- Homebrew's main `homebrew-cask` repo has notability requirements Lumi doesn't meet yet, and
  discourages very frequent releases. The personal tap has neither constraint.
- Sparkle in-app updates are deferred; until then users update via `brew upgrade --cask lumi`.
  When Sparkle lands, add `auto_updates true` to the cask.
