/*
 * Copyright (C) Open Transit Software Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy at:
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for specific language governing permissions and
 * limitations under the License.
 */

import Foundation
import OSLog

// Internal wire types for the OTP 2.x GTFS GraphQL API `plan` query, plus the
// mapping that converts them into the public models shared with the REST path.

struct GraphQLResponseEnvelope: Decodable {
    let data: GraphQLPlanData?
    let errors: [GraphQLErrorMessage]?
}

struct GraphQLErrorMessage: Decodable {
    let message: String
}

struct GraphQLPlanData: Decodable {
    let plan: GraphQLPlan?
}

struct GraphQLPlan: Decodable {
    let date: Date
    let from: GraphQLPlace
    let to: GraphQLPlace
    let routingErrors: [GraphQLRoutingError]
    let itineraries: [GraphQLItinerary]
}

struct GraphQLRoutingError: Decodable {
    let code: String
    let description: String
}

struct GraphQLItinerary: Decodable {
    let duration: Int
    let startTime: Date
    let endTime: Date
    let walkTime: Int
    let waitingTime: Int
    let walkDistance: Double?
    let elevationLost: Double?
    let elevationGained: Double?
    let numberOfTransfers: Int
    let legs: [GraphQLLeg]
}

struct GraphQLLeg: Decodable {
    let startTime: Date
    let endTime: Date
    let mode: String
    let route: GraphQLRoute?
    let from: GraphQLPlace
    let to: GraphQLPlace
    let legGeometry: GraphQLLegGeometry?
    let distance: Double
    let transitLeg: Bool?
    let duration: Double
    let realTime: Bool?
    let headsign: String?
    let intermediatePlaces: [GraphQLPlace]?
    let steps: [GraphQLStep]?
}

struct GraphQLRoute: Decodable {
    let shortName: String?
    let type: Int?
    let color: String?
    let textColor: String?
    let agency: GraphQLAgency?
}

struct GraphQLAgency: Decodable {
    let name: String
}

struct GraphQLPlace: Decodable {
    let name: String?
    let lon: Double
    let lat: Double
    let vertexType: String?
    let stop: GraphQLStop?
}

struct GraphQLStop: Decodable {
    let gtfsId: String?
    let code: String?
}

struct GraphQLLegGeometry: Decodable {
    let points: String?
    let length: Int?
}

struct GraphQLStep: Decodable {
    let distance: Double
    let streetName: String?
    let relativeDirection: String?
    let lon: Double
    let lat: Double
}

// MARK: - Mapping to public models

extension GraphQLPlan {
    func toPlan() -> Plan {
        Plan(
            date: date,
            from: from.toPlace(),
            to: to.toPlace(),
            itineraries: itineraries.map { $0.toItinerary() }
        )
    }

    /// Maps the first actionable routing error to the REST-style `ErrorResponse`, or nil
    /// when itineraries were found. `WALKING_BETTER_THAN_TRANSIT` is advisory, not a failure.
    func toErrorResponse() -> ErrorResponse? {
        guard
            itineraries.isEmpty,
            let routingError = routingErrors.first(where: { $0.code != "WALKING_BETTER_THAN_TRANSIT" })
        else {
            return nil
        }

        return routingError.toErrorResponse()
    }
}

extension GraphQLRoutingError {
    func toErrorResponse() -> ErrorResponse {
        let messageCode: ErrorResponseCode

        switch code {
        case "OUTSIDE_BOUNDS":
            messageCode = .outsideBounds
        case "NO_TRANSIT_CONNECTION", "NO_DIRECT_MODE_CONNECTION":
            messageCode = .pathNotFound
        case "NO_TRANSIT_CONNECTION_IN_SEARCH_WINDOW", "OUTSIDE_SERVICE_PERIOD":
            messageCode = .noTransitTimes
        case "LOCATION_NOT_FOUND", "NO_STOPS_IN_RANGE":
            messageCode = .locationNotAccessible
        default:
            Logger.main.warning("Unrecognized OTP routing error code: \(code)")
            messageCode = .unknown
        }

        // `id` is an OTP 1.x REST wire field with no GraphQL equivalent; consumers key off messageCode.
        return ErrorResponse(id: -1, message: description, messageCode: messageCode)
    }
}

extension GraphQLItinerary {
    func toItinerary() -> Itinerary {
        Itinerary(
            duration: duration,
            startTime: startTime,
            endTime: endTime,
            walkTime: walkTime,
            transitTime: max(0, duration - walkTime - waitingTime),
            waitingTime: waitingTime,
            walkDistance: walkDistance ?? 0,
            walkLimitExceeded: false,
            elevationLost: elevationLost ?? 0,
            elevationGained: elevationGained ?? 0,
            transfers: numberOfTransfers,
            legs: legs.map { $0.toLeg() }
        )
    }
}

extension GraphQLLeg {
    func toLeg() -> Leg {
        Leg(
            startTime: startTime,
            endTime: endTime,
            mode: mode,
            routeType: route?.type.flatMap { RouteType(rawValue: $0) },
            routeColor: route?.color,
            routeTextColor: route?.textColor,
            route: route?.shortName,
            agencyName: route?.agency?.name,
            from: from.toPlace(),
            to: to.toPlace(),
            legGeometry: LegGeometry(points: legGeometry?.points ?? "", length: legGeometry?.length ?? 0),
            distance: distance,
            transitLeg: transitLeg,
            duration: Int(duration.rounded()),
            realTime: realTime,
            streetNames: nil,
            pathway: nil,
            steps: steps?.map { $0.toStep() },
            headsign: headsign,
            intermediateStops: intermediatePlaces?.map { $0.toPlace() }
        )
    }
}

extension GraphQLPlace {
    func toPlace() -> Place {
        Place(
            name: name ?? "",
            lon: lon,
            lat: lat,
            vertexType: vertexType ?? "NORMAL",
            stopId: stop?.gtfsId,
            stopCode: stop?.code
        )
    }
}

extension GraphQLStep {
    func toStep() -> Step {
        Step(
            distance: distance,
            streetName: streetName ?? "",
            relativeDirection: relativeDirection,
            elevationChange: nil,
            lon: lon,
            lat: lat
        )
    }
}
