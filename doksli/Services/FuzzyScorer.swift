import Foundation

// MARK: - FuzzyMatch

struct FuzzyMatch {
    let score: Int
    let matchedIndices: [Int]
}

// MARK: - FuzzyScorer

final class FuzzyScorer {

    // Scoring weights
    private static let baseMatch = 1
    private static let consecutiveShort = 6     // ≤3 consecutive
    private static let consecutiveLong = 3      // >3 consecutive
    private static let startOfWord = 8
    private static let separatorBoundary = 5
    private static let camelCaseTransition = 2
    private static let sameCase = 1
    private static let contiguityBonus = 10
    private static let exactIdentity = 1 << 18  // 262144

    private static let separators: Set<Character> = ["/", "\\", "-", "_", ".", " "]

    // Hash-based cache
    private var cache: [String: FuzzyMatch?] = [:]

    func score(query: String, target: String) -> FuzzyMatch? {
        guard !query.isEmpty, !target.isEmpty else { return nil }

        // Exact identity check
        if query == target {
            return FuzzyMatch(
                score: Self.exactIdentity,
                matchedIndices: Array(0..<target.count)
            )
        }

        // Cache lookup
        let cacheKey = "\(query)\0\(target)"
        if let cached = cache[cacheKey] {
            return cached
        }

        let result = computeScore(query: query, target: target)
        cache[cacheKey] = result
        return result
    }

    func clearCache() {
        cache.removeAll()
    }

    // MARK: - DP scoring

    private func computeScore(query: String, target: String) -> FuzzyMatch? {
        let queryChars = Array(query.lowercased())
        let targetChars = Array(target.lowercased())
        let targetOriginal = Array(target)
        let queryOriginal = Array(query)
        let m = queryChars.count
        let n = targetChars.count

        guard m <= n else { return nil }

        // dp[i][j] = best score matching first i query chars in first j target chars
        // consecutive[i][j] = consecutive match streak ending at dp[i][j]
        var dp = Array(repeating: Array(repeating: Int.min, count: n + 1), count: m + 1)
        var consecutive = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        // Track which target index was matched for backtracking
        var choice = Array(repeating: Array(repeating: -1, count: n + 1), count: m + 1)

        // Base case: matching 0 query chars against any prefix = 0
        for j in 0...n {
            dp[0][j] = 0
        }

        for i in 1...m {
            for j in i...n {
                // Option 1: skip target[j-1]
                if dp[i][j - 1] > dp[i][j] {
                    dp[i][j] = dp[i][j - 1]
                    choice[i][j] = choice[i][j - 1]
                }

                // Option 2: match query[i-1] with target[j-1]
                if queryChars[i - 1] == targetChars[j - 1] {
                    let prevScore = dp[i - 1][j - 1]
                    guard prevScore != Int.min else { continue }

                    let bonus = charBonus(
                        queryIdx: i - 1, targetIdx: j - 1, streak: consecutive[i - 1][j - 1] + 1,
                        queryOriginal: queryOriginal, targetOriginal: targetOriginal
                    )

                    let matchScore = prevScore + bonus
                    if matchScore > dp[i][j] {
                        dp[i][j] = matchScore
                        consecutive[i][j] = consecutive[i - 1][j - 1] + 1
                        choice[i][j] = j - 1  // mark this position as a match
                    }
                }
            }
        }

        // No valid match
        guard dp[m][n] != Int.min else { return nil }

        // Backtrack to find matched indices
        let dpIndices = backtrack(dp: dp, choice: choice, queryChars: queryChars, targetChars: targetChars, m: m, n: n)
        let dpResult = FuzzyMatch(score: dp[m][n], matchedIndices: dpIndices)

        // Also find best consecutive substring match — the DP may miss compact
        // matches in favor of scattered word-boundary matches
        let consecutiveResult = bestConsecutiveMatch(
            queryChars: queryChars, targetChars: targetChars,
            queryOriginal: queryOriginal, targetOriginal: targetOriginal,
            m: m, n: n
        )

        // Return whichever scores higher
        if let consec = consecutiveResult, consec.score > dpResult.score {
            return consec
        }
        return dpResult
    }

    // MARK: - Consecutive substring match

    /// Finds the best position where the query appears as a consecutive substring
    /// (case-insensitive) and scores it with a contiguity bonus.
    private func bestConsecutiveMatch(
        queryChars: [Character], targetChars: [Character],
        queryOriginal: [Character], targetOriginal: [Character],
        m: Int, n: Int
    ) -> FuzzyMatch? {
        guard m <= n else { return nil }

        var best: FuzzyMatch?

        for start in 0...(n - m) {
            // Check if query matches consecutively at this position
            var matches = true
            for k in 0..<m {
                if queryChars[k] != targetChars[start + k] {
                    matches = false
                    break
                }
            }
            guard matches else { continue }

            // Score this consecutive match
            var score = 0
            var indices: [Int] = []
            for k in 0..<m {
                let targetIdx = start + k
                let streak = k + 1
                let bonus = charBonus(
                    queryIdx: k, targetIdx: targetIdx, streak: streak,
                    queryOriginal: queryOriginal, targetOriginal: targetOriginal
                )
                score += bonus
                indices.append(targetIdx)
            }

            // Add contiguity bonus for being a consecutive match
            score += m * Self.contiguityBonus

            if best == nil || score > best!.score {
                best = FuzzyMatch(score: score, matchedIndices: indices)
            }
        }

        return best
    }

    // MARK: - Per-character bonus

    private func charBonus(
        queryIdx: Int, targetIdx: Int, streak: Int,
        queryOriginal: [Character], targetOriginal: [Character]
    ) -> Int {
        var bonus = Self.baseMatch

        // Consecutive match bonus
        if streak <= 3 {
            bonus += Self.consecutiveShort
        } else {
            bonus += Self.consecutiveLong
        }

        // Start-of-word bonus
        if targetIdx == 0 || Self.separators.contains(targetOriginal[targetIdx - 1]) {
            bonus += Self.startOfWord
        }

        // Separator boundary bonus
        if targetIdx > 0 && Self.separators.contains(targetOriginal[targetIdx - 1]) {
            bonus += Self.separatorBoundary
        }

        // CamelCase transition bonus
        if targetIdx > 0 && targetOriginal[targetIdx].isUppercase && targetOriginal[targetIdx - 1].isLowercase {
            bonus += Self.camelCaseTransition
        }

        // Same case bonus
        if queryOriginal[queryIdx] == targetOriginal[targetIdx] {
            bonus += Self.sameCase
        }

        return bonus
    }

    private func backtrack(dp: [[Int]], choice: [[Int]], queryChars: [Character], targetChars: [Character], m: Int, n: Int) -> [Int] {
        var indices: [Int] = []
        var i = m
        var j = n

        while i > 0 && j > 0 {
            if j > 1 && dp[i][j] == dp[i][j - 1] && choice[i][j] == choice[i][j - 1] {
                // This score came from skipping target[j-1]
                j -= 1
            } else if queryChars[i - 1] == targetChars[j - 1] {
                // This was a match
                indices.append(j - 1)
                i -= 1
                j -= 1
            } else {
                j -= 1
            }
        }

        return indices.reversed()
    }
}
