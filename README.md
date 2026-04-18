# palee_elite_training_center

Flutter desktop application for the Palee Elite Training Center management system.

## Windows Auto Update

The app includes a manual update flow for the Windows desktop build:

1. Open the settings button in the header.
2. Click `ກວດສອບອັບເດດ` to read [version.json](version.json).
3. If a newer release exists, click `ອັບເດດດຽວນີ້`.
4. The app downloads the installer, closes itself, and starts the silent installer.

The update metadata is read from the `UPDATE_VERSION_URL` dart define. If you do not provide one, the app uses the repository default:

```bash
flutter run -d windows --dart-define=UPDATE_VERSION_URL=https://raw.githubusercontent.com/pengxue999/palee_elite_training_center/main/version.json
```

## Release Workflow

Tag a release with the format `v1.0.1` and push the tag:

```bash
git tag v1.0.1
git push origin v1.0.1
```

The GitHub Actions workflow in `.github/workflows/build-windows.yml` will:

1. Build the Windows release.
2. Create an installer with Inno Setup using [installer.iss](installer.iss).
3. Publish the installer to GitHub Releases.
4. Update [version.json](version.json) on the `main` branch.
