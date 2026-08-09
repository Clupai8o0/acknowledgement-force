import SwiftCrossUI
import ForceKit

/// The locked state: read the contract, acknowledge it, name today's action,
/// then confirm to open the gate. Desktop port of the macOS `ContractView`.
///
/// MVP difference: the macOS app requires scrolling to the bottom before the
/// acknowledgement unlocks. SwiftCrossUI 0.7 doesn't expose scroll position, so
/// here the gate requires the acknowledgement checkbox + a non-empty action
/// (the contract is still fully shown above).
struct ContractView: View {
    @Environment(DesktopModel.self) var model
    @State var acknowledged = false
    @State var actionText = ""

    private var canConfirm: Bool {
        acknowledged && !actionText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var statusMessage: String {
        if !acknowledged { return "Check the acknowledgement box." }
        if actionText.trimmingCharacters(in: .whitespaces).isEmpty {
            return "Enter your highest-leverage action for today."
        }
        return "Ready to confirm."
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.lg) {
                    header
                    ForEach(indexedBlocks(from: model.contractText, name: model.displayName), id: \.id) { item in
                        contractBlockView(item.block)
                    }
                }
                .frame(maxWidth: 760)
                .padding(Space.section)
            }
            form
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Ink.base)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            Text("DAILY CONTRACT")
                .font(Type.captionSM)
                .foregroundColor(Ink.mute)
            Text("ACKNOWLEDGEMENT FORCE")
                .font(Type.display(40))
                .foregroundColor(Ink.ink)
            Text("Read carefully. Acknowledge intentionally.")
                .font(Type.bodyMD)
                .foregroundColor(Ink.mute)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: Space.lg) {
            Toggle("I have read and acknowledge this contract for today", isOn: $acknowledged)
                .foregroundColor(Ink.ink)

            VStack(alignment: .leading, spacing: Space.sm) {
                Text("TODAY'S SINGLE HIGHEST-LEVERAGE ACTION")
                    .font(Type.captionSM)
                    .foregroundColor(Ink.mute)
                TextField("What is the ONE thing you must do today?", text: $actionText)
                    .fieldBox()
                    .frame(maxWidth: 760)
            }

            HStack(spacing: Space.xl) {
                PrimaryButton(title: "Confirm & Continue", enabled: canConfirm) {
                    model.confirm(action: actionText)
                }
                Text(statusMessage)
                    .font(Type.captionMD)
                    .foregroundColor(Ink.mute)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.xl)
        .background(Ink.containerLow)
    }
}
