import XCTest
@testable import SAVE

final class VerifiedPlaceClaimsClientTests: XCTestCase {
    func testVerifiedPlaceClaimDecodesSnakeCaseResponse() throws {
        let claimId = UUID()
        let placeId = UUID()
        let json = """
        {
          "claim_id": "\(claimId.uuidString)",
          "place_id": "\(placeId.uuidString)",
          "claim_type": "visited",
          "claim": "Tried the matcha latte.",
          "agent_usable_summary": "User tried the matcha latte.",
          "author": {
            "author_type": "self",
            "public_handle": null,
            "relationship": "self"
          },
          "proof_level": "user_confirmed_place",
          "confidence": 0.82,
          "visibility": "private",
          "evidence_summary": ["Saved by user"],
          "evidence_refs": ["save://memory/1"],
          "observed_at": "2026-06-03T10:00:00Z",
          "expires_or_stale_after": null,
          "created_at": "2026-06-03T10:01:00Z"
        }
        """.data(using: .utf8)!

        let claim = try JSONDecoder.supabase.decode(VerifiedPlaceClaim.self, from: json)

        XCTAssertEqual(claim.id, claimId)
        XCTAssertEqual(claim.placeId, placeId)
        XCTAssertEqual(claim.claimType, "visited")
        XCTAssertEqual(claim.author.relationship, "self")
        XCTAssertEqual(claim.evidenceRefs, ["save://memory/1"])
    }

    func testVerifiedPlaceClaimDraftBuildsBackendBody() throws {
        let draft = VerifiedPlaceClaimDraft(
            claimType: "menu_item",
            claim: "Has milk tea.",
            agentUsableSummary: "Milk tea evidence is user-confirmed.",
            proofLevel: "user_confirmed_place",
            evidenceRefs: ["save://source/1"],
            visibility: "private",
            confidence: 0.74,
            context: ["query": "milk tea"],
            ratings: ["taste": 4],
            observedAt: "2026-06-03T10:00:00Z",
            expiresOrStaleAfter: nil
        )

        XCTAssertEqual(draft.body["claim_type"] as? String, "menu_item")
        XCTAssertEqual(draft.body["agent_usable_summary"] as? String, "Milk tea evidence is user-confirmed.")
        XCTAssertEqual(draft.body["proof_level"] as? String, "user_confirmed_place")
        XCTAssertEqual(draft.body["evidence_refs"] as? [String], ["save://source/1"])
        XCTAssertEqual(draft.body["visibility"] as? String, "private")
        XCTAssertEqual(draft.body["confidence"] as? Double, 0.74)
    }

    func testClaimRecommendationResponseDecodesRetrievalReceipt() throws {
        let placeId = UUID()
        let claimId = UUID()
        let json = """
        {
          "results": [
            {
              "place_id": "\(placeId.uuidString)",
              "name": "Kato",
              "why": "matches menu_item; strongest proof is user_confirmed_place",
              "proof_level": "user_confirmed_place",
              "confidence": 0.91,
              "supporting_claims": ["\(claimId.uuidString)"],
              "warnings": [],
              "next_actions": ["view_card", "get_trust_summary"]
            }
          ],
          "retrieval_receipt": {
            "used": ["1 owner-scoped places", "1 verified claims"],
            "skipped": [],
            "public_web_used": false
          }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder.supabase.decode(ClaimRecommendationResponse.self, from: json)

        XCTAssertEqual(response.results.first?.id, placeId)
        XCTAssertEqual(response.results.first?.supportingClaims, [claimId])
        XCTAssertEqual(response.retrievalReceipt.used, ["1 owner-scoped places", "1 verified claims"])
        XCTAssertFalse(response.retrievalReceipt.publicWebUsed)
    }
}
