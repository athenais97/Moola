import Foundation
import SwiftUI

/// A lightweight, deterministic demo data layer.
///
/// Goals (per product request):
/// - New users see a "live" feeling portfolio immediately after onboarding + profiling
/// - All totals, accounts, performance, and ranking are connected (single source of truth)
/// - Adding accounts contributes to overall balance (including potential drag from debt accounts)
///
/// Important: This is intentionally local-only (UserDefaults) and does not touch UI/layout.
final class DemoDataStore {
    static let shared = DemoDataStore()

    private init() {}

    private let schemaVersion: Int = 1
    private let bundleKeyPrefix = "demo_bundle_v1_"
    private let linkedAccountIdsKey = "linked_account_ids"

    // MARK: - Public API

    /// Ensures a seeded bundle exists for this user.
    /// Also ensures `linked_account_ids` is non-empty so the app unlocks the portfolio screens.
    func ensureSeededIfNeeded(for userKey: String) {
        let key = normalizedUserKey(userKey)
        if loadBundle(for: key) != nil {
            // Ensure linked accounts are set if bundle exists but link gate is empty.
            let linked = UserDefaults.standard.stringArray(forKey: linkedAccountIdsKey) ?? []
            if linked.isEmpty, let bundle = loadBundle(for: key) {
                UserDefaults.standard.set(bundle.accounts.map(\.stringId), forKey: linkedAccountIdsKey)
            }
            return
        }

        let now = Date()
        let seed = fnv1a64("seed|\(key)")

        // Seed with a mix of assets + at least one liability so the "overall balance"
        // can plausibly dip when users add debt accounts later.
        let institutions: [DemoInstitution] = [
            DemoInstitution(
                id: "chase_001",
                name: "Chase",
                logoName: "building.columns.fill",
                primaryColorHex: "#117ACA"
            ),
            DemoInstitution(
                id: "fidelity_001",
                name: "Fidelity",
                logoName: "chart.line.uptrend.xyaxis",
                primaryColorHex: "#4E8542"
            ),
            DemoInstitution(
                id: "amex_001",
                name: "American Express",
                logoName: "creditcard.fill",
                primaryColorHex: "#2E77BB"
            )
        ]

        let accounts: [DemoAccount] = [
            DemoAccount(
                stringId: "chase_checking",
                institutionId: institutions[0].id,
                institutionName: institutions[0].name,
                accountName: "Primary Checking",
                kind: .checking,
                maskedNumber: "••••4521",
                currentBalance: 12_450.32,
                currencyCode: "USD",
                createdAt: now.addingTimeInterval(-40 * 24 * 60 * 60) // ~40 days ago
            ),
            DemoAccount(
                stringId: "chase_savings",
                institutionId: institutions[0].id,
                institutionName: institutions[0].name,
                accountName: "High-Yield Savings",
                kind: .savings,
                maskedNumber: "••••7832",
                currentBalance: 45_230.00,
                currencyCode: "USD",
                createdAt: now.addingTimeInterval(-70 * 24 * 60 * 60)
            ),
            DemoAccount(
                stringId: "fidelity_investment",
                institutionId: institutions[1].id,
                institutionName: institutions[1].name,
                accountName: "Investment Portfolio",
                kind: .investment,
                maskedNumber: "••••9104",
                currentBalance: 156_789.45,
                currencyCode: "USD",
                createdAt: now.addingTimeInterval(-420 * 24 * 60 * 60)
            ),
            DemoAccount(
                stringId: "amex_gold",
                institutionId: institutions[2].id,
                institutionName: institutions[2].name,
                accountName: "Gold Card",
                kind: .creditCard,
                maskedNumber: "••••1029",
                currentBalance: -3_280.14,
                currencyCode: "USD",
                createdAt: now.addingTimeInterval(-180 * 24 * 60 * 60)
            )
        ]

        let bundle = DemoBundle(
            schemaVersion: schemaVersion,
            userKey: key,
            createdAt: now,
            baseSeed: seed,
            institutions: institutions,
            accounts: accounts
        )

        saveBundle(bundle)
        UserDefaults.standard.set(accounts.map(\.stringId), forKey: linkedAccountIdsKey)
    }

