import SwiftUI

/// Reactions a user can add to a feed event (beta set).
enum FeedReactions {
    static let options = ["🔥", "💪", "👏", "😤"]
}

struct FeedEventRowView: View {
    @ObservedObject var viewModel: FeedViewModel
    let event: FeedEvent

    @State private var showComments = false

    /// Always read the freshest copy so optimistic updates render live.
    private var live: FeedEvent {
        viewModel.feedEvents.first { $0.id == event.id } ?? event
    }

    private var accent: Color { live.statCategory?.color ?? Theme.gold }

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(accent)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 10) {
                header
                Text(live.message)
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)

                if let xp = live.xpGained, xp != 0 {
                    xpBadge(xp)
                }

                reactionRow
            }
            .padding(14)
        }
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.cardStroke, lineWidth: 1)
        )
        .sheet(isPresented: $showComments) {
            CommentsSheet(viewModel: viewModel, eventID: live.id)
        }
    }

    // MARK: - Pieces

    private var header: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(accent.opacity(0.85))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(String(live.authorUsername.prefix(1)).uppercased())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                )
            VStack(alignment: .leading, spacing: 1) {
                Text(live.authorUsername)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                Text(relativeTime(live.timestamp))
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
            }
            Spacer()
            if let category = live.statCategory {
                Text(category.icon).font(.system(size: 20))
            }
        }
    }

    private func xpBadge(_ xp: Int) -> some View {
        Text("+\(xp) XP")
            .font(.system(size: 13, weight: .heavy))
            .foregroundStyle(.black)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Theme.goldGradient)
            .clipShape(Capsule())
    }

    private var reactionRow: some View {
        HStack(spacing: 8) {
            ForEach(sortedReactions, id: \.key) { entry in
                ReactionPill(emoji: entry.key, count: entry.value) {
                    viewModel.addReaction(to: live, emoji: entry.key)
                }
            }

            Menu {
                ForEach(FeedReactions.options, id: \.self) { emoji in
                    Button {
                        viewModel.addReaction(to: live, emoji: emoji)
                    } label: {
                        Text("\(emoji)  React")
                    }
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.gray)
                    .frame(width: 30, height: 28)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
            }

            Spacer()

            Button {
                showComments = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "bubble.right")
                    Text("\(live.comments.count)")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.gray)
            }
            .buttonStyle(.plain)
        }
    }

    private var sortedReactions: [(key: String, value: Int)] {
        live.reactions
            .filter { $0.value > 0 }
            .sorted { $0.value > $1.value }
            .map { ($0.key, $0.value) }
    }

    private func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Reaction pill with tap animation

private struct ReactionPill: View {
    let emoji: String
    let count: Int
    let onTap: () -> Void

    @State private var bump = false

    var body: some View {
        Button {
            onTap()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) { bump = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { bump = false }
        } label: {
            HStack(spacing: 4) {
                Text(emoji).font(.system(size: 14))
                Text("\(count)").font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.10))
            .clipShape(Capsule())
            .scaleEffect(bump ? 1.25 : 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Comments sheet

private struct CommentsSheet: View {
    @ObservedObject var viewModel: FeedViewModel
    let eventID: String

    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""

    private var event: FeedEvent? {
        viewModel.feedEvents.first { $0.id == eventID }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        if let comments = event?.comments, !comments.isEmpty {
                            ForEach(comments) { comment in
                                commentRow(comment)
                            }
                        } else {
                            Text("No comments yet. Be the first.")
                                .font(.system(size: 14))
                                .foregroundStyle(.gray)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                        }
                    }
                    .padding(16)
                }

                composer
            }
            .background(Theme.background)
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func commentRow(_ comment: FeedComment) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(comment.authorUsername)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Text(comment.timestamp, style: .relative)
                    .font(.system(size: 11))
                    .foregroundStyle(.gray)
            }
            Text(comment.text)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .solCard()
    }

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("Add a comment…", text: $draft)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
                .foregroundStyle(.white)

            Button {
                guard let event else { return }
                viewModel.submitComment(on: event, text: draft)
                draft = ""
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(draft.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Theme.gold)
            }
            .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(12)
        .background(Theme.background)
    }
}
