import Testing
import Foundation
@testable import Doksli

// MARK: - URLBarView.parseQueryParams tests

@Test func parseFlatParams() {
    let params = URLBarView.parseQueryParams("page=1&limit=10")
    #expect(params.count == 2)
    #expect(params[0].key == "page")
    #expect(params[0].value == "1")
    #expect(params[1].key == "limit")
    #expect(params[1].value == "10")
}

@Test func parseEmptyQueryString() {
    let params = URLBarView.parseQueryParams("")
    #expect(params.isEmpty)
}

@Test func parseEmptyValue() {
    let params = URLBarView.parseQueryParams("key=")
    #expect(params.count == 1)
    #expect(params[0].key == "key")
    #expect(params[0].value == "")
}

@Test func parseNoValueKey() {
    let params = URLBarView.parseQueryParams("debug")
    #expect(params.count == 1)
    #expect(params[0].key == "debug")
    #expect(params[0].value == "")
}

@Test func parseURLEncodedValues() {
    let params = URLBarView.parseQueryParams("q=hello%20world&name=John%26Jane")
    #expect(params.count == 2)
    #expect(params[0].value == "hello world")
    #expect(params[1].value == "John&Jane")
}

@Test func parseArrayBracketNotation() {
    let params = URLBarView.parseQueryParams("ids[0]=a&ids[1]=b&ids[2]=c")
    #expect(params.count == 1)
    #expect(params[0].key == "ids")
    #expect(params[0].valueType == .array)
    #expect(params[0].children?.count == 3)
    #expect(params[0].children?[0].value == "a")
    #expect(params[0].children?[1].value == "b")
    #expect(params[0].children?[2].value == "c")
}

@Test func parseURLEncodedBrackets() {
    let params = URLBarView.parseQueryParams("items%5B0%5D=a&items%5B1%5D=b")
    #expect(params.count == 1)
    #expect(params[0].key == "items")
    #expect(params[0].valueType == .array)
    #expect(params[0].children?.count == 2)
    #expect(params[0].children?[0].value == "a")
    #expect(params[0].children?[1].value == "b")
}

@Test func parseObjectBracketNotation() {
    let params = URLBarView.parseQueryParams("filter[status]=active&filter[role]=admin")
    #expect(params.count == 1)
    #expect(params[0].key == "filter")
    #expect(params[0].valueType == .object)
    #expect(params[0].children?.count == 2)
    #expect(params[0].children?[0].key == "status")
    #expect(params[0].children?[0].value == "active")
    #expect(params[0].children?[1].key == "role")
    #expect(params[0].children?[1].value == "admin")
}

@Test func parseDeeplyNested() {
    let params = URLBarView.parseQueryParams("user[address][city]=London")
    #expect(params.count == 1)
    #expect(params[0].key == "user")
    #expect(params[0].valueType == .object)
    let address = params[0].children?[0]
    #expect(address?.key == "address")
    #expect(address?.valueType == .object)
    #expect(address?.children?[0].key == "city")
    #expect(address?.children?[0].value == "London")
}

@Test func parseMixedFlatAndNested() {
    let params = URLBarView.parseQueryParams("page=1&filter[status]=active&limit=10")
    #expect(params.count == 3)
    #expect(params[0].key == "page")
    #expect(params[0].value == "1")
    #expect(params[0].valueType == .text)
    #expect(params[1].key == "filter")
    #expect(params[1].valueType == .object)
    #expect(params[2].key == "limit")
    #expect(params[2].value == "10")
}

@Test func parseMergeDuplicateArrayRoots() {
    let params = URLBarView.parseQueryParams("a[0]=1&a[1]=2")
    #expect(params.count == 1)
    #expect(params[0].key == "a")
    #expect(params[0].valueType == .array)
    #expect(params[0].children?.count == 2)
    #expect(params[0].children?[0].value == "1")
    #expect(params[0].children?[1].value == "2")
}

@Test func parseRoundTrip() {
    let original = "page=1&sortParam=mostRelevant&lastEducations[0]=8&lastEducations[1]=1&status=active"
    let params = URLBarView.parseQueryParams(original)
    let flattened = HTTPClient.flattenPairs(params)
    let rebuilt = flattened.map { "\($0.name)=\($0.pair.value)" }.joined(separator: "&")
    #expect(rebuilt == original)
}
