import SwiftUI
import PhotosUI
import Vision
import Translation
import UIKit

struct ContentView: View {
    @EnvironmentObject private var relay: SubtitleRelay
    @State private var pinInput = ""
    @State private var english = ""
    @State private var arabic = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var translationConfig: TranslationSession.Configuration?
    @State private var translating = false
    @State private var activity = "جاهز للتجربة"

    @State private var broadcastStatus = "لم يبدأ بث الشاشة بعد"
    @State private var capturedText = ""
    private let shared = UserDefaults(suiteName: "group.com.bdrtranslate.shared")

    private let purple = Color(red: 0.55, green: 0.33, blue: 0.96)

    var body: some View {
        ZStack {
            Color(red: 0.055, green: 0.052, blue: 0.09).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 12) {
                        Image(systemName: "captions.bubble.fill")
                            .font(.title).foregroundStyle(purple)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("BDr Translate").font(.title2.bold())
                            Text("iPhone v0.3 • اختبار بث الشاشة")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.bottom, 8)

                    card {
                        HStack {
                            Text("ربط الشاشة").font(.title3.bold())
                            Spacer()
                            Circle()
                                .fill(relay.isRunning ? .green : .orange)
                                .frame(width: 10, height: 10)
                        }
                        Text("اكتب كود التلفزيون المكوّن من 6 أرقام. الربط يبدأ تلقائيًا.")
                            .font(.subheadline).foregroundStyle(.secondary)
                        TextField("000000", text: $pinInput)
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .tracking(10)
                            .onChange(of: pinInput) { next in
                                let fixed = String(next.filter(\.isNumber).prefix(6))
                                if fixed != pinInput { pinInput = fixed }
                                if fixed.count == 6 { relay.start(pin: fixed) }
                            }
                            .padding(16)
                            .background(.black.opacity(0.28))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        Text(relay.status)
                            .font(.callout).foregroundStyle(relay.isRunning ? .green : .orange)
                    }

                    card {
                        Text("ترجمة إنجليزية ← عربية").font(.headline)
                        Text("الصق نصًا إنجليزيًا أو اختر صورة للحوار؛ يقرأ التطبيق النص ويترجمه محليًا إن كانت اللغة مدعومة.")
                            .font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $english)
                            .frame(height: 95)
                            .scrollContentBackground(.hidden)
                            .padding(8)
                            .background(.black.opacity(0.28))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(alignment: .topTrailing) {
                                if english.isEmpty {
                                    Text("اكتب الحوار الإنجليزي هنا…")
                                        .foregroundStyle(.gray)
                                        .padding(.top, 18).padding(.trailing, 14)
                                        .allowsHitTesting(false)
                                }
                            }
                        HStack {
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                Label("قراءة من صورة", systemImage: "text.viewfinder")
                                    .font(.subheadline)
                            }
                            .onChange(of: selectedPhoto) { item in
                                guard let item else { return }
                                Task { await readImage(item) }
                            }
                            Spacer()
                            Button {
                                translateEnglish()
                            } label: {
                                Label("ترجمة وإرسال", systemImage: "arrow.up.right")
                                    .font(.subheadline.bold())
                            }
                            .disabled(english.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || translating)
                        }
                        .tint(purple)
                        .buttonStyle(.borderedProminent)

                        if !arabic.isEmpty {
                            Text(arabic)
                                .font(.title3.weight(.semibold))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .padding(14)
                                .background(.black.opacity(0.28))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        Text(activity)
                            .font(.caption).foregroundStyle(.secondary)
                    }

