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

/// Custom app entity representing a city/location for VPN connections.
///
/// This entity conforms to the AppEntity protocol for use in parameterized intents.
/// It provides a list of available cities within a selected country that users can connect to.
///
/// Compatible with:
/// - Shortcuts app (iOS 15+)
/// - Control Center (iOS 17+)
/// - Apple Intelligence (iOS 18+)
///
/// Note: Proton VPN locations do not have a matching schema in Apple's standard schema library,
/// so this remains a custom app entity. Future versions may adopt custom schemas when available.
public struct CityEntity: AppEntity, Identifiable {
    /// Unique identifier combining country code and city name
    public let id: String
    
    /// City name for display
    let name: String
    
    /// Country code for the city's location
    let countryCode: String

    /// Visual representation for display in pickers and dropdowns
    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: .init(stringLiteral: name))
    }

    /// Type display representation for Apple Intelligence
    public static let typeDisplayRepresentation: TypeDisplayRepresentation = "City"

    /// Default query provider for fetching city entities
    public static let defaultQuery = CityQuery()
}

/// Entity query for fetching available cities from the server repository.
/// Cities are filtered based on the selected country from ConnectToRegionIntent.
public struct CityQuery: EntityQuery {
    /// Dependency on the country parameter from ConnectToRegionIntent
    @IntentParameterDependency<ConnectToRegionIntent>(\.$country) var country

    public init() {}

    /// Provides suggested cities based on the selected country
    public func suggestedEntities() async throws -> [CityEntity] {
        @Dependencies.Dependency(\.serverRepository) var repository

        let countryCode = country?.country.id
        let countries = repository
            .getGroups(
                filteredBy: [.isNotUnderMaintenance, .kind(.country(code: countryCode))],
                groupedBy: .cityName
            )

        let cities = countries
            .compactMap { group in
                if case let .city(name, code) = group.kind {
                    return CityEntity(id: code + "_" + name, name: name, countryCode: code)
                }
                return nil
            }

        return cities
    }

    /// Resolves city entities by their identifiers
    public func entities(for identifiers: [String]) async throws -> [CityEntity] {
        identifiers.map {
            let idParts = $0.components(separatedBy: "_")
            let code = idParts.first ?? ""
            let name = idParts.last ?? ""
            return CityEntity(id: $0, name: name, countryCode: code)
        }
    }
}
