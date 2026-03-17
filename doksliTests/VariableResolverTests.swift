import Testing
import Foundation
@testable import doksli

// MARK: - VariableResolver unit tests

@Test func resolveKnownVar() {
    let env = Environment(id: UUID(), name: "Test", variables: [
        EnvVar(id: UUID(), key: "token", value: "sk_live_abc", enabled: true)
    ])
    let result = VariableResolver.resolve("Bearer {{token}}", environment: env)
    #expect(result == "Bearer sk_live_abc")
}

@Test func resolveMultipleVars() {
    let env = Environment(id: UUID(), name: "Test", variables: [
        EnvVar(id: UUID(), key: "scheme", value: "https", enabled: true),
        EnvVar(id: UUID(), key: "host", value: "api.example.com", enabled: true)
    ])
    let result = VariableResolver.resolve("{{scheme}}://{{host}}", environment: env)
    #expect(result == "https://api.example.com")
}

@Test func resolveFullURL() {
    let env = Environment(id: UUID(), name: "Test", variables: [
        EnvVar(id: UUID(), key: "base_url", value: "api.example.com", enabled: true)
    ])
    let result = VariableResolver.resolve("https://{{base_url}}/v1/users", environment: env)
    #expect(result == "https://api.example.com/v1/users")
}

@Test func resolveUnknownVarLeftAsIs() {
    let env = Environment(id: UUID(), name: "Test", variables: [
        EnvVar(id: UUID(), key: "token", value: "abc", enabled: true)
    ])
    let result = VariableResolver.resolve("Bearer {{unknown}}", environment: env)
    #expect(result == "Bearer {{unknown}}")
}

@Test func resolveDisabledVarSkipped() {
    let env = Environment(id: UUID(), name: "Test", variables: [
        EnvVar(id: UUID(), key: "token", value: "secret", enabled: false)
    ])
    let result = VariableResolver.resolve("{{token}}", environment: env)
    #expect(result == "{{token}}")
}

@Test func resolveNilEnvironment() {
    let result = VariableResolver.resolve("{{token}}", environment: nil)
    #expect(result == "{{token}}")
}

@Test func resolveEmptyString() {
    let env = Environment(id: UUID(), name: "Test", variables: [
        EnvVar(id: UUID(), key: "token", value: "abc", enabled: true)
    ])
    let result = VariableResolver.resolve("", environment: env)
    #expect(result == "")
}

@Test func resolveNoVarsInString() {
    let env = Environment(id: UUID(), name: "Test", variables: [
        EnvVar(id: UUID(), key: "token", value: "abc", enabled: true)
    ])
    let result = VariableResolver.resolve("https://api.example.com", environment: env)
    #expect(result == "https://api.example.com")
}

@Test func resolveMalformedPatternLeftAsIs() {
    let env = Environment(id: UUID(), name: "Test", variables: [
        EnvVar(id: UUID(), key: "", value: "x", enabled: true)
    ])
    // {{}} has no \w+ inside so pattern does not match — left as-is
    let result = VariableResolver.resolve("{{}}", environment: env)
    #expect(result == "{{}}")
}

@Test func resolvePartialBraceLeftAsIs() {
    let env = Environment(id: UUID(), name: "Test", variables: [
        EnvVar(id: UUID(), key: "token", value: "abc", enabled: true)
    ])
    // {{ without closing }} — not matched, left as-is
    let result = VariableResolver.resolve("{{token", environment: env)
    #expect(result == "{{token")
}

@Test func resolveDoesNotMutateOriginal() {
    let env = Environment(id: UUID(), name: "Test", variables: [
        EnvVar(id: UUID(), key: "x", value: "replaced", enabled: true)
    ])
    let original = "{{x}}"
    let resolved = VariableResolver.resolve(original, environment: env)
    #expect(original == "{{x}}")
    #expect(resolved == "replaced")
}
