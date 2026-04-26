import SwiftUI

#if os(macOS)
import AppKit

struct ZoomablePreviewScrollView<Content: View>: NSViewRepresentable {
    @Binding var zoom: Double

    let contentSize: CGSize
    let minZoom: Double
    let maxZoom: Double
    let content: () -> Content

    func makeCoordinator() -> Coordinator {
        Coordinator(zoom: $zoom)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = PinchTrackingScrollView()
        scrollView.onMagnificationChanged = { [weak coordinator = context.coordinator] magnification in
            coordinator?.syncZoomFromMagnification(magnification)
        }
        scrollView.contentView = CenteringClipView()
        scrollView.drawsBackground = false
        scrollView.hasHorizontalScroller = true
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        scrollView.allowsMagnification = true
        scrollView.minMagnification = minZoom
        scrollView.maxMagnification = maxZoom
        scrollView.verticalScrollElasticity = .allowed
        scrollView.horizontalScrollElasticity = .allowed
        scrollView.usesPredominantAxisScrolling = false

        let hostingView = NSHostingView(rootView: hostedContent)
        hostingView.translatesAutoresizingMaskIntoConstraints = true
        hostingView.frame = NSRect(origin: .zero, size: contentSize)
        scrollView.documentView = hostingView

        context.coordinator.scrollView = scrollView
        context.coordinator.hostingView = hostingView
        context.coordinator.applyZoom(PreviewZoom.clamped(zoom), animated: false)

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        scrollView.minMagnification = minZoom
        scrollView.maxMagnification = maxZoom

        let hostingView = context.coordinator.hostingView ?? NSHostingView(rootView: hostedContent)
        if hostingView.superview == nil {
            scrollView.documentView = hostingView
            context.coordinator.hostingView = hostingView
        }

        hostingView.rootView = hostedContent
        hostingView.frame = NSRect(origin: .zero, size: contentSize)

        let clampedZoom = PreviewZoom.clamped(zoom)
        if abs(scrollView.magnification - clampedZoom) > 0.001 {
            context.coordinator.applyZoom(clampedZoom, animated: false)
        }
    }

    private var hostedContent: AnyView {
        AnyView(
            content()
                .frame(width: contentSize.width, height: contentSize.height)
        )
    }

    final class Coordinator: NSObject {
        @Binding private var zoom: Double
        weak var scrollView: NSScrollView?
        var hostingView: NSHostingView<AnyView>?

        init(zoom: Binding<Double>) {
            _zoom = zoom
        }

        func applyZoom(_ newZoom: Double, animated: Bool) {
            guard let scrollView else { return }
            let centeredAt = NSPoint(
                x: scrollView.contentView.bounds.midX,
                y: scrollView.contentView.bounds.midY
            )
            scrollView.setMagnification(newZoom, centeredAt: centeredAt)
        }

        func syncZoomFromMagnification(_ magnification: Double) {
            let newZoom = PreviewZoom.clamped(magnification)
            if abs(zoom - newZoom) > 0.001 {
                DispatchQueue.main.async { [weak self] in
                    self?.zoom = newZoom
                }
            }
        }
    }

    final class PinchTrackingScrollView: NSScrollView {
        var onMagnificationChanged: ((Double) -> Void)?

        override func magnify(with event: NSEvent) {
            super.magnify(with: event)
            onMagnificationChanged?(magnification)
        }

        override func smartMagnify(with event: NSEvent) {
            super.smartMagnify(with: event)
            onMagnificationChanged?(magnification)
        }
    }

    final class CenteringClipView: NSClipView {
        override func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {
            var constrained = super.constrainBoundsRect(proposedBounds)
            guard let documentView else { return constrained }

            if documentView.frame.width < proposedBounds.width {
                constrained.origin.x = (documentView.frame.width - proposedBounds.width) / 2
            }

            if documentView.frame.height < proposedBounds.height {
                constrained.origin.y = (documentView.frame.height - proposedBounds.height) / 2
            }

            return constrained
        }
    }
}
#else
struct ZoomablePreviewScrollView<Content: View>: View {
    @Binding var zoom: Double

    let contentSize: CGSize
    let minZoom: Double
    let maxZoom: Double
    let content: () -> Content

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            content()
                .frame(width: contentSize.width, height: contentSize.height)
                .scaleEffect(zoom)
                .frame(
                    width: contentSize.width * zoom,
                    height: contentSize.height * zoom
                )
        }
    }
}
#endif
