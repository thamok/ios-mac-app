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

/// Custom app intent for initiating user login.
///
/// This intent opens the Proton VPN app and triggers the login flow.
/// Compatible with:
/// - Shortcuts app (iOS 15+)
/// - Control Center (iOS 17+)
/// - Apple Intelligence (iOS 18+)
///
/// Note: Proton VPN does not have a matching schema in Apple's standard schema library,
/// so this remains a custom app intent. Future versions may adopt custom schemas when available.
public struct LoginIntent: AppIntent {
    public static let title: LocalizedStringResource = "Login"
    public static let openAppWhenRun = true
    public static let isDiscoverable = false

    public init() {}

    public func perform() async throws -> some IntentResult {
        .result()
    }
}
