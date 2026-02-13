import Foundation

// MARK: - Bank Linking Step

/// Defines the steps in the bank linking flow
/// UX: Each step has a singular focus following foundation principles
enum BankLinkingStep: Int, CaseIterable {
    case bankSelection = 0
    case secureConnection = 1
    case accountSelection = 2
    
    var title: String {
        switch self {
        case .bankSelection:
            return "Choose Your Bank"
        case .secureConnection:
            return "Secure Connection"
        case .accountSelection:
            return "Select Accounts"
        }
    }
    
    var canGoBack: Bool {
        switch self {
        case .bankSelection:
            return false
        case .secureConnection:
            return false // Can't go back during OAuth
        case .accountSelection:
            return false // Can only cancel entirely
        }
    }
}

// MARK: - Bank Model

/// Represents a financial institution available for linking
struct Bank: Identifiable, Hashable {
    let id: String
    let name: String
    let logoName: String // SF Symbol or asset name
    let primaryColor: String // Hex color for branding
    let isPopular: Bool
    let oauthURL: URL?
    
    init(
        id: String = UUID().uuidString,
        name: String,
        logoName: String = "building.columns.fill",
        primaryColor: String = "#007AFF",
        isPopular: Bool = false,
        oauthURL: URL? = nil
    ) {
        self.id = id
        self.name = name
        self.logoName = logoName
        self.primaryColor = primaryColor
        self.isPopular = isPopular
        self.oauthURL = oauthURL
    }
    
    // Sample banks for demonstration
    static let sampleBanks: [Bank] = [
        Bank(
            id: "chase",
            name: "Chase",
            logoName: "building.columns.fill",
            primaryColor: "#117ACA",
            isPopular: true,
            oauthURL: URL(string: "https://secure.chase.com/oauth")
        ),
        Bank(
            id: "bofa",
            name: "Bank of America",
            logoName: "building.columns.fill",
            primaryColor: "#E31837",
            isPopular: true,
            oauthURL: URL(string: "https://secure.bankofamerica.com/oauth")
        ),
        Bank(
            id: "wells_fargo",
            name: "Wells Fargo",
            logoName: "building.columns.fill",
            primaryColor: "#D71E28",
            isPopular: true,
            oauthURL: URL(string: "https://connect.wellsfargo.com/oauth")
        ),
        Bank(
            id: "citi",
            name: "Citibank",
            logoName: "building.columns.fill",
            primaryColor: "#003B70",
            isPopular: true,
            oauthURL: URL(string: "https://online.citi.com/oauth")
        ),
        Bank(
            id: "usbank",
            name: "U.S. Bank",
            logoName: "building.columns.fill",
            primaryColor: "#0C2074",
            isPopular: true,
            oauthURL: URL(string: "https://onlinebanking.usbank.com/oauth")
        ),
        Bank(
            id: "capital_one",
            name: "Capital One",
            logoName: "building.columns.fill",
            primaryColor: "#D03027",
            isPopular: true,
            oauthURL: URL(string: "https://verified.capitalone.com/oauth")
        ),
        Bank(
            id: "pnc",
            name: "PNC Bank",
            logoName: "building.columns.fill",
            primaryColor: "#E87722",
            isPopular: false,
            oauthURL: URL(string: "https://www.pnc.com/oauth")
        ),
        Bank(
            id: "td",
            name: "TD Bank",
            logoName: "building.columns.fill",
            primaryColor: "#34A853",
            isPopular: false,
            oauthURL: URL(string: "https://onlinebanking.tdbank.com/oauth")
        ),
        Bank(
            id: "schwab",
            name: "Charles Schwab",
            logoName: "chart.line.uptrend.xyaxis",
            primaryColor: "#00A0DF",
            isPopular: false,
            oauthURL: URL(string: "https://client.schwab.com/oauth")
        ),
        Bank(
            id: "fidelity",
            name: "Fidelity",
            logoName: "chart.line.uptrend.xyaxis",
            primaryColor: "#4E8542",
            isPopular: false,
            oauthURL: URL(string: "https://digital.fidelity.com/oauth")
        ),
        Bank(
            id: "vanguard",
            name: "Vanguard",
            logoName: "chart.line.uptrend.xyaxis",
            primaryColor: "#C8102E",
            isPopular: false,
            oauthURL: URL(string: "https://investor.vanguard.com/oauth")
        ),
        Bank(
            id: "ally",
            name: "Ally Bank",
            logoName: "building.columns.fill",
            primaryColor: "#650360",
            isPopular: false,
            oauthURL: URL(string: "https://secure.ally.com/oauth")
        )
    ]
    
    static var popularBanks: [Bank] {
        sampleBanks.filter { $0.isPopular }
    }
}

// MARK: - Bank Account Model

/// Represents a bank account returned after successful OAuth
struct BankAccount: Identifiable, Hashable {
    let id: String
    let name: String
    let accountType: BankAccountType
    let maskedNumber: String // e.g., "••••4567"
    let availableBalance: Decimal?
    let currencyCode: String
    
