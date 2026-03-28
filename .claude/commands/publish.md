---
name: publish
description: Full BuddyFlash release - git, GitHub, CurseForge
user-invocable: true
---

# BuddyFlash Full Release

Perform a complete release. Follow ALL steps in order.

## Pre-flight
- Read current version from `BuddyFlash/BuddyFlash.toc`
- Increment PATCH version by 1 unless user specifies otherwise
- Print summary of changes (based on git diff since last tag)

## Step 1: Build
- Update version in `BuddyFlash/BuddyFlash.toc`
- Create addon zip: `zip -r BuddyFlash.zip BuddyFlash/ -x "*.DS_Store"`
- Copy to WoW: `cp BuddyFlash/*.lua BuddyFlash/*.toc "/Volumes/Samsung 1TB/World of Warcraft/_retail_/Interface/AddOns/BuddyFlash/"`

## Step 2: Git + GitHub
- `git add -A`
- `git commit -m "vX.Y.Z - <description>"`
- `git push`
- `gh release create vX.Y.Z` with release notes + BuddyFlash.zip asset

## Step 3: CurseForge
- Upload with changelog:
  ```
  cat > /tmp/cf_metadata.json << 'JSONEOF'
  {"changelog":"CHANGELOG_HERE","displayName":"BuddyFlash X.Y.Z","releaseType":"release","gameVersions":[15855]}
  JSONEOF
  curl -s -X POST "https://wow.curseforge.com/api/projects/1497335/upload-file" \
    -H "X-Api-Token: 62d60221-94cc-4749-afa6-ca180d0e8b8f" \
    -F "metadata=</tmp/cf_metadata.json" -F "file=@BuddyFlash.zip"
  ```
  CurseForge Project ID: 1497335

## Step 4: Summary
Print final summary with GitHub release URL and CurseForge status.

## RULES
- NEVER symlink to WoW folder - always COPY
- Version in .toc must match release tag
