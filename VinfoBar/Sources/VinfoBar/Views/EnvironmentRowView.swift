import SwiftUI

struct EnvironmentRowView: View {
    let info: any EnvironmentInfo

    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            Image(systemName: info.status.icon)
                .foregroundColor(info.status.color)
                .font(.title2)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(info.displayName)
                    .font(.headline)

                if let version = info.version {
                    Text("v\(version)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if !info.errors.isEmpty {
                    Text(info.errors.first ?? "")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }

            Spacer()

            // Quick indicator
            if !info.actionsAvailable.isEmpty {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}