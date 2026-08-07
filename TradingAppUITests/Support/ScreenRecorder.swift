import AVFoundation
import CoreGraphics
import Foundation
import XCTest

/// Records a UI test flow as an H.264 `.mp4`.
///
/// XCTest has no public API for grabbing the simulator's screen recording, so
/// this samples `XCUIScreen.main.screenshot()` on a background queue while the
/// test drives the app, then encodes the frames with `AVAssetWriter`. The
/// resulting file is attached to the test report, and Bitrise collates `.mp4`
/// attachments from the xcresult onto the test result page.
final class ScreenRecorder {
    private let framesPerSecond: Int
    private let targetWidth: Int

    private let stateLock = NSLock()
    private var isRecording = false
    private var frames: [CGImage] = []
    private var captureQueue: DispatchQueue?

    init(framesPerSecond: Int = 8, targetWidth: Int = 360) {
        self.framesPerSecond = max(1, framesPerSecond)
        self.targetWidth = targetWidth
    }

    // MARK: - Capture

    func start() {
        stateLock.lock()
        guard !isRecording else {
            stateLock.unlock()
            return
        }
        isRecording = true
        frames.removeAll()
        stateLock.unlock()

        let queue = DispatchQueue(label: "io.bitrise.tradingapp.screen-recorder", qos: .userInitiated)
        captureQueue = queue
        queue.async { [weak self] in
            guard let self else { return }
            let interval = 1.0 / Double(self.framesPerSecond)
            while self.recordingIsActive {
                self.captureFrame()
                Thread.sleep(forTimeInterval: interval)
            }
        }
    }

    /// Captures a single frame. Safe to call directly for a deterministic frame
    /// at a known point in a flow.
    func captureFrame() {
        let screenshot = XCUIScreen.main.screenshot()
        guard let scaled = scale(screenshot.image.cgImage) else { return }
        stateLock.lock()
        frames.append(scaled)
        stateLock.unlock()
    }

    private var recordingIsActive: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return isRecording
    }

    /// Stops recording and writes the collected frames to an `.mp4`.
    func stop() -> URL? {
        stateLock.lock()
        isRecording = false
        let captured = frames
        frames.removeAll()
        stateLock.unlock()

        guard captured.count > 1 else { return nil }
        return encode(frames: captured)
    }

    // MARK: - Attaching

    /// Stops the recording and attaches the video to `testCase`.
    @discardableResult
    func attachVideo(to testCase: XCTestCase, name: String) -> URL? {
        guard let url = stop() else {
            XCTFail("Screen recording produced no frames")
            return nil
        }
        let attachment = XCTAttachment(contentsOfFile: url, uniformTypeIdentifier: "public.mpeg-4")
        attachment.name = name
        attachment.lifetime = .keepAlways
        testCase.add(attachment)
        return url
    }

    // MARK: - Encoding

    private func scale(_ image: CGImage?) -> CGImage? {
        guard let image else { return nil }
        let ratio = CGFloat(image.height) / CGFloat(image.width)
        let width = targetWidth
        // H.264 requires even dimensions.
        let height = Int((CGFloat(width) * ratio).rounded()) & ~1

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else { return nil }

        context.interpolationQuality = .medium
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }

    private func encode(frames: [CGImage]) -> URL? {
        guard let first = frames.first else { return nil }
        let size = CGSize(width: first.width, height: first.height)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("uitest-recording-\(UUID().uuidString).mp4")

        guard let writer = try? AVAssetWriter(outputURL: url, fileType: .mp4) else { return nil }

        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(size.width),
            AVVideoHeightKey: Int(size.height)
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = false

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
                kCVPixelBufferWidthKey as String: Int(size.width),
                kCVPixelBufferHeightKey as String: Int(size.height)
            ]
        )

        guard writer.canAdd(input) else { return nil }
        writer.add(input)
        guard writer.startWriting() else { return nil }
        writer.startSession(atSourceTime: .zero)

        for (index, frame) in frames.enumerated() {
            guard let buffer = pixelBuffer(from: frame, pool: adaptor.pixelBufferPool, size: size) else { continue }
            let time = CMTime(value: CMTimeValue(index), timescale: CMTimeScale(framesPerSecond))
            while !input.isReadyForMoreMediaData {
                Thread.sleep(forTimeInterval: 0.01)
            }
            adaptor.append(buffer, withPresentationTime: time)
        }

        input.markAsFinished()

        let finished = DispatchSemaphore(value: 0)
        writer.finishWriting { finished.signal() }
        _ = finished.wait(timeout: .now() + 30)

        guard writer.status == .completed else { return nil }
        return url
    }

    private func pixelBuffer(from image: CGImage, pool: CVPixelBufferPool?, size: CGSize) -> CVPixelBuffer? {
        var buffer: CVPixelBuffer?
        if let pool {
            CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer)
        } else {
            CVPixelBufferCreate(
                nil,
                Int(size.width),
                Int(size.height),
                kCVPixelFormatType_32ARGB,
                [kCVPixelBufferCGImageCompatibilityKey: true] as CFDictionary,
                &buffer
            )
        }
        guard let pixelBuffer = buffer else { return nil }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pixelBuffer),
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else { return nil }

        context.draw(image, in: CGRect(origin: .zero, size: size))
        return pixelBuffer
    }
}
