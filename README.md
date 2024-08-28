# OTPKit

OpenTripPlanner library for iOS, written in Swift.

## Compatibility

* iOS: OTPKit is compatible with iOS 17.0 and higher.
* OTP: OTPKit is known to be compatible with OpenTripPlanner 1.5.x and higher. It is presumed to work on earlier versions, but is not tested on them.

## Architecture

More to come on this in the future, but for now it's worth mentioning that OTPKit uses OTP 1.x's REST API to communicate with OpenTripPlanner servers because the servers we care most about this framework working with are all running on OTP 1.5.x.

## History

This project was created by Hilmy Veradin with Aaron Brethorst as part of the [Google Summer of Code 2024](https://summerofcode.withgoogle.com/programs/2024/projects/RHtM4Lyc) program.

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

## Additional Information

As mentioned in the History section, this repo was originally created as a Google Summer of Code Project. Here is the final report:

### Google Summer of Code 2024 Final Report

This report covers the work completed from the start of the GSOC 2024 period in May through the end of the program in August 2024.

### Project Goals

OTPKit is an OpenTripPlanner Client Library written in Swift. This project aims to encapsulate the functionalities of OpenTripPlanner. In its initial version, we aimed to integrate OTPKit into the [OneBusAway](https://github.com/OneBusAway/onebusaway-ios) app, facilitating seamless integration with existing maps and features within the OneBusAway app.

#### What Was Done

By the end of the GSOC period, several key objectives were accomplished. Most importantly, we successfully integrated OpenTripPlanner using Swift, made the MVP for OpenTripPlanner integration, and managed to make OTPKit usable as a Swift Package.

#### Current State

OTPKit is now available on TestFlight via OTPKitDemo. We are waiting for our beta testers to try it out and gather feedback.

#### What's Left To Do

After receiving TestFlight feedback, the remaining tasks include integrating OTPKit into the OneBusAway App while making some improvements.

#### Code Merged Upstream

Some of the code that has been merged:

##### Codebase improvement
- https://github.com/OneBusAway/otpkit/pull/18
- https://github.com/OneBusAway/otpkit/pull/28

##### Main Tasks
- https://github.com/OneBusAway/otpkit/pull/19
- https://github.com/OneBusAway/otpkit/pull/20
- https://github.com/OneBusAway/otpkit/pull/23
- https://github.com/OneBusAway/otpkit/pull/31
- https://github.com/OneBusAway/otpkit/pull/32
- https://github.com/OneBusAway/otpkit/pull/33
- https://github.com/OneBusAway/otpkit/pull/35
- https://github.com/OneBusAway/otpkit/pull/39
- https://github.com/OneBusAway/otpkit/pull/41
- https://github.com/OneBusAway/otpkit/pull/46
- https://github.com/OneBusAway/otpkit/pull/47
- https://github.com/OneBusAway/otpkit/pull/54
- https://github.com/OneBusAway/otpkit/pull/55
- https://github.com/OneBusAway/otpkit/pull/56

##### Bug Fixes
- https://github.com/OneBusAway/otpkit/pull/58
- https://github.com/OneBusAway/otpkit/pull/61
- https://github.com/OneBusAway/otpkit/pull/62

#### Challenges and Learnings

There were several challenges and learning opportunities while developing OTPKit. Apart from developing this project using SwiftUI from scratch, the most interesting part was the main business logic: integrating SwiftUI MapKit with the OpenTripPlanner server. Additionally, creating OTPKit as a Swift Package to ensure easy library distribution was quite challenging.