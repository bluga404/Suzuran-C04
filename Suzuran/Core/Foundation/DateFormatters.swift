import Foundation

enum DateFormatters {
    static let dayShort: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "EEE"
        return f
    }()

    static let dayAndMonth: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "d MMM"
        return f
    }()

    static let monthShort: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "MMM"
        return f
    }()

    static let fullDateID: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "id_ID")
        f.dateFormat = "d MMM yyyy"
        return f
    }()

    static let fullDateEN: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "d MMM yyyy"
        return f
    }()
}
