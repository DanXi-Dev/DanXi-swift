import SwiftUI
import DanXiKit

public struct MedalPage: View {
    let medal: Achievement
    @Binding var selectedMedal: Achievement?
    let namespace: Namespace.ID
    
    public var body: some View {
        Image(medal.name, bundle: .module)
            .onTapGesture {
                withAnimation {
                    selectedMedal = nil
                }
            }
            .matchedGeometryEffect(id: medal.name, in: namespace)
    }
}

#Preview {
    let sampleMedal = Achievement(name: "猫工智能", obtainDate: Date.now, domain: "")
    let dummyBinding: Binding<Achievement?> = Binding.constant(sampleMedal)
    let dummyNamespace = Namespace().wrappedValue
    MedalPage(medal: sampleMedal, selectedMedal: dummyBinding, namespace: dummyNamespace)
}
