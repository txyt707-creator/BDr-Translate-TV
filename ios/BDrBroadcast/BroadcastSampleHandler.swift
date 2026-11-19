import ReplayKit
import Vision
import CoreImage
import Foundation

/// Experimental ReplayKit receiver. It does not bypass protected video content.
final class BroadcastSampleHandler: RPBroadcastSampleHandler {
    private let shared = UserDefaults(suiteName: "group.com.bdrtranslate.shared")
    private let queue = DispatchQueue(label: "com.bdrtranslate.broadcast.ocr")
    private var lastScan = Date.distantPast
    private var busy = false

    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        shared?.set(true, forKey: "broadcastActive")
        shared?.set("بدأ بث الشاشة. نختبر إمكانية قراءة النص.", forKey: "broadcastStatus")
    }

    override func broadcastPaused() {
        shared?.set("البث متوقف مؤقتًا", forKey: "broadcastStatus")
    }

    override func broadcastResumed() {
        shared?.set("استؤنف بث الشاشة", forKey: "broadcastStatus")
    }

    override func broadcastFinished() {
        shared?.set(false, forKey: "broadcastActive")
        shared?.set("انتهى بث الشاشة", forKey: "broadcastStatus")
    }

    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        guard sampleBufferType == .video else { return }
        guard !busy, Date().timeIntervalSince(lastScan) >= 1.5 else { return }
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        lastScan = Date()
        busy = true
        queue.async { [weak self] in
            defer {
                self?.busy = false
            }
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .fast
            request.recognitionLanguages = ["en-US"]
            request.usesLanguageCorrection = true
            do {
                try VNImageRequestHandler(cvPixelBuffer: buffer).perform([request])
                let lines = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
                let text = lines.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty {
                    self?.shared?.set(text, forKey: "latestRecognizedText")
                    self?.shared?.set(Date().timeIntervalSince1970, forKey: "latestRecognizedAt")
                    self?.shared?.set("تم التعرف على نص من الشاشة", forKey: "broadcastStatus")
                } else {
                    self?.shared?.set("لم يُكتشف نص واضح؛ قد يكون محتوى اللعبة محميًا", forKey: "broadcastStatus")
                }
            } catch {
                self?.shared?.set("تعذرت قراءة الشاشة: \(error.localizedDescription)", forKey: "broadcastStatus")
            }
        }
    }
}