    func portfolioSummary(for userKey: String, now: Date = Date()) -> PortfolioSummary {
        let key = normalizedUserKey(userKey)
        guard let bundle = loadBundle(for: key) else {
            return .empty
        }

        let accounts = bundle.accounts.map { demoAccount -> PortfolioAccount in
            let uuid = stableUUID(userKey: key, accountStringId: demoAccount.stringId)
            return PortfolioAccount(
                id: uuid,
                institutionName: demoAccount.institutionName,
                accountName: demoAccount.accountName,
                accountType: demoAccount.kind.portfolioAccountType,
                balance: demoAccount.currentBalance,
                lastFourDigits: demoAccount.lastFourDigits,
                lastSyncDate: now.addingTimeInterval(-Double(minutesAgoSeeded(userKey: key, salt: demoAccount.stringId)) * 60),
                isActive: true,
                hasError: demoAccount.kind == .creditCard ? false : false
            )
        }

        let totalBalance = accounts.reduce(Decimal(0)) { $0 + $1.balance }
        let investedCapital = accounts
            .filter { $0.accountType == .investment || $0.accountType == .crypto }
            .reduce(Decimal(0)) { $0 + max(0, $1.balance) }

        // Balance history is the "week" portfolio performance series (connected to PerformanceView).
        let weekSummary = performanceSummary(for: key, timeframe: .week, accountId: nil, now: now)
        let balanceHistory = weekSummary.dataPoints.map { BalanceDataPoint(date: $0.date, value: $0.value) }

        let allocation = assetAllocation(from: accounts)

        let recentTransactions = generateRecentTransactions(
            userKey: key,
            accounts: accounts,
            now: now
        )

        return PortfolioSummary(
            totalBalance: totalBalance,
            investedCapital: investedCapital,
            lastSyncDate: now.addingTimeInterval(-1800),
            balanceHistory: balanceHistory,
            assetAllocation: allocation,
            accounts: accounts,
            recentTransactions: recentTransactions
        )
    }

    func synchronizedInstitutions(for userKey: String, now: Date = Date()) -> [SynchronizedInstitution] {
        let key = normalizedUserKey(userKey)
        guard let bundle = loadBundle(for: key) else { return [] }

        let accountsByInstitution = Dictionary(grouping: bundle.accounts, by: \.institutionId)

        return bundle.institutions.compactMap { inst in
            let instAccounts = (accountsByInstitution[inst.id] ?? []).map { acct in
                SynchronizedAccount(
                    id: acct.stringId,
                    name: acct.accountName,
                    accountType: acct.kind.syncedAccountType,
                    maskedNumber: acct.maskedNumber,
                    balance: acct.currentBalance,
                    currencyCode: acct.currencyCode,
                    isActive: true
                )
            }

            guard !instAccounts.isEmpty else { return nil }

            // Make 1 institution occasionally require attention (deterministic).
            let needsAttention = (fnv1a64("attention|\(key)|\(inst.id)") % 5) == 0

            return SynchronizedInstitution(
                id: inst.id,
                name: inst.name,
                logoName: inst.logoName,
                primaryColor: inst.primaryColorHex,
                accounts: instAccounts,
                connectionStatus: needsAttention ? .needsAttention : .active,
                lastSyncDate: now.addingTimeInterval(-Double(30 + Int(fnv1a64("sync|\(key)|\(inst.id)") % 90)) * 60),
                requiresReauthentication: needsAttention
            )
        }
    }

