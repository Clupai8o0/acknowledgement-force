import SwiftUI
import ForceKit

struct HistoryView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var store: Store

    private var entries: [HistoryEntry] {
        Array(store.loadHistory().prefix(7))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("PAST ACTIONS")
                    .font(Type.headingXL)
                    .foregroundStyle(Ink.ink)
                Spacer()
                Button("Close") { isPresented = false }
                    .buttonStyle(GhostTextStyle(color: Ink.mute))
            }
            .padding(.horizontal, Space.section)
            .padding(.top, Space.section)
            .padding(.bottom, Space.xl)
            .background(Ink.containerLow)

            if entries.isEmpty {
                Text("No past actions recorded yet.")
                    .font(Type.bodyMD)
                    .foregroundStyle(Ink.mute)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(Space.section)
            } else {
                ScrollView {
                    VStack(spacing: Space.sm) {
                        ForEach(Array(entries.enumerated()), id: \.element.id) { idx, entry in
                            HistoryRow(entry: entry, index: idx)
                        }
                    }
                    .padding(.horizontal, Space.section)
                    .padding(.vertical, Space.xl)
                }
            }
        }
        .frame(width: 720, height: 560)
        .background(Ink.base)
    }
}

private struct HistoryRow: View {
    let entry: HistoryEntry
    let index: Int
    @State private var appeared = false
    @State private var hovering = false

    var body: some View {
        HStack(alignment: .top, spacing: Space.xl) {
            Text(AppDate.short(entry.date))
                .font(Type.captionSM)
                .tracking(0.5)
                .foregroundStyle(Ink.mute)
                .frame(width: 120, alignment: .leading)
                .padding(.top, 2)
            Text(entry.action)
                .font(Type.bodyStrong)
                .foregroundStyle(Ink.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(Space.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(hovering ? Ink.bright : Ink.containerLow, in: RoundedRectangle(cornerRadius: Radius.lg))
        .modifier(HistoryHover(hovering: hovering))
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.18), value: hovering)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 7)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85).delay(Double(index) * 0.07)) {
                appeared = true
            }
        }
    }
}

private struct HistoryHover: ViewModifier {
    var hovering: Bool
    func body(content: Content) -> some View {
        if hovering { content.ambientShadow() } else { content }
    }
}
