# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2025-06-30

### Changed

- Prefix protocol object getter/setter names with underscores to hint that they shouldn't be used.

### Fixed

- Incorrect (de)serialization of some data structures containing arrays with trailing delimiters.
- Change incorrect `ISkillLearn.StatRequirements` field type from `ICharacterBaseStats` to
  `ISkillStatRequirements`.


## [1.0.0-RC1] - 2024-10-20

### Added

- Support for EO data structures:
  - Client packets
  - Server packets
  - Endless Map Files (EMF)
  - Endless Item Files (EIF)
  - Endless NPC Files (ENF)
  - Endless Spell Files (ESF)
  - Endless Class Files (ECF)
- Utilities:
  - Data reader
  - Data writer
  - Number encoding
  - String encoding
  - Data encryption
  - Packet sequencer

[Unreleased]: http://github.com/cirras/eolib-pas/compare/v1.0.0...HEAD
[1.0.0]: http://github.com/cirras/eolib-pas/compare/v1.0.0-RC1...v1.0.0
[1.0.0-RC1]: http://github.com/cirras/eolib-pas/compare/v1.0.0-RC1
