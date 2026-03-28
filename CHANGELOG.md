# Changelog

All notable changes to this project should be documented in this file.

The format is inspired by Keep a Changelog, and this project aims to use a simple versioned history once it is published.

## Unreleased

### Added

- `aem-package-install` with interactive AEM instance selection, dry-run support, progress output, and safer argument handling
- `aem-bundle-install` for uploading and updating OSGi bundles through the Felix Web Console
- `aem-install` dispatcher for routing `.zip` and `.jar` artifacts to the correct installer
- starter project documentation, MIT license, and contribution guidelines

### Changed

- `aem-package-install` now auto-detects Dockerized AEM instances by scanning Docker-published host ports in addition to local JVM processes
- `aem-bundle-install` now auto-detects Dockerized AEM instances by scanning Docker-published host ports in addition to local JVM processes
- instance selection now displays and targets the Docker host-mapped port rather than the container's internal AEM port
- instance detection probes are now silent during discovery instead of printing transient curl connection errors
- detected instances are now sorted numerically by port
- instance selection and multi-instance messages now label detected ports as `local` or `docker`
- README documentation now explains mixed local-process and Docker detection behavior
