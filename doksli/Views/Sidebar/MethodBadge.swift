import SwiftUI

// MARK: - MethodBadge

struct MethodBadge: View {
    let method: HTTPMethod

    var body: some View {
        Text(label)
            .font(AppFonts.eyebrow)
            .tracking(AppFonts.eyebrowTracking)
            .foregroundColor(colors.text)
            .padding(.horizontal, AppSpacing.xs)
            .padding(.vertical, 2)
            .background(colors.bg)
            .cornerRadius(AppSpacing.radiusBadge)
            .fixedSize()
    }

    private var label: String {
        switch method {
        case .GET:     return "GET"
        case .POST:    return "POST"
        case .PUT:     return "PUT"
        case .DELETE:  return "DEL"
        case .PATCH:   return "PATCH"
        case .OPTIONS: return "OPT"
        case .HEAD:    return "HEAD"
        }
    }

    private var colors: MethodColor {
        switch method {
        case .GET:     return AppColors.methodGet
        case .POST:    return AppColors.methodPost
        case .PUT:     return AppColors.methodPut
        case .DELETE:  return AppColors.methodDelete
        case .PATCH:   return AppColors.methodPatch
        case .OPTIONS: return AppColors.methodOptions
        case .HEAD:    return AppColors.methodHead
        }
    }
}
