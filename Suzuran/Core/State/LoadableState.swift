import Foundation

enum LoadableState<Value: Equatable>: Equatable {
    case idle
    case loading
    case loaded(Value)
    case empty(title: String, message: String)
    case failed(AppError)
}
