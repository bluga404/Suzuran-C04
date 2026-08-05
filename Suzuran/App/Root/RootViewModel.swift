import Combine
import Foundation

@MainActor
final class RootViewModel: ObservableObject {
    enum Phase: Equatable {
        case launching
        case ready
        case failed(AppError)
    }

    @Published private(set) var phase: Phase = .launching

    private let bootstrapper: AppBootstrapping
    private var hasStarted = false

    init(bootstrapper: AppBootstrapping) {
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
                phase = .ready
            } catch {
                phase = .failed(AppErrorMapper.map(error))
            }
        }
    }

    func retry() {
        phase = .launching
        hasStarted = false
        start()
    }
}
