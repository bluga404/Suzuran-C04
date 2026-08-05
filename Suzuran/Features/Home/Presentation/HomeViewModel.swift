import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    struct ViewState {
        let welcomeText: String
        let ingredientOcrButtonTitle: String
    }

    @Published private(set) var viewState: ViewState

    init(
        welcomeText: String,
        ingredientOcrButtonTitle: String
    ) {
        viewState = ViewState(
            welcomeText: welcomeText,
            ingredientOcrButtonTitle: ingredientOcrButtonTitle
        )
    }
}