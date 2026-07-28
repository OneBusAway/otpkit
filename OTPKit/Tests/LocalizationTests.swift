//
//  LocalizationTests.swift
//  OTPKitTests
//
//  Tests for localized display names of raw OTP tokens, and for the fixed-format
//  (wire) date formatters used to build OTP query parameters.
//

import Foundation
import Testing
@testable import OTPKit

@Suite("Localization Tests")
struct LocalizationTests {

    // MARK: - LegMode

    @Suite("LegMode")
    struct LegModeTests {

        @Test("Parses canonical OTP tokens")
        func canonicalTokens() {
            #expect(LegMode(otpMode: "BUS") == .bus)
            #expect(LegMode(otpMode: "CABLE_CAR") == .cableCar)
            #expect(LegMode(otpMode: "FUNICULAR") == .funicular)
        }

        @Test("Parsing tolerates casing and spaces")
        func lenientParsing() {
            #expect(LegMode(otpMode: "bus") == .bus)
            #expect(LegMode(otpMode: "Cable Car") == .cableCar)
            #expect(LegMode(otpMode: "  SUBWAY  ") == .subway)
        }

        @Test("Known aliases map to canonical cases")
        func aliases() {
            #expect(LegMode(otpMode: "BIKE") == .bicycle)
            #expect(LegMode(otpMode: "TRAIN") == .rail)
        }

        @Test("Unrecognized tokens do not parse")
        func unrecognized() {
            #expect(LegMode(otpMode: "TELEPORT") == nil)
            #expect(LegMode(otpMode: "") == nil)
        }

        @Test("Every case has a non-empty display name distinct from its raw token")
        func displayNames() {
            for mode in LegMode.allCases {
                #expect(!mode.displayName.isEmpty)
                #expect(mode.displayName != mode.rawValue)
            }
        }

        @Test("Leg display name is localized for a known mode")
        func legDisplayNameKnown() {
            let leg = PreviewHelpers.buildLeg()
            #expect(leg.mode == "TRAM")
            #expect(leg.modeDisplayName == "Tram")
        }

        @Test("Leg display name humanizes an unrecognized token")
        func legDisplayNameFallback() {
            #expect(LocalizationTests.leg(mode: "HOVERCRAFT").modeDisplayName == "Hovercraft")
            #expect(LocalizationTests.leg(mode: "RIDE_HAILING").modeDisplayName == "Ride Hailing")
        }
    }

    // MARK: - RelativeDirection

    @Suite("RelativeDirection")
    struct RelativeDirectionTests {

        @Test("Parses canonical OTP tokens")
        func canonicalTokens() {
            #expect(RelativeDirection(otpDirection: "HARD_LEFT") == .hardLeft)
            #expect(RelativeDirection(otpDirection: "CONTINUE") == .continueStraight)
            #expect(RelativeDirection(otpDirection: "UTURN_RIGHT") == .uturnRight)
        }

        @Test("Parsing tolerates casing and spaces")
        func lenientParsing() {
            #expect(RelativeDirection(otpDirection: "left") == .left)
            #expect(RelativeDirection(otpDirection: "Slightly Right") == .slightlyRight)
        }

        @Test("Unrecognized tokens do not parse")
        func unrecognized() {
            #expect(RelativeDirection(otpDirection: "SPIN_AROUND") == nil)
        }

        @Test("Every case has a non-empty display name distinct from its raw token")
        func displayNames() {
            for direction in RelativeDirection.allCases {
                #expect(!direction.displayName.isEmpty)
                #expect(direction.displayName != direction.rawValue)
            }
        }

        @Test("Step display name is localized for a known direction")
        func stepDisplayNameKnown() {
            let step = LocalizationTests.step(relativeDirection: "LEFT")
            #expect(step.directionDisplayName == "Turn left")
        }

        @Test("Step display name humanizes an unrecognized token")
        func stepDisplayNameFallback() {
            let step = LocalizationTests.step(relativeDirection: "SPIN_AROUND")
            #expect(step.directionDisplayName == "Spin Around")
        }

        @Test("Step display name is nil when OTP omits the direction")
        func stepDisplayNameMissing() {
            let step = LocalizationTests.step(relativeDirection: nil)
            #expect(step.directionDisplayName == nil)
        }
    }

