# Contributing

Thanks for your interest in improving `aem-tools`.

This project is small on purpose. Contributions should preserve that strength: keep behavior explicit, avoid unnecessary abstraction, and favor reliability over cleverness.

## Project Standards

- Prefer clear shell over clever shell.
- Keep scripts readable by experienced Unix users who may not know the project.
- Treat terminal UX as part of the product, not an afterthought.
- Preserve compatibility across macOS and Linux when practical.
- Separate human-facing terminal output from machine-captured stdout carefully.
- Avoid destructive behavior unless it is explicit and well-documented.

## Before Opening a Change

- Make sure the feature belongs in this project’s scope.
- Prefer extending an existing command over introducing a new one without a strong reason.
- Consider whether the behavior should be opt-in, especially if it changes defaults.

## Development Checklist

- Update built-in `help` output when changing CLI behavior.
- Update the README when usage or defaults change.
- Keep dry-run output accurate.
- Run syntax checks:

```bash
bash -n bin/aem-install bin/aem-package-install bin/aem-bundle-install
```

- Run `shellcheck` when available:

```bash
shellcheck bin/aem-install bin/aem-package-install bin/aem-bundle-install
```

## Style Notes

- Use ASCII unless there is a strong reason not to.
- Keep comments concise and useful.
- Prefer descriptive option names over short, ambiguous flags.
- Be deliberate about stdout vs stderr.

## Bug Reports

Helpful bug reports usually include:

- the exact command used
- the terminal and OS
- whether the issue occurred on macOS or Linux
- the visible output or error message
- whether `--dry-run` behaved as expected

## License

By contributing, you agree that your contributions will be licensed under the project’s MIT License.
