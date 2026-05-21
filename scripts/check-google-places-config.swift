import Foundation
import CoreLocation

@main
struct GooglePlacesConfigCheck {
    static func main() async {
        await expectMissingKey(for: nil, "nil key should be missing")
        await expectMissingKey(for: "", "empty key should be missing")
        await expectMissingKey(for: "   ", "blank key should be missing")
        await expectMissingKey(for: "YOUR_KEY_HERE", "placeholder key should be missing")
        await expectMissingKey(for: " google_places_api_key ", "placeholder env name should be missing")

        print("Validated Google Places config guard.")
    }

    private static func expectMissingKey(for key: String?, _ message: String) async {
        let service = GooglePlacesService(apiKey: key)
        do {
            _ = try await service.searchPlace(query: "USHIGORO S", near: nil)
            fail(message)
        } catch GooglePlacesError.apiKeyMissing {
            let text = GooglePlacesError.apiKeyMissing.localizedDescription
            expect(text.contains("GOOGLE_PLACES_API_KEY"), "missing-key error should name GOOGLE_PLACES_API_KEY")
            expect(text.contains("Gemini"), "missing-key error should clarify Gemini is separate")
        } catch {
            fail("\(message): expected apiKeyMissing, got \(error)")
        }
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        if !condition() { fail(message) }
    }

    private static func fail(_ message: String) -> Never {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}
