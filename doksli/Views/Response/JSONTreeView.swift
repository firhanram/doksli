import SwiftUI

// MARK: - JSONTreeView

struct JSONTreeView: View {
    let data: Data

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let parsed = parseJSON() {
                    JSONNode(key: nil, value: parsed, depth: 0)
                } else {
                    fallbackView
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - JSON parsing

    private func parseJSON() -> Any? {
        try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
    }

    // MARK: - Fallback for non-JSON

    private var fallbackView: some View {
        RawBodyView(data: data)
    }
}
