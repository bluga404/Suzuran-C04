import SwiftUI

struct InsightResultView: View {
    let insight: InsightResponse
    let counts: [String: Int]
    
    var body: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(Theme.accent)
                    Text("AI Analysis")
                        .font(.system(.title3, design: .rounded).bold())
                        .foregroundColor(.white)
                }
                
                Divider().background(Color.white.opacity(0.3))
                
                if !counts.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CoreML Detection")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                        let countsText = counts.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
                        Text(countsText.isEmpty ? "No issues detected" : countsText)
                            .font(.system(.footnote, design: .rounded).bold())
                            .foregroundColor(.white)
                    }
                }
                
                insightSection(icon: "chart.line.uptrend.xyaxis", title: "Trend", content: insight.trendSummary)
                insightSection(icon: "flask", title: "Ingredients", content: insight.ingredientInsight)
                
                HStack(alignment: .top, spacing: 12) {
                    recommendationBox(icon: "plus.circle.fill", title: "Add", content: insight.recommendationToAdd, color: Theme.accent)
                    recommendationBox(icon: "minus.circle.fill", title: "Avoid", content: insight.recommendationToAvoid, color: Theme.warning)
                }
                
                Divider().background(Color.white.opacity(0.3))
                
                Text(insight.encouragement)
                    .font(.system(.subheadline, design: .rounded))
                    .italic()
                    .foregroundColor(.white.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    @ViewBuilder
    private func insightSection(icon: String, title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.system(.headline, design: .rounded))
                .foregroundColor(Theme.accent)
            Text(content)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    @ViewBuilder
    private func recommendationBox(icon: String, title: String, content: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.system(.headline, design: .rounded).bold())
                .foregroundColor(color)
            Text(content)
                .font(.system(.footnote, design: .rounded))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}
