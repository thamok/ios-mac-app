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
import Connection
import Dependencies
import Domain
import Localization
import Persistence
import Sharing
import SwiftUI

/// Custom app intent for connecting to a specific VPN region.
///
/// This intent allows connecting to Proton VPN by specifying a country, state, or city.
/// The user can select their preferred region through the parameterized interface.
///
/// Compatible with:
/// - Shortcuts app (iOS 15+)
/// - Control Center (iOS 17+)
/// - Apple Intelligence (iOS 18+)
///
/// Note: Proton VPN does not have a matching schema in Apple's standard schema library,
/// so this remains a custom app intent. Future versions may adopt custom schemas when available.
public struct ConnectToRegionIntent: AppIntent {
    public static let title: LocalizedStringResource = "Connect to Region"
    static let description = IntentDescription(
        "This intent allows to connect to a selected country, city or state",
        resultValueName: "connected"
    )

    /// The country to connect to
    @Parameter(title: "country", requestValueDialog: "Which country?")
    public var country: CountryEntity?
    
    /// Specifies whether to connect to a city, state, or fastest server
    @Parameter(title: "region", default: .any)
    var specifyRegion: RegionType
    
    /// The city to connect to (used when specifyRegion is .city)
    @Parameter(title: "city", requestValueDialog: "Which city?")
    public var city: CityEntity?
    
    /// The state to connect to (used when specifyRegion is .state)
    @Parameter(title: "state", requestValueDialog: "Which state?")
    public var state: StateEntity?
    
    /// Skip reconnecting if already connected to the target region
    @Parameter(title: "Skip if already connected", default: true)
    public var skipReconnect: Bool // TODO: Actually implement this

    public static let openAppWhenRun: Bool = true

    public init() {}

    enum RegionType: String, AppEnum {
        case city
        case state
        case any

        public static let typeDisplayRepresentation: TypeDisplayRepresentation = "RegionType"

        public static let caseDisplayRepresentations: [RegionType: DisplayRepresentation] = [
            .city: "city",
            .state: "state",
            .any: "fastest server",
        ]
    }

    @MainActor
    public func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        // First see if city, state, or country is specified, if yes, connect to that.
        if let simpleSpec = specForSelection() {
            let value = try await ConnectToVPNWithParametersIntent(connectionSpec: simpleSpec, skipReconnect: skipReconnect).perform().value ?? false
            return .result(value: value)
        }
        let value = try await ConnectToVPNWithParametersIntent().perform().value ?? false
        return .result(value: value)
    }

    private func specForSelection() -> ConnectionSpec? {
        if let city {
            ConnectionSpec(location: .city(name: city.name, code: city.countryCode, order: .fastest), features: [])
        } else if let state {
            ConnectionSpec(location: .state(name: state.name, code: state.countryCode, order: .fastest), features: [])
        } else if let code = country?.id {
            ConnectionSpec(location: .country(code: code, order: .fastest), features: [])
        } else {
            nil
        }
    }

    public static var parameterSummary: some ParameterSummary {
        Switch(\.$specifyRegion) {
            Case(.city) {
                Summary("Connect to \(\.$city) \(\.$specifyRegion) in \(\.$country)") {
                    \.$skipReconnect
                }
            }
            Case(.state) {
                Summary("Connect to \(\.$state) \(\.$specifyRegion) in \(\.$country)") {
                    \.$skipReconnect
                }
            }
            DefaultCase {
                Summary("Connect to \(\.$specifyRegion) in \(\.$country)") {
                    \.$skipReconnect
                }
            }
        }
    }
}