    func performanceSummary(
        for userKey: String,
        timeframe: PerformanceTimeframe,
        accountId: UUID?,
        now: Date = Date()
    ) -> PerformanceSummary {
        let key = normalizedUserKey(userKey)
        guard let bundle = loadBundle(for: key) else {
            return .empty
        }

        let scopedAccount: DemoAccount? = {
            guard let accountId else { return nil }
            return bundle.accounts.first(where: { stableUUID(userKey: key, accountStringId: $0.stringId) == accountId })
        }()

        let currentValue: Decimal = {
            if let scopedAccount {
                return scopedAccount.currentBalance
            }
            return bundle.accounts.reduce(Decimal(0)) { $0 + $1.currentBalance }
        }()

        let series = generateSeries(
            userKey: key,
            bundle: bundle,
            timeframe: timeframe,
            now: now,
            currentValue: currentValue,
            scope: scopedAccount?.stringId ?? "portfolio",
            kind: scopedAccount?.kind
        )

        let startValue = series.first?.value ?? 0
        let endValue = series.last?.value ?? 0

        let movers: [AccountPerformance] = {
            // Only compute movers for the full portfolio view.
            guard scopedAccount == nil else { return [] }
            return keyMovers(
                userKey: key,
                bundle: bundle,
                timeframe: timeframe,
                now: now,
                portfolioStart: startValue,
                portfolioEnd: endValue
            )
        }()

        return PerformanceSummary(
            timeframe: timeframe,
            startValue: startValue,
            endValue: endValue,
            dataPoints: series,
            keyMovers: movers
        )
    }

    func rankedAccounts(for userKey: String, timeframe: PerformanceTimeframe, now: Date = Date()) -> [RankedAccount] {
        let key = normalizedUserKey(userKey)
        guard let bundle = loadBundle(for: key) else { return [] }

        return bundle.accounts.map { acct in
            let uuid = stableUUID(userKey: key, accountStringId: acct.stringId)
            let series = performanceSummary(for: key, timeframe: timeframe, accountId: uuid, now: now).dataPoints
            let start = series.first?.value ?? acct.currentBalance
            let end = series.last?.value ?? acct.currentBalance
            let gain = end - start
            let pct: Decimal = start != 0 ? (gain / start) * 100 : 0

            let inst = bundle.institutions.first(where: { $0.id == acct.institutionId })
            let brandColor = Color(hex: inst?.primaryColorHex ?? "#777777") ?? .gray

            // Ranking screen expects a compact "balanceHistory" series.
            let history = series.map(\.value)
            let historyDecimals = history.isEmpty ? [start, end] : history

            return RankedAccount(
                id: acct.stringId,
                accountName: acct.accountName,
                institutionName: acct.institutionName,
                institutionLogoName: inst?.logoName ?? "building.columns.fill",
                brandColor: brandColor,
                currentBalance: end,
                previousBalance: start,
                absoluteGain: gain,
                percentageGain: pct,
                balanceHistory: historyDecimals,
                hasInsufficientData: false
            )
        }
    }

    /// Called when the user links accounts via Bank Linking.
    /// This persists the accounts so all other screens can reflect the newly added balances/performance.
    func upsertLinkedAccounts(userKey: String, bank: Bank, accounts: [BankAccount]) {
        let key = normalizedUserKey(userKey)
        ensureSeededIfNeeded(for: key)
        guard var bundle = loadBundle(for: key) else { return }

        // Institution upsert.
        let institutionId = "\(bank.id)_\(abs(bank.id.hashValue) % 1000)"
        if !bundle.institutions.contains(where: { $0.id == institutionId }) {
            bundle.institutions.append(
                DemoInstitution(
                    id: institutionId,
                    name: bank.name,
                    logoName: bank.logoName,
                    primaryColorHex: bank.primaryColor
                )
            )
        }

        // Account upsert.
        for acct in accounts {
            if bundle.accounts.contains(where: { $0.stringId == acct.id }) {
                continue
            }

            let kind = DemoAccountKind(from: acct.accountType)
            let balance = acct.availableBalance ?? seededBalance(userKey: key, salt: acct.id, kind: kind)

            bundle.accounts.append(
                DemoAccount(
                    stringId: acct.id,
                    institutionId: institutionId,
                    institutionName: bank.name,
                    accountName: acct.name,
                    kind: kind,
                    maskedNumber: acct.maskedNumber,
                    currentBalance: balance,
                    currencyCode: acct.currencyCode,
                    createdAt: Date()
                )
            )
        }

        saveBundle(bundle)

        // Update the app gate for "linked accounts".
        let existingLinked = UserDefaults.standard.stringArray(forKey: linkedAccountIdsKey) ?? []
        let merged = Array(Set(existingLinked + bundle.accounts.map(\.stringId)))
        UserDefaults.standard.set(merged, forKey: linkedAccountIdsKey)
    }

