import SwiftUI

public struct CustomizableSlider<
    Value: BinaryFloatingPoint,
    TrackBackground: View,
    TrackForeground: View,
    Thumb: View,
    Tooltip: View
>: View {
    @Binding var currentValue: Value
    
    private let range: ClosedRange<Value>
    private let step: Value
    private let magnetized: Bool
    private let trackBackground: () -> TrackBackground
    private let trackForeground: () -> TrackForeground
    private let thumb: () -> Thumb
    private let tooltip: () -> Tooltip
    private let onChanged: (() -> Void)?
    private let onEnded: (() -> Void)?
    
    @State private var percentage: Value = 1.0
    @State private var showTooltip = false
    @State private var tooltipSize: CGSize = .zero
    
    private var rangeDiff: Value {
        range.upperBound - range.lowerBound
    }
    
    public init(
        currentValue: Binding<Value>,
        range: ClosedRange<Value>,
        step: Value,
        magnetized: Bool = false,
        @ViewBuilder trackBackground: @escaping () -> TrackBackground,
        @ViewBuilder trackForeground: @escaping () -> TrackForeground = { EmptyView() },
        @ViewBuilder thumb: @escaping () -> Thumb,
        @ViewBuilder tooltip: @escaping () -> Tooltip = { EmptyView() },
        onChanged: (() -> Void)? = nil,
        onEnded: (() -> Void)? = nil
    ) {
        assert(step <= range.upperBound - range.lowerBound, "Step must be inside the range")
        
        _currentValue = currentValue
        
        self.range = range
        self.step = step
        self.magnetized = magnetized
        self.trackBackground = trackBackground
        self.trackForeground = trackForeground
        self.thumb = thumb
        self.tooltip = tooltip
        self.onChanged = onChanged
        self.onEnded = onEnded
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                trackBackground()
                
                trackForeground()
                    .frame(width: thumbCenterRelatedTo(geometry.size) + geometry.size.height)

                if showTooltip {
                    tooltip()
                        .measureSize {
                            tooltipSize =  $0
                        }
                        .offset(
                            x: thumbCenterRelatedTo(geometry.size) + tooltipSize.width / 2,
                            y: -geometry.size.height / 2 - tooltipSize.height / 2
                        )
                }
                
                thumb()
                    .position(
                        x: thumbCenterRelatedTo(geometry.size) + geometry.size.height / 2,
                        y: geometry.size.height / 2
                    )
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let availableWidth = geometry.size.width - geometry.size.height
                                let locationX = max(0, min(value.location.x - geometry.size.height / 2, availableWidth))
                                let xOffset = max(0, min(locationX, availableWidth))
                                let newValue = rangeDiff * Value(xOffset / availableWidth) + range.lowerBound
                                let steppedNewValue = (round(Value(newValue) / step) * step)
                                
                                currentValue = min(range.upperBound, max(range.lowerBound, Value(steppedNewValue)))
                                percentage = 1 - (range.upperBound - newValue) / (range.upperBound - range.lowerBound)
                                showTooltip = true
                                
                                onChanged?()
                            }
                            .onEnded { _ in
                                if magnetized {
                                    percentage = 1.0 - ((range.upperBound - currentValue) / rangeDiff)
                                }

                                showTooltip = false
                                
                                onEnded?()
                            }
                    )
            }
        }
    }
    
    private func thumbCenterRelatedTo(_ size: CGSize) -> CGFloat {
        (size.width - size.height) * CGFloat(percentage)
    }
}
