import SwiftUI

struct SubscriptionView: View {
    @EnvironmentObject var wardrobeManager: WardrobeManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var showingUpgradeSheet = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Current Plan
                    currentPlanCard

                    // Usage Statistics
                    usageStatistics

                    // Available Plans
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Available Plans")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        ForEach([SubscriptionTier.free, .basic, .premium, .unlimited], id: \.self) { tier in
                            SubscriptionTierCard(
                                tier: tier,
                                isCurrentTier: tier == subscriptionManager.currentTier,
                                onSelect: {
                                    if tier != subscriptionManager.currentTier {
                                        subscriptionManager.upgradeTier(to: tier)
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var currentPlanCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Plan")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(subscriptionManager.currentTier.displayName)
                        .font(.title)
                        .fontWeight(.bold)
                }

                Spacer()

                Image(systemName: "star.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.yellow)
            }

            if subscriptionManager.currentTier != .unlimited {
                Button("Upgrade Plan") {
                    showingUpgradeSheet = true
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var usageStatistics: some View {
        VStack(spacing: 16) {
            Text("Usage")
                .font(.headline)

            HStack(spacing: 20) {
                UsageCard(
                    title: "Items",
                    current: wardrobeManager.totalItems,
                    maximum: subscriptionManager.currentTier.maxItems,
                    icon: "tshirt.fill"
                )

                UsageCard(
                    title: "Looks",
                    current: wardrobeManager.totalOutfits,
                    maximum: subscriptionManager.currentTier.maxOutfits,
                    icon: "sparkles"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct UsageCard: View {
    let title: String
    let current: Int
    let maximum: Int
    let icon: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.blue)

            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if maximum == Int.max {
                    Text("\(current) / ∞")
                        .font(.title3)
                        .fontWeight(.semibold)
                } else {
                    Text("\(current) / \(maximum)")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }

            if maximum != Int.max {
                ProgressView(value: Double(current), total: Double(maximum))
                    .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    private var progressColor: Color {
        let percentage = Double(current) / Double(maximum)
        if percentage >= 0.9 {
            return .red
        } else if percentage >= 0.7 {
            return .orange
        } else {
            return .green
        }
    }
}

struct SubscriptionTierCard: View {
    let tier: SubscriptionTier
    let isCurrentTier: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tier.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text(tier.price)
                            .font(.headline)
                            .foregroundColor(.blue)
                    }

                    Spacer()

                    if isCurrentTier {
                        Text("Current")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(tier.features, id: \.self) { feature in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)

                            Text(feature)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }
                }

                if !isCurrentTier {
                    HStack {
                        Spacer()
                        Text(tier == .free ? "Downgrade" : "Select Plan")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .background(isCurrentTier ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isCurrentTier ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
}

#Preview {
    SubscriptionView()
        .environmentObject(WardrobeManager())
        .environmentObject(SubscriptionManager())
}
