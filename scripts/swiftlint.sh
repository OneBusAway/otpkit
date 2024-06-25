# Adds support for Apple Silicon brew directory
export PATH="$PATH:/opt/homebrew/bin"

if [ "$CI" = true ]; then
  echo "skipping swiftlint because in GitHub Actions it runs in a separate job."
elif which swiftlint >/dev/null; then
  swiftlint --fix && swiftlint
else
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint or via Homebrew."
fi
