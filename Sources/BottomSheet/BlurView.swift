//
//  Created by Anton Heestand on 2021-01-21.
//

import UIKit
import SwiftUI

public struct BlurView: UIViewRepresentable {
    
    @Environment(\.colorScheme) var colorScheme
    
    public init() {}
    
    public var style: UIBlurEffect.Style { colorScheme == .light ? .light : .dark }
    public var effect: UIVisualEffect { UIBlurEffect(style: style) }
    
    public func makeUIView(context: Self.Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: effect)
    }
    
    public func updateUIView(_ visualEffectView: UIVisualEffectView, context: Self.Context) {
        visualEffectView.effect = effect
    }
    
}
