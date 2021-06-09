import SwiftUI

public struct BottomSheet<Content: View>: View {
    
    let cornerRadius: CGFloat = 25
    
    public enum MotionStop {
        case hidden
        case full
        case custom(CGFloat)
    }
    let stops: [MotionStop]
    var sortedStops: [MotionStop] {
        stops.sorted(by: { aStop, bStop in
            self.height(stop: aStop) < self.height(stop: bStop)
        })
    }
    
    enum MotionState {
        case idle(at: MotionStop)
        case dragging(from: MotionStop)
        var stop: MotionStop {
            switch self {
            case .idle(at: let stop):
                return stop
            case .dragging(from: let stop):
                return stop
            }
        }
        var isIdle: Bool {
            if case .idle = self { return true }
            return false
        }
        var isDragging: Bool {
            if case .dragging = self { return true }
            return false
        }
    }
    @State var state: MotionState
    
    @State var maxHeight: CGFloat?
    
    @State var translation: CGFloat?
    
    let drawBackground: Bool
    
    public enum Position {
        case bottom
        case top
    }
    let position: Position
    
    let content: () -> (Content)
    
    public init(stops: [MotionStop],
                drawBackground: Bool = true,
                position: Position = .bottom,
                content: @escaping () -> (Content)) {
        precondition(!stops.isEmpty)
        self.stops = stops
        state = .idle(at: stops.first!)
        self.drawBackground = drawBackground
        self.position = position
        self.content = content
    }
    
    public var body: some View {
        GeometryReader { proxy in
            VStack {
                if position != .top {
                    Spacer(minLength: 0)
                }
                ZStack(alignment: position == .bottom ? .top : .bottom) {
                    
                    if drawBackground {
                        ZStack {
                            BlurView()
                            content()
                                .padding(.bottom, cornerRadius)
                                .frame(height: height(), alignment: position == .bottom ? .top : .bottom)
                        }
                        .clipShape(
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        )
                        .padding(.bottom, -cornerRadius)
                    } else {
                        content()
                            .frame(height: height(), alignment: .top)
                    }
                    
                    RoundedRectangle(cornerRadius: 3)
                        .frame(width: 36, height: 6)
                        .padding(6)
                        .opacity(0.25)
                        .frame(height: 0, alignment: position == .bottom ? .top : .bottom)
                }
                .frame(height: height() ?? 0.0)
                .gesture(
                    DragGesture(coordinateSpace: .global)
                        .onChanged { value in
                            onChanged(value: value)
                        }
                        .onEnded { value in
                            onEnded(value: value)
                        }
                )
                if position != .bottom {
                    Spacer(minLength: 0)
                }
            }
            .onAppear {
                maxHeight = proxy.size.height
            }
            .onChange(of: proxy.size.height) { height in
                maxHeight = height
            }
        }
    }
    
    func height() -> CGFloat? {
        var height: CGFloat
        switch state {
        case .idle:
            height = self.height(stop: state.stop)
        case .dragging:
            guard let translation: CGFloat = translation else { return nil }
            height = self.height(stop: state.stop) - translation
        }
        guard let firstStop: MotionStop = sortedStops.first else { return nil }
        guard let lastStop: MotionStop = sortedStops.last else { return nil }
        let minHeight: CGFloat = self.height(stop: firstStop)
        let maxHeight: CGFloat = self.height(stop: lastStop)
        height = min(max(height, minHeight), maxHeight)
        return height
    }
    
    func onChanged(value: DragGesture.Value) {
        if !state.isDragging {
            state = .dragging(from: state.stop)
        }
        var translation = value.translation.height
        if position == .top {
            translation = -translation
        }
        self.translation = translation
    }
    
    func onEnded(value: DragGesture.Value) {
        
        var predictedOffset: CGFloat = value.predictedEndLocation.y - value.startLocation.y
        if position == .top {
            predictedOffset = -predictedOffset
        }
        let predictedHeight: CGFloat = self.height(stop: state.stop) - predictedOffset
        
        var predictedStop: MotionStop!
        for i in 0..<(stops.count - 1) {
            let stop: MotionStop = sortedStops[i]
            let nextStop: MotionStop = sortedStops[i + 1]
            let stopHeight = self.height(stop: stop)
            let nextStopHeight = self.height(stop: nextStop)
            if predictedHeight < stopHeight {
                predictedStop = stop
                break
            } else if predictedHeight < nextStopHeight {
                let stopDistance: CGFloat = nextStopHeight - stopHeight
                if predictedHeight < stopHeight + stopDistance / 2 {
                    predictedStop = stop
                } else {
                    predictedStop = nextStop
                }
                break
            } else if i == stops.count - 2 {
                predictedStop = sortedStops.last!
                break
            }
        }
        
        withAnimation(.interactiveSpring(response: 0.25)) {
            state = .idle(at: predictedStop)
        }
        translation = nil
    }
    
    func height(stop: MotionStop) -> CGFloat {
        switch stop {
        case .hidden:
            return 0.0
        case .full:
            return maxHeight ?? 0.0
        case .custom(let height):
            return height
        }
    }
}

struct BottomSheet_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            
            Group {
                Color.primary
                    .colorInvert()
                Color.primary
                    .opacity(0.3)
            }
            .edgesIgnoringSafeArea(.all)
            
            BottomSheet(stops: [.custom(300), .custom(600), .full]) {
                VStack {
                    Text("Top")
                    Spacer()
                    Text("Center")
                    Spacer()
                    Text("Bottom")
                }
                .padding(30)
            }
            .edgesIgnoringSafeArea(.bottom)

        }
        .colorScheme(.dark)
    }
}
