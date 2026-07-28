//
//  RelativeDirection.swift
//  OTPKit
//

import Foundation
import OSLog

/// The turn a walking `Step` asks the rider to make, as reported by OTP.
///
/// OTP sends these as uppercase tokens (`HARD_LEFT`). Rendering the token directly leaks
/// English-shaped data into every locale, so callers should use ``displayName``.
public enum RelativeDirection: String, CaseIterable, Sendable {
    case depart = "DEPART"
    case hardLeft = "HARD_LEFT"
    case left = "LEFT"
    case slightlyLeft = "SLIGHTLY_LEFT"
    case continueStraight = "CONTINUE"
    case slightlyRight = "SLIGHTLY_RIGHT"
    case right = "RIGHT"
    case hardRight = "HARD_RIGHT"
    case circleClockwise = "CIRCLE_CLOCKWISE"
    case circleCounterclockwise = "CIRCLE_COUNTERCLOCKWISE"
    case elevator = "ELEVATOR"
    case uturnLeft = "UTURN_LEFT"
    case uturnRight = "UTURN_RIGHT"
    case enterStation = "ENTER_STATION"
    case exitStation = "EXIT_STATION"
    case followSigns = "FOLLOW_SIGNS"

    /// Creates a direction from an OTP token, tolerating casing and spaces in place of underscores.
    public init?(otpDirection: String) {
        guard let direction = RelativeDirection(rawValue: otpDirection.normalizedOTPToken) else { return nil }
        self = direction
    }

    /// Localized instruction, phrased to lead a sentence such as "Turn left onto Pine St".
    public var displayName: String {
        switch self {
        case .depart:
            return OTPLoc("direction.depart", comment: "Walking direction: start out")
        case .hardLeft:
            return OTPLoc("direction.hard_left", comment: "Walking direction: sharp left turn")
        case .left:
            return OTPLoc("direction.left", comment: "Walking direction: left turn")
        case .slightlyLeft:
            return OTPLoc("direction.slightly_left", comment: "Walking direction: slight left turn")
        case .continueStraight:
            return OTPLoc("direction.continue", comment: "Walking direction: keep going straight")
        case .slightlyRight:
            return OTPLoc("direction.slightly_right", comment: "Walking direction: slight right turn")
        case .right:
            return OTPLoc("direction.right", comment: "Walking direction: right turn")
        case .hardRight:
            return OTPLoc("direction.hard_right", comment: "Walking direction: sharp right turn")
        // The left/right and clockwise/counterclockwise pairs are kept distinct: collapsing
        // them would drop routing information the server took the trouble to send.
        case .circleClockwise:
            return OTPLoc("direction.circle_clockwise", comment: "Walking direction: go clockwise around a roundabout")
        case .circleCounterclockwise:
            return OTPLoc("direction.circle_counterclockwise",
                          comment: "Walking direction: go counterclockwise around a roundabout")
        case .elevator:
            return OTPLoc("direction.elevator", comment: "Walking direction: take the elevator")
        case .uturnLeft:
            return OTPLoc("direction.uturn_left", comment: "Walking direction: U-turn towards the left")
        case .uturnRight:
            return OTPLoc("direction.uturn_right", comment: "Walking direction: U-turn towards the right")
        case .enterStation:
            return OTPLoc("direction.enter_station", comment: "Walking direction: enter a transit station")
        case .exitStation:
            return OTPLoc("direction.exit_station", comment: "Walking direction: leave a transit station")
        case .followSigns:
            return OTPLoc("direction.follow_signs", comment: "Walking direction: follow posted signage")
        }
    }
}

public extension Step {
    /// Localized instruction for this step, falling back to the raw OTP token when unrecognized.
    var directionDisplayName: String? {
        guard let relativeDirection else { return nil }
        guard let direction = RelativeDirection(otpDirection: relativeDirection) else {
            Logger.main.warning("Unrecognized OTP relative direction: \(relativeDirection)")
            return relativeDirection.humanizedOTPToken
        }
        return direction.displayName
    }
}
