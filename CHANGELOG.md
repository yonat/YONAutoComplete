# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- fix PrivacyInfo.xcprivacy format.

## [1.3.1] - 2023-08-19

### Added
- add privacy manifest PrivacyInfo.xcprivacy.

## [1.3.0] - 2022-10-03

### Added
- allow having another text field delegate by setting `autoComplete.textFieldDelegate`. 

## [1.2.2] - 2020-01-25

### Fixed
- don't forward UIControlEventEditingDidEndOnExit to prevent a text field inside UIAlertController from dismissing the presenting view controller as well as the alert.

## [1.2.0] - 2018-09-07

### Added
- limit completions shown to `maxCompletions`.

## [1.1.1] - 2018-07-23

### Fixed
- better styling for completions inside a UIAlertController

## [1.1.0] - 2018-07-21

### Added
- show completions inside a UIAlertController
