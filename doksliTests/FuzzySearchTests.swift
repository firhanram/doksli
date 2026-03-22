import XCTest
@testable import Doksli

final class FuzzySearchTests: XCTestCase {

    private var scorer: FuzzyScorer!

    override func setUp() {
        super.setUp()
        scorer = FuzzyScorer()
    }

    override func tearDown() {
        scorer = nil
        super.tearDown()
    }

    // MARK: - FuzzyScorer tests

    func testExactMatch() {
        let result = scorer.score(query: "Login", target: "Login")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.score, 1 << 18)
        XCTAssertEqual(result?.matchedIndices, [0, 1, 2, 3, 4])
    }

    func testPrefixMatchScoresHigherThanSuffix() {
        let prefix = scorer.score(query: "Log", target: "Login")
        let suffix = scorer.score(query: "gin", target: "Login")
        XCTAssertNotNil(prefix)
        XCTAssertNotNil(suffix)
        XCTAssertGreaterThan(prefix!.score, suffix!.score)
    }

    func testCaseInsensitiveMatch() {
        let result = scorer.score(query: "login", target: "Login")
        XCTAssertNotNil(result)
    }

    func testSameCaseBonus() {
        let sameCase = scorer.score(query: "Log", target: "Login")
        let diffCase = scorer.score(query: "log", target: "Login")
        XCTAssertNotNil(sameCase)
        XCTAssertNotNil(diffCase)
        XCTAssertGreaterThan(sameCase!.score, diffCase!.score)
    }

    func testCamelCaseMatch() {
        let result = scorer.score(query: "gU", target: "getUser")
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.matchedIndices.contains(0)) // g
        XCTAssertTrue(result!.matchedIndices.contains(3)) // U
    }

    func testStartOfWordBonus() {
        let withSeparator = scorer.score(query: "us", target: "get-user")
        let withoutSeparator = scorer.score(query: "us", target: "abcuser")
        XCTAssertNotNil(withSeparator)
        XCTAssertNotNil(withoutSeparator)
        XCTAssertGreaterThan(withSeparator!.score, withoutSeparator!.score)
    }

    func testConsecutiveBonus() {
        let consecutive = scorer.score(query: "get", target: "getUser")
        let scattered = scorer.score(query: "geu", target: "getUser")
        XCTAssertNotNil(consecutive)
        XCTAssertNotNil(scattered)
        XCTAssertGreaterThan(consecutive!.score, scattered!.score)
    }

    func testNoMatch() {
        let result = scorer.score(query: "xyz", target: "Login")
        XCTAssertNil(result)
    }

    func testEmptyQuery() {
        let result = scorer.score(query: "", target: "Login")
        XCTAssertNil(result)
    }

    func testEmptyTarget() {
        let result = scorer.score(query: "a", target: "")
        XCTAssertNil(result)
    }

    func testCacheHit() {
        let first = scorer.score(query: "Log", target: "Login")
        let second = scorer.score(query: "Log", target: "Login")
        XCTAssertEqual(first?.score, second?.score)
        XCTAssertEqual(first?.matchedIndices, second?.matchedIndices)
    }

    func testSeparatorBoundaryBonus() {
        let withSlash = scorer.score(query: "u", target: "auth/users")
        let noSlash = scorer.score(query: "u", target: "authxusers")
        XCTAssertNotNil(withSlash)
        XCTAssertNotNil(noSlash)
        XCTAssertGreaterThan(withSlash!.score, noSlash!.score)
    }

    func testQueryLongerThanTarget() {
        let result = scorer.score(query: "LongQuery", target: "Lo")
        XCTAssertNil(result)
    }

    func testMatchedIndicesAreCorrect() {
        let result = scorer.score(query: "abc", target: "aXbXc")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.matchedIndices, [0, 2, 4])
    }

    func testClearCache() {
        _ = scorer.score(query: "Log", target: "Login")
        scorer.clearCache()
        // After clearing, scoring again should still work
        let result = scorer.score(query: "Log", target: "Login")
        XCTAssertNotNil(result)
    }

    func testURLSlashSeparator() {
        let result = scorer.score(query: "users", target: "api/users")
        XCTAssertNotNil(result)
        // Should get separator boundary bonus at 'u' after '/'
        XCTAssertTrue(result!.score > 0)
    }

    // MARK: - SidebarSearchService tests

    func testSearchByName() {
        let service = SidebarSearchService()
        let workspace = makeTestWorkspace()
        let results = service.search(query: "Login", in: workspace)
        XCTAssertFalse(results.isEmpty)
        XCTAssertEqual(results.first?.name, "Login")
    }

    func testSearchByURL() {
        let service = SidebarSearchService()
        let workspace = makeTestWorkspace()
        let results = service.search(query: "users", in: workspace)
        XCTAssertFalse(results.isEmpty)
        // Should match the request with URL containing "users"
        let hasUserMatch = results.contains { $0.url?.contains("users") == true }
        XCTAssertTrue(hasUserMatch)
    }

    func testSearchEmptyQuery() {
        let service = SidebarSearchService()
        let workspace = makeTestWorkspace()
        let results = service.search(query: "", in: workspace)
        XCTAssertTrue(results.isEmpty)
    }

    func testSearchWhitespaceQuery() {
        let service = SidebarSearchService()
        let workspace = makeTestWorkspace()
        let results = service.search(query: "   ", in: workspace)
        XCTAssertTrue(results.isEmpty)
    }

    func testSearchNoResults() {
        let service = SidebarSearchService()
        let workspace = makeTestWorkspace()
        let results = service.search(query: "zzzzzzz", in: workspace)
        XCTAssertTrue(results.isEmpty)
    }

    func testSearchResultsSortedByScore() {
        let service = SidebarSearchService()
        let workspace = makeTestWorkspace()
        let results = service.search(query: "get", in: workspace)
        for i in 1..<results.count {
            XCTAssertGreaterThanOrEqual(results[i - 1].score, results[i].score)
        }
    }

    func testBreadcrumbBuilding() {
        let service = SidebarSearchService()
        let workspace = makeTestWorkspace()
        let results = service.search(query: "Nested", in: workspace)
        let nested = results.first { $0.name == "Nested Request" }
        XCTAssertNotNil(nested)
        XCTAssertEqual(nested?.breadcrumb, "Auth")
    }

    func testSearchMatchesFolder() {
        let service = SidebarSearchService()
        let workspace = makeTestWorkspace()
        let results = service.search(query: "Auth", in: workspace)
        let folderResult = results.first { $0.method == nil }
        XCTAssertNotNil(folderResult)
        XCTAssertEqual(folderResult?.name, "Auth")
    }

    func testResultCacheHit() {
        let service = SidebarSearchService()
        let workspace = makeTestWorkspace()
        let first = service.search(query: "Login", in: workspace)
        let second = service.search(query: "Login", in: workspace)
        XCTAssertEqual(first.count, second.count)
        if let f = first.first, let s = second.first {
            XCTAssertEqual(f.score, s.score)
        }
    }

    func testBestFieldWins() {
        let service = SidebarSearchService()
        // Request named "Login" with URL "/api/login"
        let workspace = makeTestWorkspace()
        let results = service.search(query: "Login", in: workspace)
        let loginResult = results.first { $0.name == "Login" }
        XCTAssertNotNil(loginResult)
        // "Login" exactly matches the name, so matchedField should be .name
        XCTAssertEqual(loginResult?.matchedField, .name)
    }

    // MARK: - Helpers

    private func makeTestWorkspace() -> Workspace {
        let nestedRequest = Request(
            id: UUID(), name: "Nested Request", method: .POST,
            url: "https://api.example.com/auth/token",
            params: [], headers: [], body: .none, auth: .none
        )
        let folder = Folder(id: UUID(), name: "Auth", items: [.request(nestedRequest)])

        let loginRequest = Request(
            id: UUID(), name: "Login", method: .POST,
            url: "https://api.example.com/login",
            params: [], headers: [], body: .none, auth: .none
        )
        let getUsersRequest = Request(
            id: UUID(), name: "Get Users", method: .GET,
            url: "https://api.example.com/users",
            params: [], headers: [], body: .none, auth: .none
        )

        let collection = Collection(
            id: UUID(), name: "Requests",
            items: [.request(loginRequest), .request(getUsersRequest), .folder(folder)]
        )

        return Workspace(id: UUID(), name: "Test", collections: [collection])
    }
}
