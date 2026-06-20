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
            ScrollView {
                VStack(spacing: 20) {
                    header

                    VStack(spacing: 16) {
                        SectionLabel("Add a report")

                        Button { showScanner = true } label: {
                            UploadOptionCard(
                                icon: "doc.viewfinder",
                                title: "Scan a printout",
                                subtitle: "Use your camera to capture pages",
                                tint: Theme.sageDeep
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(vm.busy)

                        PhotosPicker(selection: $photoItem, matching: .images) {
                            UploadOptionCard(
                                icon: "photo.on.rectangle.angled",
                                title: "Choose a photo",
                                subtitle: "Pick an existing image from your library",
                                tint: Theme.aqua
                            )
                        }
                        .disabled(vm.busy)

                        Button { showFileImporter = true } label: {
                            UploadOptionCard(
                                icon: "doc.fill",
                                title: "Import a PDF",
                                subtitle: "Add a PDF straight from your files",
                                tint: Theme.sage
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(vm.busy)
                    }

                    if vm.busy { uploadingCard }
                    if let error = vm.error { errorCard(error) }

                    DisclaimerBanner()
                }
                .padding(20)
            }
            .aeroScreen()
            .navigationTitle("Upload")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.tint(Theme.sageDeep) } }
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

    // MARK: - Pieces

    private var header: some View {
        VStack(spacing: 12) {
            LogoMark(size: 64)
            Text("Add a lab report")
                .font(Theme.title(26))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text("Use a PDF or photo from your provider. We'll extract the values and let you confirm them before anything is analyzed.")
                .font(Theme.rounded(.callout))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    private var uploadingCard: some View {
        GlassCard {
            HStack(spacing: 14) {
                ProgressView()
                    .tint(Theme.sageDeep)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Uploaded — processing")
                        .font(Theme.heading(17))
                        .foregroundStyle(Theme.ink)
                    Text("Reading your report. This only takes a moment.")
                        .font(Theme.rounded(.footnote))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer(minLength: 0)
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.aqua)
            }
        }
    }

    private func errorCard(_ message: String) -> some View {
        GlassCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Theme.color(for: .high))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Upload didn't go through")
                        .font(Theme.heading(17))
                        .foregroundStyle(Theme.ink)
                    Text(message)
                        .font(Theme.rounded(.footnote))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Please check the file and try again.")
                        .font(Theme.rounded(.footnote, weight: .medium))
                        .foregroundStyle(Theme.sageDeep)
                }
                Spacer(minLength: 0)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Theme.color(for: .high).opacity(0.45), lineWidth: 1.5)
        )
    }
}

// MARK: - Upload option card

/// Big glossy tappable card for each import method.
private struct UploadOptionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color

    var body: some View {
        GlassCard(padding: 18) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Theme.tintFill)
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LinearGradient(colors: [.white.opacity(0.55), .clear],
                                             startPoint: .top, endPoint: .center))
                        .padding(1)
                    Image(systemName: icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(tint)
                }
                .frame(width: 56, height: 56)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(.white.opacity(0.6), lineWidth: 1))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(Theme.heading(19))
                        .foregroundStyle(Theme.ink)
                    Text(subtitle)
                        .font(Theme.rounded(.footnote))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.sage)
            }
        }
    }
}
