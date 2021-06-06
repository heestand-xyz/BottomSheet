import SwiftUI

public struct BottomSheet<Content: View>: View {
    
    let cornerRadius: CGFloat = 25
    
    let content: () -> (Content)
    
    enum MotionStop {
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
    @State var state: MotionState = .idle(at: .custom(300))
    
    @State var maxHeight: CGFloat?
    
    @State var translation: CGFloat?

    public init(customStops: [CGFloat], includeHiddenStop: Bool = true, content: @escaping () -> (Content)) {
        self.content = content
        stops = (includeHiddenStop ? [.hidden] : []) + customStops.map({ MotionStop.custom($0) }) + [.full]
    }
    
    public var body: some View {
        GeometryReader { proxy in
            VStack {
                Spacer(minLength: 0)
                ZStack(alignment: .top) {
                    
                    ZStack {
                        BlurView()
                        content()
                            .padding(.bottom, cornerRadius)
                            .frame(height: height(), alignment: .top)
                    }
                    .clipShape(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    )
                    .padding(.bottom, -cornerRadius)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .frame(width: 36, height: 6)
                        .padding(6)
                        .opacity(0.25)
                        .frame(height: 0, alignment: .top)
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
            }
            .onAppear {
                maxHeight = proxy.size.height
            }
            .onChange(of: proxy.size.height) { height in
                maxHeight = height
            }
        }
        .edgesIgnoringSafeArea(.bottom)
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
        guard let maxHeight: CGFloat = maxHeight else { return nil }
        height = min(max(height, 0.0), maxHeight)
        return height
    }
    
    func onChanged(value: DragGesture.Value) {
        if !state.isDragging {
            state = .dragging(from: state.stop)
        }
        translation = value.translation.height
    }
    
    func onEnded(value: DragGesture.Value) {
        
        let predictedOffset: CGFloat = value.predictedEndLocation.y - value.startLocation.y
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
            
            BottomSheet(customStops: [300, 600]) {
                VStack {
                    Text("Top")
                    Spacer()
                    Text("Center")
                    Spacer()
                    Text("Bottom")
                }
                .padding(30)
            }
            
        }
        .colorScheme(.dark)
    }
}
