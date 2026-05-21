import Foundation
import CoreLocation

private final class StubGooglePlacesService: GooglePlacesServiceProtocol {
    func searchPlace(query: String, near: CLLocationCoordinate2D?) async throws -> [GooglePlaceMatch] {
        if query.contains("蜜柑") {
            return [
                GooglePlaceMatch(
                    id: "stub-mikan",
                    name: "蜜柑 關西風壽喜燒",
                    address: "台中市西區中興街125號2樓",
                    latitude: 24.149,
                    longitude: 120.663,
                    rating: 4.5,
                    priceLevel: 3
                )
            ]
        }
        return []
    }

    func getPlaceDetails(placeId: String) async throws -> GooglePlaceDetails {
        throw GooglePlacesError.noResults
    }
}

@main
struct SocialPlacesRefineFixtureCheck {
    static func main() async {
        let service = SocialLinkReviewCandidateService(googlePlacesService: StubGooglePlacesService())
        let candidates = service.reviewCandidates(
            fromEvidenceText: """
            勤美附近新開的棉花糖壽喜燒
            @mikantaichung
            台中 西區 壽喜燒
            """,
            sourceURL: "https://www.instagram.com/p/DX_cUWNmNxH/"
        )
        guard let candidate = candidates.first else {
            fail("expected handle review candidate")
        }

        let refined = await service.refineCandidate(candidate)
        expect(refined.candidateName == "蜜柑 關西風壽喜燒", "expected refined name")
        expect(refined.address == "台中市西區中興街125號2樓", "expected refined address")
        expect(refined.latitude == 24.149, "expected refined latitude")
        expect(refined.longitude == 120.663, "expected refined longitude")
        expect(refined.confidence >= 0.74, "expected likely confidence")
        expect(refined.missingInfo.contains("Evidence tier: likely"), "expected likely tier")
        expect(refined.missingInfo.contains("Google Places refined; user must confirm before saving"), "expected user confirmation guard")
        expect(refined.evidence.contains("Google Places refined match: 蜜柑 關西風壽喜燒"), "expected Places evidence")

        print("Validated social Places refine fixtures.")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        if !condition() { fail(message) }
    }

    private static func fail(_ message: String) -> Never {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}