    // MARK: - Helpers (user identity)

    /// Reads the stored user's email (if present) so view models can resolve demo data without UI injection.
    func currentUserKeyFromStoredUser() -> String? {
        // Mirrors AuthenticationService's persistence key.
        let userDefaultsKey = "stored_user"
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let codable = try? JSONDecoder().decode(CodableUserForDemo.self, from: data) else {
            return nil
        }
        return codable.email
    }
}

// MARK: - Codable bundle (local persistence)

private struct DemoBundle: Codable {
    var schemaVersion: Int
    var userKey: String
    var createdAt: Date
    var baseSeed: UInt64
    var institutions: [DemoInstitution]
    var accounts: [DemoAccount]
}

private struct DemoInstitution: Codable {
    var id: String
    var name: String
    var logoName: String
    var primaryColorHex: String
}

private struct DemoAccount: Codable {
    var stringId: String
    var institutionId: String
    var institutionName: String
    var accountName: String
    var kind: DemoAccountKind
    var maskedNumber: String
    var currentBalance: Decimal
    var currencyCode: String
    var createdAt: Date

    var lastFourDigits: String {
        let digits = maskedNumber.replacingOccurrences(of: "•", with: "")
        if digits.count >= 4 {
            return String(digits.suffix(4))
        }
        // Some account types may not have digits (e.g. wallets).
        return maskedNumber == "••••" ? "••••" : ""
    }
}

private enum DemoAccountKind: String, Codable {
    case checking
    case savings
    case investment
    case retirement
    case crypto
    case creditCard
    case loan

    init(from type: BankAccountType) {
        switch type {
        case .checking: self = .checking
        case .savings: self = .savings
        case .investment: self = .investment
        case .creditCard: self = .creditCard
        case .loan: self = .loan
        case .retirement: self = .retirement
        }
    }

    var portfolioAccountType: PortfolioAccountType {
        switch self {
        case .checking: return .checking
        case .savings: return .savings
        case .investment, .retirement: return .investment
        case .crypto: return .crypto
        case .creditCard: return .creditCard
        case .loan: return .loan
        }
    }

    var syncedAccountType: SyncedAccountType {
        switch self {
        case .checking: return .checking
        case .savings: return .savings
        case .investment: return .investment
        case .retirement: return .retirement
        case .crypto: return .crypto
        case .creditCard: return .creditCard
        case .loan: return .loan
        }
    }
}

// MARK: - Persistence IO