    init(
        id: String = UUID().uuidString,
        name: String,
        accountType: BankAccountType,
        maskedNumber: String,
        availableBalance: Decimal? = nil,
        currencyCode: String = "USD"
    ) {
        self.id = id
        self.name = name
        self.accountType = accountType
        self.maskedNumber = maskedNumber
        self.availableBalance = availableBalance
        self.currencyCode = currencyCode
    }
    
    /// Formatted display for the masked account number
    var displayIdentifier: String {
        maskedNumber
    }
    
    /// Sample accounts for demonstration
    static func sampleAccounts(for bank: Bank) -> [BankAccount] {
        [
            BankAccount(
                name: "Primary Checking",
                accountType: .checking,
                maskedNumber: "••••4521",
                availableBalance: 12450.32
            ),
            BankAccount(
                name: "Savings Account",
                accountType: .savings,
                maskedNumber: "••••7832",
                availableBalance: 45230.00
            ),
            BankAccount(
                name: "Investment Portfolio",
                accountType: .investment,
                maskedNumber: "••••9104",
                availableBalance: 156789.45
            ),
            // Liability account example so added accounts can reduce overall balance.
            BankAccount(
                name: "Credit Card",
                accountType: .creditCard,
                maskedNumber: "••••1029",
                availableBalance: -3280.14
            )
        ]
    }
}

/// Types of bank accounts
enum BankAccountType: String, CaseIterable {
    case checking = "Checking"
    case savings = "Savings"
    case investment = "Investment"
    case creditCard = "Credit Card"
    case loan = "Loan"
    case retirement = "Retirement"
    
    var iconName: String {
        switch self {
        case .checking:
            return "creditcard.fill"
        case .savings:
            return "banknote.fill"
        case .investment:
            return "chart.line.uptrend.xyaxis"
        case .creditCard:
            return "creditcard.fill"
        case .loan:
            return "building.columns.fill"
        case .retirement:
            return "leaf.fill"
        }
    }
    
    var displayName: String {
        rawValue
    }
}

// MARK: - Connection State

/// Represents the state of the bank connection process
enum BankConnectionState: Equatable {
    case idle
    case connecting
    case awaitingCallback
    case processingCallback
    case success(accounts: [BankAccount])
    case failed(BankConnectionError)
    
    static func == (lhs: BankConnectionState, rhs: BankConnectionState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.connecting, .connecting),
             (.awaitingCallback, .awaitingCallback),
             (.processingCallback, .processingCallback):
            return true
        case (.success(let lhsAccounts), .success(let rhsAccounts)):
            return lhsAccounts == rhsAccounts
        case (.failed(let lhsError), .failed(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

/// Errors that can occur during bank connection
enum BankConnectionError: Error, Equatable {
    case networkTimeout
    case userCancelled
    case bankUnavailable
    case noAccountsFound
    case invalidCredentials
    case sessionExpired
    case unknown
    
    var title: String {
        switch self {
        case .networkTimeout:
            return "Connection Timed Out"
        case .userCancelled:
            return "Connection Cancelled"
        case .bankUnavailable:
            return "Bank Unavailable"
        case .noAccountsFound:
            return "No Accounts Found"
        case .invalidCredentials:
            return "Invalid Credentials"
        case .sessionExpired:
            return "Session Expired"
        case .unknown:
            return "Something Went Wrong"
        }
    }
    
    var message: String {
        switch self {
        case .networkTimeout:
            return "The bank is taking too long to respond. Please try again."
        case .userCancelled:
            return "You cancelled the connection process."
        case .bankUnavailable:
            return "This bank is temporarily unavailable. Please try again later."
        case .noAccountsFound:
            return "We couldn't find any eligible accounts with this bank."
        case .invalidCredentials:
            return "The bank couldn't verify your credentials. Please try again."
        case .sessionExpired:
            return "Your secure session has expired. Please start over."
        case .unknown:
            return "An unexpected error occurred. Please try again."
        }
    }
    
    var iconName: String {
        switch self {
        case .networkTimeout:
            return "wifi.exclamationmark"
        case .userCancelled:
            return "xmark.circle"
        case .bankUnavailable:
            return "building.columns.fill"
        case .noAccountsFound:
            return "folder.badge.questionmark"
        case .invalidCredentials:
            return "lock.shield"
        case .sessionExpired:
            return "clock.badge.exclamationmark"
        case .unknown:
            return "exclamationmark.triangle"
        }
    }
}

// MARK: - Link Request

/// Configuration for re-authentication scenarios
struct BankLinkRequest {
    let mode: LinkMode
    let existingAccountId: String?
    
    enum LinkMode {
        case newConnection
        case updateConnection
        case addMoreAccounts
    }
    
    static var newConnection: BankLinkRequest {
        BankLinkRequest(mode: .newConnection, existingAccountId: nil)
    }
    
    static func updateConnection(accountId: String) -> BankLinkRequest {
        BankLinkRequest(mode: .updateConnection, existingAccountId: accountId)
    }
}
