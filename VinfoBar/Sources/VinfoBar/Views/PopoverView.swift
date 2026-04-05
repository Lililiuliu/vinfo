import SwiftUI

struct PopoverView: View {
    @EnvironmentObject var service: EnvironmentService
    @State private var selectedEnvironment: String?
    @State private var showDetail = false
    @State private var detailEnvironment: (any EnvironmentInfo)?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Development Environment")
                    .font(.headline)
                Spacer()
                Button(action: { Task { await service.refresh() } }) {
                    Image(systemName: "arrow.clockwise")
                        .rotationEffect(.degrees(service.isRefreshing ? 360 : 0))
                        .animation(
                            service.isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                            value: service.isRefreshing
                        )
                }
                .buttonStyle(.plain)
                .disabled(service.isRefreshing)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            if service.isRefreshing && service.environments.isEmpty {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if service.environments.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No environments detected")
                        .foregroundColor(.secondary)
                    Button("Refresh") {
                        Task { await service.refresh() }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $selectedEnvironment) {
                    ForEach(service.environments, id: \.name) { env in
                        EnvironmentRowView(info: env)
                            .tag(env.name)
                            .onTapGesture(count: 2) {
                                detailEnvironment = env
                                showDetail = true
                            }
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }

            Divider()

            // Footer
            HStack {
                Button("Settings") {
                    NSApp.sendAction(#selector(AppDelegate.openSettings), to: nil, from: nil)
                }
                Spacer()
                if service.lastRefresh != .distantPast {
                    Text("Updated: \(service.lastRefresh, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .frame(width: 360, height: 480)
        .sheet(isPresented: $showDetail) {
            if let env = detailEnvironment {
                DetailView(info: env)
                    .environmentObject(service)
            }
        }
    }
}