    // MARK: - Wire-format date formatters

    @Suite("API date formatters")
    struct APIDateFormatterTests {

        /// 2024-05-10 08:00 local time, built on an explicitly Gregorian calendar.
        private static func referenceDate() -> Date {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = .current
            var components = DateComponents()
            components.year = 2024
            components.month = 5
            components.day = 10
            components.hour = 8
            components.minute = 0
            return calendar.date(from: components)!
        }

        @Test("Wire formatters are pinned to a Gregorian, POSIX locale in the local zone")
        func formattersArePinned() {
            for formatter in [DateFormatter.tripDateFormatter,
                              DateFormatter.tripTimeFormatter,
                              DateFormatter.tripAPITimeFormatter] {
                #expect(formatter.locale.identifier == "en_US_POSIX")
                #expect(formatter.calendar.identifier == .gregorian)
                // Guards the UTC shift: without an explicit zone these emit times offset
                // from the user's, so OTP plans for the wrong part of the day.
                #expect(formatter.timeZone.identifier == TimeZone.current.identifier)
                // And guards a regression to a pinned `.current`: these formatters are
                // `static let`, so a fixed zone would go stale the moment the device's
                // changes. Note `.autoupdatingCurrent != .current` even when they resolve
                // to the same zone, which is why the check above compares identifiers.
                #expect(formatter.timeZone == TimeZone.autoupdatingCurrent)
            }
        }

        @Test("Date parameter uses the OTP wire format")
        func dateParameter() {
            #expect(Self.referenceDate().formattedTripDate == "05-10-2024")
        }

        @Test("Time parameter uses the OTP wire format with Latin AM/PM")
        func timeParameter() {
            let actual = Self.referenceDate().formattedTripTime
            let scalars = actual.unicodeScalars
                .map { String(format: "U+%04X", $0.value) }
                .joined(separator: " ")
            #expect(actual == "8:00 AM", "actual=[\(actual)] scalars=[\(scalars)]")
        }

        /// Guards the bug the pinning fixes: an unpinned formatter on a device set to a
        /// non-Gregorian calendar emits a year OTP cannot parse.
        @Test("Unpinned formatting under a Buddhist calendar would corrupt the year")
        func unpinnedFormatterWouldRegress() {
            let naive = DateFormatter()
            naive.locale = Locale(identifier: "th_TH")
            naive.dateFormat = "MM-dd-yyyy"
            let naiveOutput = naive.string(from: Self.referenceDate())

            #expect(naiveOutput != "05-10-2024")
            #expect(Self.referenceDate().formattedTripDate == "05-10-2024")
        }
    }

    // MARK: - String table integrity

    @Suite("String tables")
    struct StringTableTests {

        static let locales = ["en", "ar", "zh-Hans", "zh-Hant", "es", "fil", "fr",
                              "it", "ko", "pl", "pt-BR", "ru", "vi"]

