import SwiftUI

/// Invest view for discovering and executing investments
/// Browse funds, stocks, and investment opportunities
struct InvestView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Featured Section
                    featuredSection
                    
                    // Categories
                    categoriesSection
                    
                    // Popular Investments
                    popularSection
                    
                    // Watchlist
                    watchlistSection
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Invest")
            .searchable(text: $searchText, prompt: "Search investments")
        }
    }
    
    // MARK: - Featured Section
    
    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Featured")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    FeaturedCard(
                        title: "Sustainable Growth",
                        subtitle: "ESG-focused portfolio",
                        returnRate: "+12.4% YTD",
                        color: .green
                    )
                    FeaturedCard(
                        title: "Tech Leaders",
                        subtitle: "Top technology stocks",
                        returnRate: "+18.2% YTD",
                        color: .blue
                    )
                    FeaturedCard(
                        title: "Dividend Kings",
                        subtitle: "Reliable income",
                        returnRate: "+8.1% YTD",
                        color: .orange
                    )
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Categories Section
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                CategoryButton(icon: "chart.bar", title: "Stocks", count: 2450)
                CategoryButton(icon: "building.columns", title: "ETFs", count: 890)
                CategoryButton(icon: "doc.text", title: "Bonds", count: 340)
                CategoryButton(icon: "bitcoinsign.circle", title: "Crypto", count: 125)
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Popular Section
    
    private var popularSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Popular Today")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Spacer()
                
                Button("See All") {
                    // Navigate to full list
                }
                .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal)
            
            VStack(spacing: 0) {
                InvestmentRow(symbol: "AAPL", name: "Apple Inc.", price: "€178.52", change: "+1.2%", isPositive: true)
                Divider().padding(.leading, 60)
                InvestmentRow(symbol: "MSFT", name: "Microsoft", price: "€412.30", change: "+0.8%", isPositive: true)
                Divider().padding(.leading, 60)
                InvestmentRow(symbol: "GOOGL", name: "Alphabet", price: "€141.80", change: "-0.3%", isPositive: false)
                Divider().padding(.leading, 60)
                InvestmentRow(symbol: "AMZN", name: "Amazon", price: "€178.25", change: "+2.1%", isPositive: true)
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    // MARK: - Watchlist Section
    
    private var watchlistSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Watchlist")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Spacer()
                
                Button {
                    // Add to watchlist
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .medium))
                }
            }
            .padding(.horizontal)
            
            VStack(spacing: 0) {
                InvestmentRow(symbol: "NVDA", name: "NVIDIA", price: "€875.40", change: "+3.5%", isPositive: true)
                Divider().padding(.leading, 60)
                InvestmentRow(symbol: "TSLA", name: "Tesla", price: "€248.50", change: "-1.8%", isPositive: false)
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

// MARK: - Supporting Views

struct FeaturedCard: View {
    let title: String
    let subtitle: String
    let returnRate: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Text(returnRate)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.green)
        }
        .frame(width: 160)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

struct CategoryButton: View {
    let icon: String
    let title: String
    let count: Int
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.accentColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                
                Text("\(count) options")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct InvestmentRow: View {
    let symbol: String
    let name: String
    let price: String
    let change: String
    let isPositive: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Symbol badge
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 44, height: 44)
                
                Text(String(symbol.prefix(2)))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(symbol)
                    .font(.system(size: 15, weight: .semibold))
                
                Text(name)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(price)
                    .font(.system(size: 15, weight: .medium))
                
                Text(change)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isPositive ? .green : .red)
            }
        }
        .padding()
    }
}

#Preview("Invest View") {
    InvestView()
        .environmentObject(AppState())
}
