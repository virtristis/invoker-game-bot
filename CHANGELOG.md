# Changelog

All notable changes to this project are documented here.

## [Unreleased]

### Added
- **Invoker in the header of the horizontal layout**: the portrait from the intro, drawn in dots in the colour of the theme, fills the empty middle of the header.
- **The website in Español and 中文**, next to English and Русский.
- **A GIF of a full practice run** in the README and on the website. It is made by the app itself: `--selftest drill-gif` plays a practice run on a virtual clock and saves the frames, `tools/make-gif.ps1` (with `tools/GifWriter.cs`) turns them into a small GIF.

## [1.8.2] - 2026-10-09

### Changed
- **New images** for the README and the website, taken on the current version: the showcase banner (3 modes, the sound button, 3 themes and 4 languages), the horizontal layout, the coach overlay with the spell icon, practice, statistics and the social preview.
- The README and the website mention that the overlay can be resized with the mouse wheel.
- `tools/make-banner.ps1` and `tools/make-docs-images.ps1` build these images from the app's screenshots; the self-test `--selftest shot-stages` renders the coach overlay stages.
- Window screenshots in self-tests are now reliable on a hidden desktop as well.

[1.8.2]: https://github.com/virtristis/invoker-game-bot/releases/tag/v1.8.2
