import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.saveInk)
                .frame(width: 76, height: 76)
                .background(Color.saveHoney)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.saveNotebookLine, lineWidth: 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.saveInk)

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.saveMutedText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline)
                        .fontWeight(.black)
                        .foregroundColor(.saveInk)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.saveHoney)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.saveNotebookLine, lineWidth: 1.6)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.top, 8)
            }
        }
        .padding(18)
        .saveNotebookPage(cornerRadius: 22)
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStateView(
        icon: "mappin.and.ellipse",
        title: "No Saved Places",
        subtitle: "Share a link from Instagram or any app to start building your map.",
        actionTitle: "Learn How",
        action: {}
    )
}
