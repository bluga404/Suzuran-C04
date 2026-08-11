import Foundation
import Combine

@MainActor
final class RootViewModel: ObservableObject {
    enum Phase: Equatable {
        case report
        case failed(AppError)
    }

    @Published private(set) var phase: Phase = .report

    private let bootstrapper: AppBootstrapping
    private var hasStarted = false

    init(
        bootstrapper: AppBootstrapping
    ) {
        self.bootstrapper = bootstrapper
    }

    func start() {
        guard !hasStarted else {
            return
        }

        hasStarted = true

        Task {
            do {
                try await bootstrapper.bootstrap()
            } catch {
                phase = .failed(AppErrorMapper.map(error))
            }
        }
    }

    func retry() {
        phase = .report
        hasStarted = false
        start()
    }
}
