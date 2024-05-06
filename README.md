# OTPKit

OpenTripPlanner library for iOS, written in Swift.

## Compatibility

* iOS: OTPKit is compatible with iOS 16.0 and higher.
* OTP: OTPKit is known to be compatible with OpenTripPlanner 1.5.x and higher. It is presumed to work on earlier versions, but is not tested on them.

## Architecture

More to come on this in the future, but for now it's worth mentioning that OTPKit uses OTP 1.x's REST API to communicate with OpenTripPlanner servers because the servers we care most about this framework working with are all running on OTP 1.5.x.

## Code Quality

### Unit Testing and CI

We make extensive use of unit testing in this project to ensure that our code works as expected and our changes do not cause regressions. All PR merges are gated on unit tests passing in GitHub Actions. Please be sure to run tests locally before opening a pull request. Also, please add or update unit tests to account for changes to your code.

### Swiftlint

We make extensive use of [Swiflint](https://github.com/realm/SwiftLint) in order to ensure that our code adheres to standard styles and conventions. Please install Swiftlint locally via Homebrew:

```
brew install swiftlint
```

A clean bill of health from Swiftlint is required for merging pull requests.

## License

OTPKit is licensed under the Apache 2.0 license. See [LICENSE](LICENSE) for more details.
