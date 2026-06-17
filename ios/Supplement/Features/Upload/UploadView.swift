import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

@Observable
final class UploadViewModel {
    var busy = false
    var error: String?
    var uploadedReportId: String?

    func upload(data: Data, contentType: String) async {
        busy = true; error = nil
        defer { busy = false }
        do {
            uploadedReportId = try await ReportService.uploadReport(data: data, contentType: contentType)
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct UploadView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm = UploadViewModel()
    @State private var showScanner = false
    @State private var photoItem: PhotosPickerItem?
    @State private var showFileImporter = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Add a lab report")
                    .font(.title2.bold())
                Text("Use a PDF or photo from your provider. We'll extract the values and let you confirm them before anything is analyzed.")
                    .font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)

                Button { showScanner = true } label: {
                    Label("Scan a printout", systemImage: "doc.viewfinder").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label("Choose a photo", systemImage: "photo").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button { showFileImporter = true } label: {
                    Label("Import a PDF", systemImage: "doc").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                if vm.busy { ProgressView("Uploading…") }
                if let error = vm.error { Text(error).font(.footnote).foregroundStyle(.red) }

                Spacer()
                DisclaimerBanner()
            }
            .padding()
            .navigationTitle("Upload")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .fullScreenCover(isPresented: $showScanner) {
                DocumentScanner { data in
                    if let data { Task { await vm.upload(data: data, contentType: "application/pdf") } }
                }
                .ignoresSafeArea()
            }
            .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.pdf]) { result in
                if case .success(let url) = result {
                    Task {
                        guard url.startAccessingSecurityScopedResource() else { return }
                        defer { url.stopAccessingSecurityScopedResource() }
                        if let data = try? Data(contentsOf: url) {
                            await vm.upload(data: data, contentType: "application/pdf")
                        }
                    }
                }
            }
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        await vm.upload(data: data, contentType: "image/jpeg")
                    }
                }
            }
            .onChange(of: vm.uploadedReportId) { _, id in
                if id != nil { dismiss() }   // report now appears on Home; user opens it to review
            }
        }
    }
}
