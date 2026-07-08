//
//  Created on 2026-02-10 by Pawel Jurczyk.
//
//  Copyright (c) 2026 Proton AG
//
//  Proton VPN is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton VPN is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton VPN.  If not, see <https://www.gnu.org/licenses/>.

import AppIntents
import Dependencies
import Localization
import Persistence

/// Custom app entity representing a state/province/region for VPN connections.
///
/// This entity conforms to the AppEntity protocol for use in parameterized intents.
/// It provides a list of available states/provinces within a selected country that users can connect to.
///
/// Compatible with:
/// - Shortcuts app (iOS 15+)
/// - Control Center (iOS 17+)
/// - Apple Intelligence (iOS 18+)
///
/// Note: Proton VPN locations do not have a matching schema in Apple's standard schema library,
/// so this remains a custom app entity. Future versions may adopt custom schemas when available.
public struct StateEntity: AppEntity, Identifiable {
    /// Unique identifier combining country code and state name
    public let id: String

    /// State/province name for display
    let name: String
    
    /// Country code for the state's location
    let countryCode: String

    /// Visual representation for display in pickers and dropdowns
    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: .init(stringLiteral: name))
    }

    /// Type display representation for Apple Intelligence
    public static let typeDisplayRepresentation: TypeDisplayRepresentation = "State"

    /// Default query provider for fetching state entities
    public static let defaultQuery = StateQuery()
}

/// Entity query for fetching available states from the server repository.
/// States are filtered based on the selected country from ConnectToRegionIntent.
public struct StateQuery: EntityQuery {
    /// Dependency on the country parameter from ConnectToRegionIntent
    @IntentParameterDependency<ConnectToRegionIntent>(\.country) var country

    public init() {}

    /// Provides suggested states based on the selected country
    public func suggestedEntities() async throws -> [StateEntity] {
        @Dependencies.Dependency(\.serverRepository) var repository

        let countryCode = country?.country.id
        let countries = repository
            .getGroups(
                filteredBy: [.isNotUnderMaintenance, .kind(.country(code: countryCode))],
                groupedBy: .stateName
            )

        let states = countries
            .compactMap { group in
                if case let .state(name, code) = group.kind {
                    return StateEntity(id: code + "_" + name, name: name, countryCode: code)
                }
                return nil
            }

        return states
    }

    /// Resolves state entities by their identifiers
    public func entities(for identifiers: [String]) async throws -> [StateEntity] {
        identifiers.map {
            let idParts = $0.components(separatedBy: "_")
            let code = idParts.first ?? ""
            let name = idParts.last ?? ""
            return StateEntity(id: $0, name: name, countryCode: code)
        }
    }
}
