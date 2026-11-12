# Contributing to rx_shared_preferences

## Create a new issue

The easiest way to get involved is to create a [new issue](https://github.com/hoc081098/rx_shared_preferences/issues/new) when you spot a bug, if the documentation is incomplete or out of date, or if you identify an implementation problem.

## General coding guidelines

If you'd like to add a feature or fix a bug, we're more than happy to accept pull requests! We only ask a few things:

-   Ensure your code contains no analyzer errors, e.g.
    -   Code is strong-mode compliant
    -   Code is free of lint errors

-   Check formatting with `dart format --output=none --set-exit-if-changed lib test example`.

-   Write tests for all new code paths, consider using the [Stream Matchers](https://pub.dartlang.org/packages/test#stream-matchers) available from the test package.

-   Write helpful documentation

-   Validate release documentation with `dart doc --validate-links` and package
    contents with `dart pub publish --dry-run`. Both checks run in Flutter CI,
    including for Markdown-only changes. Resolve documentation errors and publish
    warnings before release.

-   If you would like to make a bigger / fundamental change to the codebase, please file a lightweight example PR / issue, or contact me via my email hoc081098@gmail.com so we can discuss the issue.
