import Foundation

protocol SkincareRepositoryProtocol {
    func fetchProducts() -> [SkincareProduct]
    func saveProducts(_ products: [SkincareProduct])
    func addProduct(_ product: SkincareProduct)
    func updateProduct(_ product: SkincareProduct)
    func deleteProduct(id: UUID)
}

final class SkincareRepository: SkincareRepositoryProtocol {
    private let userDefaultsKey = "suzuran.skincare.products"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func fetchProducts() -> [SkincareProduct] {
        guard let data = userDefaults.data(forKey: userDefaultsKey) else {
            return []
        }
        do {
            return try JSONDecoder().decode([SkincareProduct].self, from: data)
        } catch {
            print("[SkincareRepository] Failed to decode products: \(error)")
            return []
        }
    }

    func saveProducts(_ products: [SkincareProduct]) {
        do {
            let data = try JSONEncoder().encode(products)
            userDefaults.set(data, forKey: userDefaultsKey)
        } catch {
            print("[SkincareRepository] Failed to encode products: \(error)")
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
