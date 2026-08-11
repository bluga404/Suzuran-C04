import SwiftUI

/// Custom page indicator matching the design specifications.
struct PageIndicatorView: View {
    let numberOfPages: Int
    let currentPage: Int
    var activeColor: Color = .white
    var inactiveColor: Color = Color.white.opacity(0.35)
    var onSelectPage: ((Int) -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<numberOfPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? activeColor : inactiveColor)
                    .frame(width: 8, height: 8)
                    .scaleEffect(index == currentPage ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                    .onTapGesture {
                        onSelectPage?(index)
                    }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
        VStack(spacing: 20) {
            PageIndicatorView(numberOfPages: 3, currentPage: 0)
            PageIndicatorView(numberOfPages: 3, currentPage: 1)
            PageIndicatorView(numberOfPages: 3, currentPage: 2)
        }
    }
}