private extension DemoDataStore {
    func normalizedUserKey(_ userKey: String) -> String {
        userKey.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    func bundleStorageKey(for userKey: String) -> String {
        bundleKeyPrefix + normalizedUserKey(userKey)
    }

    func loadBundle(for userKey: String) -> DemoBundle? {
        let key = bundleStorageKey(for: userKey)
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(DemoBundle.self, from: data)
    }

    func saveBundle(_ bundle: DemoBundle) {
        let key = bundleStorageKey(for: bundle.userKey)
        if let data = try? JSONEncoder().encode(bundle) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

// MARK: - Portfolio helpers

private extension DemoDataStore {
    func assetAllocation(from accounts: [PortfolioAccount]) -> AssetAllocation {
        var cash: Decimal = 0
        var stocks: Decimal = 0
        var crypto: Decimal = 0
        var other: Decimal = 0

        for account in accounts {
            let amount = account.balance
            switch account.accountType.assetCategory {
            case .cash: cash += amount
            case .stocks: stocks += amount
            case .crypto: crypto += amount
            case .other: other += amount
            }
        }

        return AssetAllocation(cash: cash, stocks: stocks, crypto: crypto, other: other)
    }

    func generateRecentTransactions(userKey: String, accounts: [PortfolioAccount], now: Date) -> [Transaction] {
        guard !accounts.isEmpty else { return [] }
        let calendar = Calendar.current

        // Deterministic selection for "alive" feel without changing on every refresh.
        var rng = SeededRNG(seed: fnv1a64("tx|\(userKey)|\(calendar.component(.day, from: now))"))

        let merchants = [
            ("Apple Inc.", TransactionCategory.investment),
            ("Whole Foods Market", .groceries),
            ("Monthly Salary", .income),
            ("Uber", .transport),
            ("Netflix", .utilities),
            ("Starbucks", .dining)
        ]

        let txCount = 6
        return (0..<txCount).map { idx in
            let (title, category) = merchants[Int(rng.nextUInt64() % UInt64(merchants.count))]
            let account = accounts[Int(rng.nextUInt64() % UInt64(accounts.count))]

            let isCredit = category == .income || category == .investment
            let base = rng.nextDouble(in: 12...420)
            let signed = isCredit ? base : -base

            let date = calendar.date(byAdding: .day, value: -Int(rng.nextUInt64() % 4), to: now) ?? now

            return Transaction(
                id: UUID(),
                title: title,
                category: category,
                amount: Decimal(signed),
                date: date,
                accountName: "\(account.institutionName) \(account.accountName)",
                isPending: idx == 0 && !isCredit
            )
        }
        .sorted { $0.date > $1.date }
    }
}

// MARK: - Performance generation (connected, deterministic)

private extension DemoDataStore {
    func generateSeries(
        userKey: String,
        bundle: DemoBundle,
        timeframe: PerformanceTimeframe,
        now: Date,
        currentValue: Decimal,
        scope: String,
        kind: DemoAccountKind?
    ) -> [PerformanceDataPoint] {
        let calendar = Calendar.current

        let (component, count): (Calendar.Component, Int) = {
            switch timeframe {
            case .day: return (.hour, 24)
            case .week: return (.day, 7)
            case .month: return (.day, 30)
            case .year: return (.weekOfYear, 52)
            case .all: return (.month, 36)
            }
        }()

        // Make it feel "alive" but stable: seed includes a time bucket so it changes slowly.
        let timeBucket: Int = {
            switch timeframe {
            case .day:
                return calendar.component(.hour, from: now)
            case .week, .month:
                return calendar.component(.day, from: now)
            case .year, .all:
                return calendar.component(.month, from: now)
            }
        }()

        var rng = SeededRNG(seed: fnv1a64("perf|\(userKey)|\(scope)|\(timeframe.rawValue)|\(timeBucket)"))

        // Volatility tuned by timeframe; slightly modulated by account kind.
        let baseVol: Double = {
            switch timeframe {
            case .day: return 0.002
            case .week: return 0.008
            case .month: return 0.010
            case .year: return 0.020
            case .all: return 0.028
            }
        }()

        let kindMultiplier: Double = {
            switch kind {
            case .investment: return 1.25
            case .crypto: return 1.60
            case .creditCard, .loan: return 0.55
            case .checking, .savings: return 0.35
            case .retirement: return 0.90
            case .none: return 1.0 // portfolio
            }
        }()

        // Drift can be negative to create "down" portfolios for some users.
        let drift: Double = {
            let raw = (rng.nextDouble(in: -0.9...1.1)) * 0.0006
            // Debt accounts tend to "worsen" slightly (more negative) in short horizons.
            if kind == .creditCard || kind == .loan {
                return raw - 0.0003
            }
            return raw
        }()

        // Generate backwards from "now" so endValue always matches current balance.
        var pointsBackwards: [PerformanceDataPoint] = []
        var value = NSDecimalNumber(decimal: currentValue).doubleValue

        for i in 0..<count {
            // Apply a step backward: invert a plausible forward move.
            let shock = rng.nextDouble(in: -1.05...1.20)
            let step = value * (baseVol * kindMultiplier) * shock
            let meanRevert = value * drift
            value = max(0, value - step - meanRevert)

            let date = calendar.date(byAdding: component, value: -i, to: now) ?? now

            // Keep the visual "data gap" demo on monthly charts.
            let isInterpolated = timeframe == .month && (i == 12 || i == 13 || i == 14)

            pointsBackwards.append(
                PerformanceDataPoint(
                    date: date,
                    value: Decimal(value),
                    isInterpolated: isInterpolated
                )
            )
        }

        // Reverse so oldest -> newest.
        return pointsBackwards.reversed()
    }

    func keyMovers(
        userKey: String,
        bundle: DemoBundle,
        timeframe: PerformanceTimeframe,
        now: Date,
        portfolioStart: Decimal,
        portfolioEnd: Decimal
    ) -> [AccountPerformance] {
        let totalChange = portfolioEnd - portfolioStart
        let totalAbs = absDecimal(totalChange)
        guard totalAbs > 0 else { return [] }

        let perAccount: [(DemoAccount, Decimal)] = bundle.accounts.map { acct in
            let uuid = stableUUID(userKey: userKey, accountStringId: acct.stringId)
            let series = performanceSummary(for: userKey, timeframe: timeframe, accountId: uuid, now: now)
            let change = series.endValue - series.startValue
            return (acct, change)
        }

        let sorted = perAccount.sorted { absDecimal($0.1) > absDecimal($1.1) }.prefix(3)

        return sorted.map { acct, change in
            let pct = (absDecimal(change) / totalAbs) * 100
            return AccountPerformance(
                accountName: acct.accountName,
                institutionName: acct.institutionName,
                accountType: acct.kind.portfolioAccountType,
                contribution: change,
                percentageOfTotal: pct,
                isPositive: change >= 0
            )
        }
    }
}

// MARK: - Deterministic utilities

private extension DemoDataStore {
    func stableUUID(userKey: String, accountStringId: String) -> UUID {
        // Build 16 bytes from two independent 64-bit hashes.
        let h1 = fnv1a64("uuidA|\(userKey)|\(accountStringId)")
        let h2 = fnv1a64("uuidB|\(userKey)|\(accountStringId)")

        var bytes: [UInt8] = []
        bytes.reserveCapacity(16)
        bytes.append(contentsOf: withUnsafeBytes(of: h1.bigEndian, Array.init))
        bytes.append(contentsOf: withUnsafeBytes(of: h2.bigEndian, Array.init))

        // Set version (4) and variant bits for a well-formed UUID.
        bytes[6] = (bytes[6] & 0x0F) | 0x40
        bytes[8] = (bytes[8] & 0x3F) | 0x80

        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5],
            bytes[6], bytes[7],
            bytes[8], bytes[9],
            bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }

    func minutesAgoSeeded(userKey: String, salt: String) -> Int {
        20 + Int(fnv1a64("mins|\(userKey)|\(salt)") % 160) // 20...179
    }

    func seededBalance(userKey: String, salt: String, kind: DemoAccountKind) -> Decimal {
        var rng = SeededRNG(seed: fnv1a64("bal|\(userKey)|\(salt)|\(kind.rawValue)"))
        switch kind {
        case .checking:
            return Decimal(rng.nextDouble(in: 800...18_500))
        case .savings:
            return Decimal(rng.nextDouble(in: 2_000...85_000))
        case .investment, .retirement:
            return Decimal(rng.nextDouble(in: 8_000...240_000))
        case .crypto:
            return Decimal(rng.nextDouble(in: 500...40_000))
        case .creditCard:
            return Decimal(-rng.nextDouble(in: 200...9_500))
        case .loan:
            return Decimal(-rng.nextDouble(in: 5_000...120_000))
        }
    }

    func absDecimal(_ value: Decimal) -> Decimal {
        value < 0 ? -value : value
    }

    /// FNV-1a 64-bit hash for stable, fast deterministic seeds.
    func fnv1a64(_ input: String) -> UInt64 {
        var hash: UInt64 = 1469598103934665603
        for b in input.utf8 {
            hash ^= UInt64(b)
            hash = hash &* 1099511628211
        }
        return hash
    }
}

private struct SeededRNG {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }

    mutating func nextUInt64() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1
        return state
    }

    mutating func nextDouble(in range: ClosedRange<Double>) -> Double {
        let unit = Double(nextUInt64()) / Double(UInt64.max)
        return range.lowerBound + unit * (range.upperBound - range.lowerBound)
    }
}

/// Minimal stored-user decoder (we only need the email).
private struct CodableUserForDemo: Codable {
    let email: String
}

