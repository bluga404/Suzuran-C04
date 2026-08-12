import Foundation

/// Contract for persisting user-owned ``SkincareProduct`` values.
protocol SkincareProductRepositoryProtocol {
    func fetchProducts() -> [SkincareProduct]
    func saveProducts(_ products: [SkincareProduct])
    func addProduct(_ product: SkincareProduct)
    func updateProduct(_ product: SkincareProduct)
    func deleteProduct(id: UUID)
}

/// UserDefaults-backed repository for ``SkincareProduct``.
final class SkincareProductRepository: SkincareProductRepositoryProtocol {
    private let userDefaultsKey = "suzuran.skincare.products"
    private let userDefaults: UserDefaults
    private let logger: AppLogging

    init(userDefaults: UserDefaults = .standard, logger: AppLogging = AppLogger()) {
        self.userDefaults = userDefaults
        self.logger = logger
    }

    func fetchProducts() -> [SkincareProduct] {
        guard let data = userDefaults.data(forKey: userDefaultsKey) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([SkincareProduct].self, from: data)
        } catch {
            logger.error("SkincareProductRepository.fetchProducts: decode failed: \(error)")
            return []
        }
    }

    func saveProducts(_ products: [SkincareProduct]) {
        do {
            let data = try JSONEncoder().encode(products)
            userDefaults.set(data, forKey: userDefaultsKey)
        } catch {
            logger.error("SkincareProductRepository.saveProducts: encode failed: \(error)")
        }
    }

    func addProduct(_ product: SkincareProduct) {
        var products = fetchProducts()
        products.append(product)
        saveProducts(products)
    }

    func updateProduct(_ product: SkincareProduct) {
        var products = fetchProducts()
        if let index = products.firstIndex(where: { $0.id == product.id }) {
            products[index] = product
            saveProducts(products)
        }
    }

    func deleteProduct(id: UUID) {
        var products = fetchProducts()
        products.removeAll { $0.id == id }
        saveProducts(products)
    }
}
