import Foundation
import UIKit

enum AppSettingsURLProvider {
    static func appSettingsURL() -> URL? {
        URL(string: UIApplication.openSettingsURLString)
    }
}
