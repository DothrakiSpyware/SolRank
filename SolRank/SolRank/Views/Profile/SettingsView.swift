import SwiftUI
import MessageUI
import FirebaseAuth
import FirebaseFirestore

struct SettingsView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @EnvironmentObject private var gameVM: GameViewModel

    @State private var showSignOutConfirm = false
    @State private var showDeleteConfirm1 = false
    @State private var showDeleteConfirm2 = false
    @State private var showEditName = false
    @State private var editedName = ""
    @State private var showComingSoon = false
    @State private var mailContext: MailContext?
    @State private var showMailUnavailable = false
    @State private var webURL: WebLink?

    var body: some View {
        NavigationStack {
            List {
                accountSection
                appSection
                if AppConfig.isBeta { betaSection }
                legalSection
                if AppConfig.isBeta {
                    Section {
                        betaBanner
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Profile")
            .alert("Sign Out?", isPresented: $showSignOutConfirm) {
                Button("Sign Out", role: .destructive) { authVM.signOut() }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Delete Account?", isPresented: $showDeleteConfirm1) {
                Button("Continue", role: .destructive) { showDeleteConfirm2 = true }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure?")
            }
            .alert("This cannot be undone", isPresented: $showDeleteConfirm2) {
                Button("Delete Everything", role: .destructive) { Task { await deleteAccount() } }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("All your data will be deleted permanently.")
            }
            .alert("Coming Soon", isPresented: $showComingSoon) {
                Button("OK", role: .cancel) {}
            }
            .alert("Mail Not Available", isPresented: $showMailUnavailable) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Set up the Mail app or email us at \(AppConfig.feedbackEmail)")
            }
            .sheet(item: $mailContext) { ctx in
                MailComposer(recipient: AppConfig.feedbackEmail, subject: ctx.subject, body: ctx.body)
            }
            .sheet(item: $webURL) { link in
                SafariWebView(url: link.url)
            }
            .sheet(isPresented: $showEditName) {
                editNameSheet
            }
        }
    }

    // MARK: - Account

    private var accountSection: some View {
        Section("Account") {
            Button {
                editedName = gameVM.character?.name ?? authVM.appUser?.displayName ?? ""
                showEditName = true
            } label: {
                LabeledContent("Display Name", value: gameVM.character?.name ?? authVM.appUser?.displayName ?? "—")
            }
            .foregroundStyle(.white)

            HStack {
                LabeledContent("Username", value: authVM.appUser?.displayName ?? "—")
                Spacer()
                Button("Change") { showComingSoon = true }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.gold)
            }

            LabeledContent("Email", value: authVM.appUser?.email ?? "—")

            Button("Sign Out", role: .destructive) { showSignOutConfirm = true }

            Button("Delete Account", role: .destructive) { showDeleteConfirm1 = true }
        }
    }

    // MARK: - App

    private var appSection: some View {
        Section("App") {
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                LabeledContent("Notifications", value: "iOS Settings")
            }
            .foregroundStyle(.white)
            LabeledContent("Dark Mode", value: "Always on")
            LabeledContent("Version", value: AppConfig.versionString)
        }
    }

    // MARK: - Beta

    private var betaSection: some View {
        Section("Beta Testing") {
            Text("You're using a pre-release version of SolRank. Thanks for testing!")
                .font(.system(size: 13))
                .foregroundStyle(.gray)
            Button("Report a Bug") { openMail(subject: "SolRank Bug Report", body: bugTemplate) }
                .foregroundStyle(Theme.gold)
            Button("Leave Feedback") { openMail(subject: "SolRank Feedback", body: feedbackTemplate) }
                .foregroundStyle(Theme.gold)
        }
    }

    private var bugTemplate: String {
        """

        ---
        \(AppConfig.versionString)
        Describe the bug:
        """
    }

    private var feedbackTemplate: String {
        """

        ---
        \(AppConfig.versionString)
        What's on your mind?
        """
    }

    // MARK: - Legal

    private var legalSection: some View {
        Section("Legal") {
            Button("Privacy Policy") { webURL = WebLink(url: URL(string: "https://solrank.app/privacy")!) }
                .foregroundStyle(.white)
            Button("Terms of Service") { webURL = WebLink(url: URL(string: "https://solrank.app/terms")!) }
                .foregroundStyle(.white)
        }
    }

    // MARK: - Beta banner

    private var betaBanner: some View {
        HStack(spacing: 8) {
            Text("BETA")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(Theme.gold))
            Text("Pre-release · \(AppConfig.versionString)")
                .font(.system(size: 12))
                .foregroundStyle(.gray)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Edit name sheet

    private var editNameSheet: some View {
        NavigationStack {
            Form {
                TextField("Display name", text: $editedName)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Edit Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showEditName = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Best-effort: persist on character if present.
                        Task { await saveDisplayName() }
                        showEditName = false
                    }
                    .disabled(editedName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.height(220)])
    }

    private func saveDisplayName() async {
        let trimmed = editedName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if var char = gameVM.character {
            char.name = trimmed
            // Save via Firestore directly; GameViewModel doesn't expose a rename helper.
            try? await GameService().saveCharacter(char)
        }
    }

    // MARK: - Mail / delete

    private func openMail(subject: String, body: String) {
        if MFMailComposeViewController.canSendMail() {
            mailContext = MailContext(subject: subject, body: body)
        } else {
            showMailUnavailable = true
        }
    }

    private func deleteAccount() async {
        guard let uid = authVM.appUser?.id else { return }
        let db = Firestore.firestore()
        try? await db.collection(Constants.Firestore.characters).document(uid).delete()
        try? await db.collection(Constants.Firestore.users).document(uid).delete()
        if let user = Auth.auth().currentUser {
            try? await user.delete()
        }
        authVM.signOut()
    }
}

// MARK: - Helpers

private struct MailContext: Identifiable {
    let id = UUID()
    let subject: String
    let body: String
}

private struct WebLink: Identifiable {
    let id = UUID()
    let url: URL
}

private struct MailComposer: UIViewControllerRepresentable {
    let recipient: String
    let subject: String
    let body: String

    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setToRecipients([recipient])
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        vc.mailComposeDelegate = context.coordinator
        return vc
    }
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            controller.dismiss(animated: true)
        }
    }
}

private struct SafariWebView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        DispatchQueue.main.async {
            UIApplication.shared.open(url)
        }
        return vc
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
