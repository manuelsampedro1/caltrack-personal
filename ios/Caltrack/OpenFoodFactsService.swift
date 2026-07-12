import Foundation

struct BarcodeProduct: Equatable {
    let code: String
    let name: String
    let brands: String
    let servingSize: String
    let nutriScore: String?
    let caloriesPer100: Double
    let proteinPer100: Double
    let carbohydratesPer100: Double
    let fatPer100: Double

    func editableMeal(amount: Double) -> EditableMeal {
        let factor = max(0, amount) / 100
        var meal = EditableMeal()
        meal.name = brands.isEmpty ? name : "\(name) · \(brands)"
        meal.calories = Self.format(caloriesPer100 * factor)
        meal.protein = Self.format(proteinPer100 * factor)
        meal.carbohydrates = Self.format(carbohydratesPer100 * factor)
        meal.fat = Self.format(fatPer100 * factor)
        meal.confidence = 1
        meal.assumption = "Código \(code), \(Self.format(amount)) g o ml consumidos. Datos colaborativos de Open Food Facts."
        return meal
    }

#if DEBUG
    static let testingFixture = BarcodeProduct(
        code: "3017620422003",
        name: "Nutella",
        brands: "Ferrero",
        servingSize: "15 g",
        nutriScore: "e",
        caloriesPer100: 539,
        proteinPer100: 6.3,
        carbohydratesPer100: 57.5,
        fatPer100: 30.9
    )
#endif

    private static func format(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }
}

struct OpenFoodFactsService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func product(barcode rawBarcode: String) async throws -> BarcodeProduct {
        let barcode = try Self.normalizedBarcode(rawBarcode)
        var components = URLComponents(string: "https://world.openfoodfacts.org/api/v3/product/\(barcode)")!
        components.queryItems = [
            URLQueryItem(
                name: "fields",
                value: "code,product_name,product_name_es,brands,serving_size,nutriments,nutriscore_grade"
            )
        ]
        guard let url = components.url else { throw OpenFoodFactsError.invalidResponse }
        var request = URLRequest(url: url)
        request.timeoutInterval = 25
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("es", forHTTPHeaderField: "Accept-Language")
        request.setValue(
            "Caltrack - iOS - Version 1.3 - https://github.com/manuelsampedro1/caltrack-personal - scan",
            forHTTPHeaderField: "User-Agent"
        )

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw OpenFoodFactsError.invalidResponse }
        if http.statusCode == 404 { throw OpenFoodFactsError.notFound }
        guard (200..<300).contains(http.statusCode) else {
            throw OpenFoodFactsError.api("Open Food Facts devolvió el código \(http.statusCode).")
        }
        return try Self.decodeProduct(data, fallbackCode: barcode)
    }

    static func decodeProduct(_ data: Data, fallbackCode: String = "") throws -> BarcodeProduct {
        let envelope = try JSONDecoder().decode(OpenFoodFactsEnvelope.self, from: data)
        guard envelope.status == "success", let product = envelope.product else {
            throw OpenFoodFactsError.notFound
        }
        let name = [product.productNameES, product.productName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty })
        guard let name else { throw OpenFoodFactsError.incompleteProduct }
        guard let calories = product.nutriments.energyKcal100 ?? product.nutriments.energyKcal,
              let protein = product.nutriments.proteins100 ?? product.nutriments.proteins,
              let carbohydrates = product.nutriments.carbohydrates100 ?? product.nutriments.carbohydrates,
              let fat = product.nutriments.fat100 ?? product.nutriments.fat else {
            throw OpenFoodFactsError.incompleteNutrition
        }
        return BarcodeProduct(
            code: product.code ?? envelope.code ?? fallbackCode,
            name: name,
            brands: product.brands?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            servingSize: product.servingSize?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            nutriScore: product.nutriScore?.lowercased(),
            caloriesPer100: max(0, calories),
            proteinPer100: max(0, protein),
            carbohydratesPer100: max(0, carbohydrates),
            fatPer100: max(0, fat)
        )
    }

    static func normalizedBarcode(_ value: String) throws -> String {
        let digits = value.filter(\.isNumber)
        guard digits.count >= 8, digits.count <= 14, digits.count == value.filter({ !$0.isWhitespace && $0 != "-" }).count else {
            throw OpenFoodFactsError.invalidBarcode
        }
        return digits
    }
}

private struct OpenFoodFactsEnvelope: Decodable {
    let status: String
    let code: String?
    let product: Product?

    struct Product: Decodable {
        let code: String?
        let productName: String?
        let productNameES: String?
        let brands: String?
        let servingSize: String?
        let nutriScore: String?
        let nutriments: Nutriments

        enum CodingKeys: String, CodingKey {
            case code, brands, nutriments
            case productName = "product_name"
            case productNameES = "product_name_es"
            case servingSize = "serving_size"
            case nutriScore = "nutriscore_grade"
        }
    }

    struct Nutriments: Decodable {
        let energyKcal100: Double?
        let energyKcal: Double?
        let proteins100: Double?
        let proteins: Double?
        let carbohydrates100: Double?
        let carbohydrates: Double?
        let fat100: Double?
        let fat: Double?

        enum CodingKeys: String, CodingKey {
            case energyKcal100 = "energy-kcal_100g"
            case energyKcal = "energy-kcal"
            case proteins100 = "proteins_100g"
            case proteins
            case carbohydrates100 = "carbohydrates_100g"
            case carbohydrates
            case fat100 = "fat_100g"
            case fat
        }
    }
}

enum OpenFoodFactsError: LocalizedError, Equatable {
    case invalidBarcode
    case notFound
    case incompleteProduct
    case incompleteNutrition
    case invalidResponse
    case api(String)

    var errorDescription: String? {
        switch self {
        case .invalidBarcode: "Introduce un código de entre 8 y 14 dígitos."
        case .notFound: "Este producto todavía no está en Open Food Facts."
        case .incompleteProduct: "El producto no tiene un nombre verificable."
        case .incompleteNutrition: "Faltan calorías o macros en la ficha del producto."
        case .invalidResponse: "Open Food Facts respondió con un formato desconocido."
        case .api(let message): message
        }
    }
}
