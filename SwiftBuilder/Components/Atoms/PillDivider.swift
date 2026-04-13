import SwiftUI

struct PillDivider: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(Color.primary.opacity(0.12))
            .frame(width: 1, height: 20)
    }
}
