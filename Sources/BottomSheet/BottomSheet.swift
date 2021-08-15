import SwiftUI

public enum MotionStop: Equatable {
    case hidden
    case full
    case custom(CGFloat)
}

public struct BottomSheet<Content: View>: View {
    
    let cornerRadius: CGFloat = 25
    
    let stops: [MotionStop]
    var sortedStops: [MotionStop] {
        stops.sorted(by: { aStop, bStop in
            self.height(stop: aStop) < self.height(stop: bStop)
        })
    }
    
    enum MotionState: Equatable {
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
    
    @Binding var heightGetter: CGFloat
    
    public init(stops: [MotionStop],
                drawBackground: Bool = true,
                position: Position = .bottom,
                heightGetter: Binding<CGFloat>? = nil,
                content: @escaping () -> (Content)) {
        precondition(!stops.isEmpty)
        self.stops = stops
        state = .idle(at: stops.first!)
        self.drawBackground = drawBackground
        self.position = position
        self.content = content
        _heightGetter = heightGetter ?? .constant(0.0)
    }
    
    public var body: some View {
        GeometryReader { geometry in
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
                maxHeight = geometry.size.height
                heightGetter = height(stop: state.stop)
            }
            .onChange(of: geometry.size.height) { height in
                maxHeight = height
            }
            .onChange(of: stops) { stops in
                let stop: MotionStop
                switch state.stop {
                case .hidden:
                    stop = .hidden
                case .full:
                    stop = .full
                case .custom(let customHeight):
                    stop = stops.filter({ stop in
                        if case .custom = stop {
                            return true
                        }
                        return false
                    }).sorted(by: { a, b in
                        abs(height(stop: a) - customHeight) < abs(height(stop: b) - customHeight)
                    }).first!
                }
                withAnimation {
                    state = .idle(at: stop)
                }
            }
            .onChange(of: state) { state in
                heightGetter = height(stop: state.stop)
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
        
        let predictedStop: MotionStop = stop(at: predictedHeight)
        
        withAnimation(.interactiveSpring(response: 0.25)) {
            state = .idle(at: predictedStop)
        }
        translation = nil
    }
    
    func stop(at targetHeight: CGFloat) -> MotionStop {
        var targetStop: MotionStop!
        for i in 0..<(stops.count - 1) {
            let stop: MotionStop = sortedStops[i]
            let nextStop: MotionStop = sortedStops[i + 1]
            let stopHeight = self.height(stop: stop)
            let nextStopHeight = self.height(stop: nextStop)
            if targetHeight < stopHeight {
                targetStop = stop
                break
            } else if targetHeight < nextStopHeight {
                let stopDistance: CGFloat = nextStopHeight - stopHeight
                if targetHeight < stopHeight + stopDistance / 2 {
                    targetStop = stop
                } else {
                    targetStop = nextStop
                }
                break
            } else if i == stops.count - 2 {
                targetStop = sortedStops.last!
                break
            }
        }
        return targetStop
    }
}

struct BottomSheet_Previews: SwiftUI.PreviewProvider {
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
