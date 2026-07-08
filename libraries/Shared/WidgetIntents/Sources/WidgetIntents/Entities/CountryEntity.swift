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

/// Custom app entity representing a country/location for VPN connections.
///
/// This entity conforms to the AppEntity protocol for use in parameterized intents.
/// It provides a list of available countries that users can connect to via Proton VPN.
///
/// Compatible with:
/// - Shortcuts app (iOS 15+)
/// - Control Center (iOS 17+)
/// - Apple Intelligence (iOS 18+)
///
/// Note: Proton VPN locations do not have a matching schema in Apple's standard schema library,
/// so this remains a custom app entity. Future versions may adopt custom schemas when available.
public struct CountryEntity: AppEntity, Identifiable {
    /// Unique country code identifier
    public let id: String

    /// Localized country name for display
    let name: String

    /// Visual representation for display in pickers and dropdowns
    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: .init(stringLiteral: name))
    }

    /// Type display representation for Apple Intelligence
    public static let typeDisplayRepresentation: TypeDisplayRepresentation = "Country"

    /// Default query provider for fetching country entities
    public static let defaultQuery = CountriesQuery()
}

/// Entity query for fetching available countries from the server repository.
public struct CountriesQuery: EntityQuery {
    public init() {}

    /// Provides suggested countries based on server availability
    public func suggestedEntities() async throws -> [CountryEntity] {
        @Dependencies.Dependency(\.serverRepository) var repository

        let countries = repository
            .getGroups(
                filteredBy: [.isNotUnderMaintenance, .kind(.country)],
                groupedBy: .serverType
            )

        return countries
            .compactMap { group in
                if case let .country(code) = group.kind,
                   let translatedCountryName = LocalizationUtility.default.countryName(forCode: code) {
                    return CountryEntity(id: code, name: translatedCountryName)
                }
                return nil
            }
    }

    /// Resolves country entities by their identifiers
    public func entities(for identifiers: [String]) async throws -> [CountryEntity] {
        identifiers.compactMap {
            if let translatedCountryName = LocalizationUtility.default.countryName(forCode: $0) {
                return CountryEntity(id: $0, name: translatedCountryName)
            }
            return nil
        }
    }
}