        /// Reads one locale's table out of the package bundle.
        ///
        /// `localization:` is the API meant for reaching a *specific* `.lproj` rather than
        /// whichever one the runtime would pick. `.strings` are compiled to binary plists at
        /// build time, which `PropertyListSerialization` reads transparently.
        private static func keys(in locale: String) throws -> [String: String] {
            let url = try #require(
                Localization.bundle.url(forResource: "Localizable",
                                  withExtension: "strings",
                                  subdirectory: nil,
                                  localization: locale),
                "no Localizable.strings for \(locale) in \(Localization.bundle.bundleURL.lastPathComponent)"
            )
            let data = try Data(contentsOf: url)
            let plist = try #require(try PropertyListSerialization.propertyList(
                from: data, format: nil) as? [String: String],
                "\(locale) table is not a string dictionary")
            return plist
        }

        @Test("Every locale defines exactly the keys the base table defines")
        func keyParity() throws {
            let base = try Self.keys(in: "en")
            #expect(!base.isEmpty)

            for locale in Self.locales.dropFirst() {
                let table = try Self.keys(in: locale)
                let missing = Set(base.keys).subtracting(table.keys).sorted()
                let extra = Set(table.keys).subtracting(base.keys).sorted()
                #expect(missing.isEmpty, "\(locale) is missing: \(missing)")
                #expect(extra.isEmpty, "\(locale) has stray keys: \(extra)")
            }
        }

        /// `NSLocalizedString` silently echoes the key when a lookup fails, so a typo'd or
        /// deleted key ships as literal `leg_mode.bus` in the UI. This is the guard for that.
        @Test("Every base key resolves through the package bundle")
        func everyKeyResolves() throws {
            let base = try Self.keys(in: "en")
            let sentinel = "\u{0}MISSING"

            for key in base.keys.sorted() {
                let value = Localization.bundle.localizedString(forKey: key, value: sentinel, table: nil)
                #expect(value != sentinel, "Localization.bundle cannot resolve \(key)")
            }
        }

        @Test("No locale ships an empty translation")
        func noEmptyValues() throws {
            for locale in Self.locales {
                let table = try Self.keys(in: locale)
                let blank = table.filter { $0.value.trimmingCharacters(in: .whitespaces).isEmpty }
                #expect(blank.isEmpty, "\(locale) has empty values for \(blank.keys.sorted())")
            }
        }

        @Test("Format specifiers match the base table in type and arity")
        func formatSpecifierParity() throws {
            let base = try Self.keys(in: "en")
            let specifier = try NSRegularExpression(pattern: "%(\\d+\\$)?([@dfs])")

            // Maps each argument position to the conversion it expects. Comparing counts alone
            // would let a translation swap `%@` for `%d`, which crashes `String(format:)` at
            // runtime; comparing the raw sequence would instead reject the reordering that
            // positional specifiers exist to allow, and that several locales here rely on.
            func specifierTypes(_ string: String) -> [Int: String] {
                var types: [Int: String] = [:]
                var nextImplicitPosition = 1
                for match in specifier.matches(in: string, range: NSRange(string.startIndex..., in: string)) {
                    guard let conversion = Range(match.range(at: 2), in: string) else { continue }
                    let position: Int
                    if let explicit = Range(match.range(at: 1), in: string),
                       let parsed = Int(string[explicit].dropLast()) {  // drops the trailing "$"
                        position = parsed
                    } else {
                        position = nextImplicitPosition
                        nextImplicitPosition += 1
                    }
                    types[position] = String(string[conversion])
                }
                return types
            }

            for locale in Self.locales.dropFirst() {
                let table = try Self.keys(in: locale)
                for (key, baseValue) in base {
                    guard let translated = table[key] else { continue }
                    #expect(specifierTypes(baseValue) == specifierTypes(translated),
                            "\(locale) \(key): \(baseValue) vs \(translated)")
                }
            }
        }

        @Test("Enum display names never leak a raw key")
        func displayNamesResolve() {
            for mode in LegMode.allCases {
                #expect(!mode.displayName.contains("leg_mode."))
                #expect(!mode.displayName.contains("transport_mode."))
            }
            for direction in RelativeDirection.allCases {
                #expect(!direction.displayName.contains("direction."))
            }
            for distance in WalkingDistance.allCases {
                #expect(!distance.title.contains("walking_distance."))
            }
        }
    }

    // MARK: - Fixtures

    private static func leg(mode: String) -> Leg {
        Leg(
            startTime: Date(),
            endTime: Date(),
            mode: mode,
            routeType: nil,
            routeColor: nil,
            routeTextColor: nil,
            route: nil,
            agencyName: nil,
            from: Place(name: "foo", lon: 47, lat: -122, vertexType: ""),
            to: Place(name: "bar", lon: 47, lat: -122, vertexType: ""),
            legGeometry: LegGeometry(points: "AA@@", length: 4),
            distance: 100,
            transitLeg: false,
            duration: 60,
            realTime: false,
            streetNames: nil,
            pathway: nil,
            steps: nil,
            headsign: nil,
            intermediateStops: nil
        )
    }

    private static func step(relativeDirection: String?) -> Step {
        Step(
            distance: 100,
            streetName: "Pine St",
            relativeDirection: relativeDirection,
            elevationChange: nil,
            lon: -122.0,
            lat: 47.0
        )
    }
}