                    card {
                        Text("التقاط شاشة PS5 • تجريبي").font(.headline)
                        Text("من مركز التحكم، اضغط مطولًا على تسجيل الشاشة واختر BDr Translate. قد يمنع PS Remote Play التقاط الفيديو.")
                            .font(.caption).foregroundStyle(.secondary)
                        Text(broadcastStatus).font(.callout)
                            .foregroundStyle(.cyan)
                        if !capturedText.isEmpty {
                            Text(capturedText)
                                .font(.footnote)
                                .lineLimit(5)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.black.opacity(0.25))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            Button("نقل النص المكتشف إلى الترجمة") {
                                english = capturedText
                                activity = "تم نقل النص؛ اضغط ترجمة وإرسال"
                            }
                            .buttonStyle(.borderedProminent).tint(purple)
                        }
                    }

                    card {
                        Text("اختبار عرض الترجمة").font(.headline)
                        Button("إرسال جملة عربية للتلفزيون") {
                            arabic = "اركب السيارة بسرعة! لازم نفلت من الشرطة!"
                            relay.send(arabic)
                            activity = "أُرسلت الجملة التجريبية للتلفزيون"
                        }
                        .buttonStyle(.borderedProminent).tint(purple)
                        .disabled(!relay.isRunning)
                        Button("مسح النص من الشاشة") { relay.send(""); arabic = "" }
                            .foregroundStyle(.secondary).disabled(!relay.isRunning)
                    }
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle")
                        Text("التقاط ReplayKit تجريبي؛ قد يمنع PS Remote Play تسجيل محتواه. معالجة النص والترجمة والإرسال التلقائي أثناء تشغيل تطبيق آخر ليست متاحة بعد.")
                    }
                    .font(.footnote).foregroundStyle(.secondary)
                    .padding(6)
                }
                .padding(20)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: refreshBroadcast)
        .onReceive(Timer.publish(every: 2, on: .main, in: .common).autoconnect()) { _ in
            refreshBroadcast()
        }
        .translationTask(translationConfig) { session in
            let source = english.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !source.isEmpty else { return }
            do {
                let result = try await session.translate(source)
                await MainActor.run {
                    arabic = result.targetText
                    translating = false
                    activity = "تمت الترجمة محليًا"
                    relay.send(result.targetText)
                }
            } catch {
                await MainActor.run {
                    translating = false
                    activity = "تعذرت الترجمة: \(error.localizedDescription). تحقق من توفر الإنجليزية والعربية وحزم اللغات."
                }
            }
        }
    }

    private func refreshBroadcast() {
        broadcastStatus = shared?.string(forKey: "broadcastStatus") ?? "لم يبدأ بث الشاشة بعد"
        capturedText = shared?.string(forKey: "latestRecognizedText") ?? ""
    }

    private func translateEnglish() {
        guard !english.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        translating = true
        activity = "جاري الترجمة المحلية…"
        if translationConfig == nil {
            translationConfig = TranslationSession.Configuration(
                source: Locale.Language(identifier: "en"),
                target: Locale.Language(identifier: "ar")
            )
        } else {
            translationConfig?.invalidate()
        }
    }

    private func readImage(_ item: PhotosPickerItem) async {
        await MainActor.run { activity = "جاري قراءة نص الصورة…" }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data),
                  let cgImage = uiImage.cgImage else {
                await MainActor.run { activity = "تعذر فتح الصورة" }
                return
            }
            let recognized: String = try await Task.detached(priority: .userInitiated) {
                let req = VNRecognizeTextRequest()
                req.recognitionLevel = .accurate
                req.recognitionLanguages = ["en-US"]
                req.usesLanguageCorrection = true
                try VNImageRequestHandler(cgImage: cgImage).perform([req])
                return (req.results ?? [])
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: " ")
            }.value
            await MainActor.run {
                english = recognized
                activity = recognized.isEmpty
                    ? "ما لقيت نص إنجليزي واضحًا في الصورة"
                    : "تم استخراج النص؛ اضغط «ترجمة وإرسال»"
            }
        } catch {
            await MainActor.run { activity = "خطأ قراءة الصورة: \(error.localizedDescription)" }
        }
    }

    @ViewBuilder
    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 13, content: content)
            .padding(19)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.12, green: 0.11, blue: 0.18))
            .clipShape(RoundedRectangle(cornerRadius: 19))
    }
}
