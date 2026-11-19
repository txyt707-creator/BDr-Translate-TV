import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var relay: SubtitleRelay
    @State private var pinInput: String = ""
    @State private var subtitle: String = "لازم نطلع من هنا قبل ما توصل الشرطة!"

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.10).ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        HStack {
                            Image(systemName: "captions.bubble.fill").font(.title)
                            VStack(alignment: .leading) {
                                Text("BDr Translate").font(.title2.bold())
                                Text("iPhone • Local TV Link v0.1").font(.caption).foregroundStyle(.gray)
                            }
                            Spacer()
                        }
                        card {
                            Text("ربط التلفزيون").font(.headline)
                            Text("افتح تطبيق BDr على الشاشة، وخذ رمزها المكوّن من 6 أرقام ثم أدخله هنا.")
                                .font(.subheadline).foregroundStyle(.gray)
                            TextField("رمز التلفزيون: 6 أرقام", text: $pinInput)
                                .keyboardType(.numberPad).textContentType(.oneTimeCode)
                                .onChange(of: pinInput) { newValue in
                                    pinInput = String(newValue.filter { $0.isNumber }.prefix(6))
                                }
                                .padding(14).background(.black.opacity(0.35)).clipShape(RoundedRectangle(cornerRadius: 12))
                            Button {
                                relay.start(pin: pinInput)
                            } label: {
                                Label(relay.isRunning ? "إعادة تشغيل الربط" : "تشغيل الاتصال المحلي", systemImage: "wifi")
                                    .frame(maxWidth: .infinity).padding(12)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color(red: 0.52, green: 0.33, blue: 0.93))
                            .disabled(pinInput.count != 6)
                            Text(relay.status).font(.footnote).foregroundStyle(relay.isRunning ? .green : .orange)
                            if relay.isRunning {
                                Text("IP الآيفون: " + relay.deviceIP)
                                    .font(.callout.monospacedDigit()).textSelection(.enabled)
                                Text("اكتب IP الآيفون في شاشة التلفزيون مرة واحدة. ابقِ التطبيق مفتوحًا أثناء التجربة.")
                                    .font(.caption).foregroundStyle(.gray)
                            }
                        }
                        card {
                            Text("اختبار الترجمة العربية").font(.headline)
                            TextEditor(text: $subtitle)
                                .frame(height: 115).scrollContentBackground(.hidden)
                                .padding(8).background(.black.opacity(0.35)).clipShape(RoundedRectangle(cornerRadius: 12))
                            Button {
                                relay.send(subtitle)
                            } label: {
                                Label("إرسال النص للتلفزيون", systemImage: "paperplane.fill")
                                    .frame(maxWidth: .infinity).padding(12)
                            }.buttonStyle(.borderedProminent)
                                .tint(Color(red: 0.52, green: 0.33, blue: 0.93))
                                .disabled(!relay.isRunning)
                            Button("مسح الترجمة") { relay.send("") }
                                .foregroundStyle(.gray).disabled(!relay.isRunning)
                        }
                        Text("نسخة اختبار: إدخال النص يدوي فقط. قراءة PS5 وOCR وAI لم تُفعّل بعد.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    .padding(22)
                }
            }
            .preferredColorScheme(.dark)
            .navigationBarHidden(true)
        }
    }

    @ViewBuilder
    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 13, content: content)
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.12, green: 0.12, blue: 0.18))
            .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
