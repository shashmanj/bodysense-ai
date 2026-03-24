//
//  CommunityView.swift
//  body sense ai
//
//  Community Groups · Posts · Data Sharing
//

import SwiftUI

// MARK: - Community View

struct CommunityView: View {
    @Environment(HealthStore.self) var store
    @State private var selectedTab    = 0
    @State private var showPost       = false
    @State private var showCreateGroup = false
    @State private var selectedGroup  : CommunityGroup? = nil

    let tabs = ["Explore", "My Groups", "Doctors"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    ForEach(0..<tabs.count, id: \.self) { i in Text(tabs[i]).tag(i) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8).padding(.bottom, 10)
                .background(Color.brandBg)

                ScrollView {
                    VStack(spacing: 16) {
                        switch selectedTab {
                        case 0: DiscoverTab(selectedGroup: $selectedGroup, showCreateGroup: $showCreateGroup)
                        case 1: MyGroupsTab(selectedGroup: $selectedGroup, showPost: $showPost, switchToDiscover: { selectedTab = 0 })
                        case 2: PatientDoctorsTab()
                        default: EmptyView()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .padding(.bottom, 100) // space for tab bar
                }
                .background(Color.brandBg)
            }
            .navigationTitle("Community")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if selectedTab == 1 && !store.joinedGroups.isEmpty {
                        Button {
                            showPost = true
                        } label: {
                            Label("New Post", systemImage: "square.and.pencil")
                                .font(.subheadline.bold())
                                .foregroundColor(.brandPurple)
                        }
                    }
                }
            }
            .sheet(item: $selectedGroup) { group in GroupDetailView(group: group) }
            .sheet(isPresented: $showPost) { NewPostSheet() }
            .sheet(isPresented: $showCreateGroup) { CreateGroupSheet() }
        }
    }
}

// MARK: - Discover Tab

struct DiscoverTab: View {
    @Environment(HealthStore.self) var store
    @Binding var selectedGroup: CommunityGroup?
    @Binding var showCreateGroup: Bool
    @State private var searchText = ""
    @State private var selectedCat: GroupCategory? = nil
    @State private var myCityOnly = false

    var userCity: String { store.userProfile.city }

    var filtered: [CommunityGroup] {
        var groups = store.communityGroups
        if myCityOnly && !userCity.isEmpty {
            groups = groups.filter { $0.city.isEmpty || $0.city == userCity }
        }
        if let cat = selectedCat { groups = groups.filter { $0.category == cat } }
        if !searchText.isEmpty { groups = groups.filter { $0.name.localizedCaseInsensitiveContains(searchText) } }
        // Sort: user's city first → global → other cities
        if !userCity.isEmpty {
            groups.sort { a, b in
                let aScore = a.city == userCity ? 0 : (a.city.isEmpty ? 1 : 2)
                let bScore = b.city == userCity ? 0 : (b.city.isEmpty ? 1 : 2)
                return aScore < bScore
            }
        }
        return groups
    }

    var body: some View {
        Group {
            // Welcome banner
            HStack(spacing: 14) {
                Image(systemName: "person.3.sequence.fill")
                    .font(.title2).foregroundColor(.brandPurple)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Find Your Health Community")
                        .font(.subheadline.bold())
                    Text("Join groups, share experiences, and support each other.")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            .padding(14)
            .background(Color.brandPurple.opacity(0.06))
            .cornerRadius(14)

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search groups by name…", text: $searchText)
            }
            .padding(10)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .shadow(color: Color.primary.opacity(0.05), radius: 4, y: 2)

            // City + Create row
            HStack(spacing: 8) {
                if !userCity.isEmpty {
                    Button {
                        myCityOnly.toggle()
                    } label: {
                        Label(myCityOnly ? "📍 \(userCity)" : "📍 My City",
                              systemImage: myCityOnly ? "checkmark.circle.fill" : "location.circle")
                            .font(.caption.bold())
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(myCityOnly ? Color.brandPurple : Color.white)
                            .foregroundColor(myCityOnly ? .white : .brandPurple)
                            .cornerRadius(10)
                            .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
                    }
                }
                Spacer()
                // Prominent Create Group button
                Button { showCreateGroup = true } label: {
                    Label("Create Group", systemImage: "plus.circle.fill")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Color.brandTeal)
                        .cornerRadius(10)
                }
            }

            // Category filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(label: "All Categories", isSelected: selectedCat == nil) { selectedCat = nil }
                    ForEach(GroupCategory.allCases, id: \.self) { cat in
                        FilterChip(label: cat.rawValue, isSelected: selectedCat == cat) { selectedCat = cat }
                    }
                }
                .padding(.horizontal, 2)
            }

            // Results count
            if !searchText.isEmpty || selectedCat != nil || myCityOnly {
                HStack {
                    Text("\(filtered.count) group\(filtered.count == 1 ? "" : "s") found")
                        .font(.caption).foregroundColor(.secondary)
                    Spacer()
                    if searchText.isEmpty && selectedCat == nil && !myCityOnly {} else {
                        Button("Clear") {
                            searchText = ""; selectedCat = nil; myCityOnly = false
                        }
                        .font(.caption.bold()).foregroundColor(.brandPurple)
                    }
                }
            }

            // Groups list
            if filtered.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass").font(.system(size: 36))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("No groups match your search").font(.subheadline.bold())
                    Text("Try a different category, or start your own group!")
                        .font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
                    Button { showCreateGroup = true } label: {
                        Text("Create a Group")
                            .font(.subheadline.bold()).foregroundColor(.white)
                            .padding(.horizontal, 20).padding(.vertical, 10)
                            .background(Color.brandPurple).cornerRadius(12)
                    }
                }
                .padding()
            } else {
                ForEach(filtered) { group in
                    GroupCard(group: group) { selectedGroup = group }
                }
            }
        }
    }
}

// MARK: - My Groups Tab

struct MyGroupsTab: View {
    @Environment(HealthStore.self) var store
    @Binding var selectedGroup: CommunityGroup?
    @Binding var showPost: Bool
    let switchToDiscover: () -> Void

    var joined: [CommunityGroup] { store.communityGroups.filter { $0.isJoined } }

    var body: some View {
        Group {
            if joined.isEmpty {
                // Clear empty state with strong CTAs
                VStack(spacing: 20) {
                    Image(systemName: "person.3.sequence.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.brandPurple.opacity(0.25))
                    Text("You haven't joined any groups yet")
                        .font(.title3.bold())
                        .multilineTextAlignment(.center)
                    Text("Connect with thousands of people managing diabetes, hypertension, and more. Share your journey and get support.")
                        .font(.subheadline).foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                    VStack(spacing: 10) {
                        Button {
                            switchToDiscover()
                        } label: {
                            Label("Browse Health Groups", systemImage: "magnifyingglass")
                                .font(.headline).foregroundColor(.white)
                                .frame(maxWidth: .infinity).padding()
                                .background(Color.brandPurple).cornerRadius(14)
                        }
                        Text("or")
                            .font(.caption).foregroundColor(.secondary)
                        Button {
                            switchToDiscover()
                        } label: {
                            Text("Create Your Own Group")
                                .font(.subheadline.bold()).foregroundColor(.brandTeal)
                                .frame(maxWidth: .infinity).padding()
                                .background(Color.brandTeal.opacity(0.1)).cornerRadius(14)
                        }
                    }
                }
                .padding(24)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(20)
                .shadow(color: Color.primary.opacity(0.04), radius: 6, y: 3)
            } else {
                // My groups summary bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(joined) { group in
                            Button { selectedGroup = group } label: {
                                VStack(spacing: 5) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: group.color).opacity(0.15))
                                            .frame(width: 50, height: 50)
                                        Image(systemName: group.icon)
                                            .foregroundColor(Color(hex: group.color))
                                    }
                                    Text(group.name.split(separator: " ").first.map(String.init) ?? group.name)
                                        .font(.caption2).lineLimit(1).frame(width: 56)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 2)
                }

                // Write a post CTA
                Button { showPost = true } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.brandPurple.opacity(0.12))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Text(String(store.userProfile.name.prefix(1).uppercased()))
                                    .font(.subheadline.bold()).foregroundColor(.brandPurple)
                            )
                        Text("Share an update with your groups…")
                            .font(.subheadline).foregroundColor(.secondary)
                        Spacer()
                        Image(systemName: "photo.on.rectangle.angled")
                            .foregroundColor(.secondary)
                    }
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(14)
                    .shadow(color: Color.primary.opacity(0.04), radius: 4, y: 2)
                }
                .buttonStyle(.plain)

                // Posts feed
                ForEach(joined) { group in
                    if !group.posts.isEmpty {
                        HStack {
                            Text(group.name).font(.caption.bold()).foregroundColor(Color(hex: group.color))
                            Spacer()
                            Button { selectedGroup = group } label: {
                                Text("View group →").font(.caption).foregroundColor(.brandPurple)
                            }
                        }
                        .padding(.horizontal, 4)
                        ForEach(group.posts.prefix(2)) { post in
                            PostCard(post: post, groupName: group.name)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Data Sharing Tab

struct DataSharingTab: View {
    @Environment(HealthStore.self) var store
    @State private var sharingEnabled = true
    @State private var shareGlucose  = true
    @State private var shareBP       = true
    @State private var shareMeds     = false
    @State private var shareWeight   = false
    @State private var shareName     = ""
    @State private var shareEmail    = ""
    @State private var showInvite    = false

    var body: some View {
        Group {
            // Info card
            BSCard {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Secure Data Sharing", systemImage: "lock.shield.fill")
                        .font(.headline).foregroundColor(.brandPurple)
                    Text("Share your health data with family, caregivers, or doctors. You control what they can see.")
                        .font(.subheadline).foregroundColor(.secondary)
                }
            }

            // Sharing settings
            BSCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("What to share").font(.headline)
                    Toggle("Blood Glucose readings",  isOn: $shareGlucose).tint(.brandPurple)
                    Toggle("Blood Pressure readings", isOn: $shareBP).tint(.brandPurple)
                    Toggle("Medications",             isOn: $shareMeds).tint(.brandPurple)
                    Toggle("Weight & BMI",            isOn: $shareWeight).tint(.brandPurple)
                }
            }

            // Active shares
            BSCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Shared With").font(.headline)
                        Spacer()
                        Button { showInvite = true } label: {
                            Label("Invite", systemImage: "person.badge.plus")
                                .font(.subheadline).foregroundColor(.brandPurple)
                        }
                    }

                    // Sample shared contacts
                    ShareContactRow(name: "Dr. Amara Patel",  role: "Endocrinologist",  access: "View only",        initials: "AP", color: "#6C63FF")
                    ShareContactRow(name: "Maria (daughter)", role: "Family member",      access: "View & comment",   initials: "MD", color: "#FF6B6B")
                }
            }

            // Privacy note
            BSCard {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.shield.fill").font(.title2).foregroundColor(.brandGreen)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Your data is private").font(.subheadline.bold())
                        Text("All data sharing is end-to-end encrypted. Recipients can only see what you explicitly choose to share.")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showInvite) { InviteShareSheet() }
    }
}

// MARK: - Group Detail View

struct GroupDetailView: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss
    var group: CommunityGroup

    var idx: Int? { store.communityGroups.firstIndex(where: { $0.id == group.id }) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    ZStack {
                        LinearGradient(colors: [Color(hex: group.color), Color(hex: group.color).opacity(0.7)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                            .frame(height: 150)
                        VStack(spacing: 8) {
                            Image(systemName: group.icon).font(.system(size: 44)).foregroundColor(.white)
                            Text(group.name).font(.title3.bold()).foregroundColor(.white).multilineTextAlignment(.center)
                        }
                    }

                    VStack(spacing: 16) {
                        // Stats row
                        HStack {
                            GroupStatPill(label: "Members", value: "\(group.memberCount.formatted())")
                            GroupStatPill(label: "Posts", value: "\(group.posts.count + 12)")
                            GroupStatPill(label: "Category", value: group.category.rawValue)
                        }
                        .padding(.horizontal)

                        // Description
                        BSCard {
                            Text(group.description).font(.subheadline).foregroundColor(.secondary)
                        }
                        .padding(.horizontal)

                        // Join / Leave button
                        Button {
                            if let i = idx {
                                store.communityGroups[i].isJoined.toggle()
                                store.save()
                            }
                        } label: {
                            let joined = idx.map { store.communityGroups[$0].isJoined } ?? group.isJoined
                            Label(joined ? "Leave Group" : "Join Group",
                                  systemImage: joined ? "person.badge.minus" : "person.badge.plus")
                                .font(.headline).foregroundColor(.white)
                                .frame(maxWidth: .infinity).padding()
                                .background(joined ? Color.gray : Color(hex: group.color))
                                .cornerRadius(16)
                        }
                        .padding(.horizontal)

                        // Challenges
                        if !group.challenges.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Group Challenges").font(.headline).padding(.horizontal)
                                ForEach(group.challenges) { challenge in
                                    GroupChallengeCard(challenge: challenge).padding(.horizontal)
                                }
                            }
                        }

                        // Posts
                        if !group.posts.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Recent Posts").font(.headline).padding(.horizontal)
                                ForEach(group.posts) { post in
                                    PostCard(post: post, groupName: group.name).padding(.horizontal)
                                }
                            }
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                    }
                }
            }
        }
    }
}

// MARK: - Group Card

struct GroupCard: View {
    @Environment(HealthStore.self) var store
    var group: CommunityGroup
    var onTap: () -> Void

    var idx: Int? { store.communityGroups.firstIndex(where: { $0.id == group.id }) }

    var body: some View {
        BSCard {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: group.color).opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: group.icon)
                        .font(.title3).foregroundColor(Color(hex: group.color))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name).font(.subheadline.bold())
                    Text(group.description).font(.caption).foregroundColor(.secondary).lineLimit(2)
                    HStack(spacing: 6) {
                        Image(systemName: "person.2.fill").font(.caption2).foregroundColor(.secondary)
                        Text("\(group.memberCount.formatted()) members").font(.caption2).foregroundColor(.secondary)
                        Text("·").foregroundColor(.secondary)
                        Text(group.category.rawValue).font(.caption2)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color(hex: group.color).opacity(0.15))
                            .foregroundColor(Color(hex: group.color)).cornerRadius(6)
                    }
                }
                Spacer()
                VStack(spacing: 6) {
                    Button {
                        if let i = idx {
                            store.communityGroups[i].isJoined.toggle()
                            store.save()
                        }
                    } label: {
                        let joined = idx.map { store.communityGroups[$0].isJoined } ?? group.isJoined
                        Text(joined ? "Joined" : "Join")
                            .font(.caption.bold())
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(joined ? Color.brandGreen.opacity(0.15) : Color(hex: group.color))
                            .foregroundColor(joined ? .brandGreen : .white)
                            .cornerRadius(10)
                    }
                    Button(action: onTap) {
                        Text("View")
                            .font(.caption)
                            .foregroundColor(.brandPurple)
                    }
                }
            }
        }
    }
}

// MARK: - Post Card

struct PostCard: View {
    @Environment(HealthStore.self) var store
    @State var post: CommunityPost
    let groupName: String

    var body: some View {
        BSCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    // Avatar
                    ZStack {
                        Circle().fill(Color(hex: post.avatarColor)).frame(width: 36, height: 36)
                        Text(post.initials).font(.caption.bold()).foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(post.author).font(.subheadline.bold())
                        Text(post.date.timeAgo + " · " + groupName).font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    if !post.tag.isEmpty {
                        Text(post.tag).font(.caption2.bold())
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.brandPurple.opacity(0.1))
                            .foregroundColor(.brandPurple).cornerRadius(8)
                    }
                }

                if post.isHidden {
                    Text("This post has been hidden")
                        .font(.subheadline).foregroundColor(.secondary).italic()
                } else {
                    Text(post.content).font(.subheadline)

                    // Activity data pills
                    if let activity = post.activityData {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ActivityPill(icon: "figure.walk", value: "\(activity.steps)", label: "steps", color: .brandGreen)
                                ActivityPill(icon: "map", value: String(format: "%.1f km", activity.distance), label: "", color: .brandTeal)
                                ActivityPill(icon: "flame.fill", value: "\(activity.calories)", label: "cal", color: .brandCoral)
                                ActivityPill(icon: "timer", value: "\(activity.activeMinutes)", label: "min", color: .brandPurple)
                            }
                        }
                    }
                }

                HStack(spacing: 16) {
                    Button {
                        post.isLiked.toggle()
                        post.likes += post.isLiked ? 1 : -1
                    } label: {
                        Label("\(post.likes)", systemImage: post.isLiked ? "heart.fill" : "heart")
                            .font(.caption).foregroundColor(post.isLiked ? .brandCoral : .secondary)
                    }
                    Label("\(post.comments)", systemImage: "bubble.left")
                        .font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: "square.and.arrow.up").font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .contextMenu {
            if !post.isOwnPost && !post.isHidden {
                Button(role: .destructive) {
                    let alias = store.userProfile.anonymousAlias
                    if !post.reportedBy.contains(alias) {
                        post.reportCount += 1
                        post.reportedBy.append(alias)
                        if post.reportCount >= 3 {
                            post.isHidden = true
                        }
                        // Persist to store
                        for gi in store.communityGroups.indices {
                            if let pi = store.communityGroups[gi].posts.firstIndex(where: { $0.id == post.id }) {
                                store.communityGroups[gi].posts[pi] = post
                            }
                        }
                        store.save()
                    }
                } label: {
                    Label("Report Post", systemImage: "exclamationmark.triangle")
                }
            }
        }
    }
}

// MARK: - New Post Sheet

// MARK: - PII Content Filter (blocks phone numbers, emails, bank details)

private func containsPII(_ text: String) -> (Bool, String) {
    let patterns: [(String, String)] = [
        // UK mobile: 07xxx, +447xxx, 00447xxx
        (#"(?<!\d)(07\d{3}\s?\d{6}|\+44\s?7\d{3}\s?\d{6}|00447\d{9})(?!\d)"#,
         "phone numbers"),
        // International phone patterns (10+ digits)
        (#"(?<!\d)\+?\d[\d\s\-]{9,15}\d(?!\d)"#,
         "phone numbers"),
        // Email addresses
        (#"[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}"#,
         "email addresses"),
        // UK sort codes: XX-XX-XX
        (#"\b\d{2}[\s\-]\d{2}[\s\-]\d{2}\b"#,
         "bank sort codes"),
        // 8-digit account numbers (standalone)
        (#"(?<!\d)\d{8}(?!\d)"#,
         "bank account numbers"),
        // IBAN patterns
        (#"\b[A-Z]{2}\d{2}\s?[\dA-Z]{4}\s?[\dA-Z]{4}\s?[\dA-Z]{4}\s?[\dA-Z]{0,4}\b"#,
         "IBAN numbers"),
        // Card numbers (16 digits with optional spaces/dashes)
        (#"\b\d{4}[\s\-]?\d{4}[\s\-]?\d{4}[\s\-]?\d{4}\b"#,
         "card numbers")
    ]

    for (pattern, label) in patterns {
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil {
            return (true, label)
        }
    }
    return (false, "")
}

struct NewPostSheet: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss
    @State private var text = ""
    @State private var selectedGroup: CommunityGroup? = nil
    @State private var shareActivity = false
    @State private var showPIIAlert = false
    @State private var piiType = ""

    var joined: [CommunityGroup] { store.communityGroups.filter { $0.isJoined } }

    var body: some View {
        NavigationStack {
            Form {
                Section("Post to") {
                    if joined.isEmpty {
                        Text("Join a group first to post.").foregroundColor(.secondary)
                    } else {
                        Picker("Group", selection: $selectedGroup) {
                            Text("Select group").tag(Optional<CommunityGroup>.none)
                            ForEach(joined) { g in Text(g.name).tag(Optional(g)) }
                        }
                    }
                }
                Section("Your post") {
                    TextEditor(text: $text)
                        .frame(minHeight: 120)
                        .onChange(of: text) { if text.count > 2000 { text = String(text.prefix(2000)) } }
                    Text("\(text.count)/2000")
                        .font(.caption2).foregroundColor(text.count >= 2000 ? .red : .secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                Section {
                    Toggle("Share today's activity data", isOn: $shareActivity)
                        .tint(.brandPurple)
                    if shareActivity {
                        HStack(spacing: 12) {
                            Label("\(store.todaySteps) steps", systemImage: "figure.walk").font(.caption)
                            Spacer()
                            Label("\(store.todaySteps / 20) cal", systemImage: "flame.fill").font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Activity")
                } footer: {
                    Text("Your post will appear under your anonymous alias: \(store.userProfile.anonymousAlias.isEmpty ? "Anonymous" : store.userProfile.anonymousAlias)")
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        // ── PII Safety Check ──
                        let (hasPII, detectedType) = containsPII(text)
                        if hasPII {
                            piiType = detectedType
                            showPIIAlert = true
                            return
                        }
                        store.ensureAnonymousAlias()
                        if let group = selectedGroup,
                           let idx = store.communityGroups.firstIndex(where: { $0.id == group.id }) {
                            let alias = store.userProfile.anonymousAlias
                            let aliasInitials = String(alias.prefix(2)).uppercased()
                            let activityData: SharedActivityData? = shareActivity ? SharedActivityData(
                                steps: store.todaySteps,
                                distance: Double(store.todaySteps) * 0.00078,
                                calories: store.todaySteps / 20,
                                activeMinutes: 0,
                                date: Date()
                            ) : nil
                            let newPost = CommunityPost(
                                author: alias,
                                initials: aliasInitials,
                                avatarColor: store.userProfile.anonymousColor.isEmpty ? "#6C63FF" : store.userProfile.anonymousColor,
                                content: text, date: Date(), likes: 0, comments: 0,
                                activityData: activityData,
                                isOwnPost: true)
                            store.communityGroups[idx].posts.insert(newPost, at: 0)
                            store.save()
                        }
                        dismiss()
                    }.disabled(text.isEmpty || selectedGroup == nil)
                }
            }
            .alert("Content Blocked", isPresented: $showPIIAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your post contains \(piiType). For your safety, sharing personal contact or financial information in community groups is not allowed. Please remove this information and try again.")
            }
        }
    }
}

// MARK: - Invite Share Sheet

struct InviteShareSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var name  = ""
    @State private var email = ""
    @State private var access = "View only"

    var body: some View {
        NavigationStack {
            Form {
                Section("Person to invite") {
                    TextField("Name", text: $name)
                    TextField("Email address", text: $email).keyboardType(.emailAddress)
                }
                Section("Access level") {
                    Picker("Access", selection: $access) {
                        Text("View only").tag("View only")
                        Text("View & comment").tag("View & comment")
                    }.pickerStyle(.segmented)
                }
                Section {
                    Text("They will receive an email invite to join BodySense AI and view your shared health data.")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            .navigationTitle("Invite to Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send Invite") { dismiss() }.disabled(name.isEmpty || email.isEmpty)
                }
            }
        }
    }
}

// MARK: - Create Group Sheet

struct CreateGroupSheet: View {
    @Environment(HealthStore.self) var store
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var category: GroupCategory = .wellness
    @State private var icon = "person.3.fill"
    @State private var color = "#6C63FF"

    let iconOptions = ["person.3.fill", "figure.walk", "heart.fill", "drop.fill", "fork.knife.circle.fill", "scalemass.fill", "brain.head.profile", "leaf.fill"]
    let colorOptions = ["#6C63FF", "#FF6B6B", "#4ECDC4", "#FF9F43", "#26de81", "#4834d4", "#e056fd", "#22a6b3"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Group details") {
                    TextField("Group name", text: $name)
                    Text("\(name.count)/50")
                        .font(.caption2).foregroundColor(name.count > 50 ? .red : .secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    Picker("Category", selection: $category) {
                        ForEach(GroupCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                }
                Section("Icon") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(iconOptions, id: \.self) { ic in
                                Button {
                                    icon = ic
                                } label: {
                                    Image(systemName: ic)
                                        .font(.title3)
                                        .frame(width: 44, height: 44)
                                        .background(icon == ic ? Color(hex: color) : Color.gray.opacity(0.15))
                                        .foregroundColor(icon == ic ? .white : .primary)
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }
                }
                Section("Color") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(colorOptions, id: \.self) { c in
                                Button {
                                    color = c
                                } label: {
                                    Circle()
                                        .fill(Color(hex: c))
                                        .frame(width: 36, height: 36)
                                        .overlay(color == c ? Circle().stroke(Color.primary, lineWidth: 2) : nil)
                                }
                            }
                        }
                    }
                }
                Section {
                    Text("Your group will be visible to users in \(store.userProfile.city.isEmpty ? "all cities" : store.userProfile.city). You'll appear as \(store.userProfile.anonymousAlias.isEmpty ? "Anonymous" : store.userProfile.anonymousAlias).")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            .navigationTitle("Create Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        store.ensureAnonymousAlias()
                        let newGroup = CommunityGroup(
                            name: name,
                            description: description,
                            category: category,
                            memberCount: 1,
                            isJoined: true,
                            icon: icon,
                            color: color,
                            city: store.userProfile.city,
                            isUserCreated: true,
                            creatorAlias: store.userProfile.anonymousAlias
                        )
                        store.communityGroups.insert(newGroup, at: 0)
                        store.save()
                        dismiss()
                    }
                    .disabled(!InputValidator.isValidGroupName(name))
                }
            }
        }
    }
}

// MARK: - Group Challenge Card

struct GroupChallengeCard: View {
    var challenge: GroupChallenge

    var body: some View {
        BSCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "trophy.fill").foregroundColor(.brandAmber)
                    Text(challenge.title).font(.subheadline.bold())
                    Spacer()
                    Text("\(challenge.participants) joined").font(.caption2).foregroundColor(.secondary)
                }
                Text(challenge.description).font(.caption).foregroundColor(.secondary)
                // Progress bar
                VStack(alignment: .leading, spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.brandAmber.opacity(0.15)).frame(height: 8)
                            Capsule().fill(Color.brandAmber).frame(width: geo.size.width * challenge.progress, height: 8)
                        }
                    }
                    .frame(height: 8)
                    HStack {
                        Text("\(Int(challenge.currentValue)) / \(Int(challenge.targetValue)) \(challenge.unit)")
                            .font(.caption2).foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(challenge.progress * 100))%")
                            .font(.caption2.bold()).foregroundColor(.brandAmber)
                    }
                }
            }
        }
    }
}

// MARK: - Activity Pill

struct ActivityPill: View {
    let icon: String; let value: String; let label: String; let color: Color
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2)
            Text(value + (label.isEmpty ? "" : " \(label)")).font(.caption2.bold())
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(color.opacity(0.12))
        .foregroundColor(color)
        .cornerRadius(10)
    }
}

// MARK: - Helper Subviews

struct GroupStatPill: View {
    let label: String; let value: String
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.subheadline.bold())
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
        .shadow(color: Color.primary.opacity(0.05), radius: 4, y: 2)
    }
}

struct ShareContactRow: View {
    let name: String; let role: String; let access: String; let initials: String; let color: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color(hex: color)).frame(width: 36, height: 36)
                Text(initials).font(.caption.bold()).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.subheadline.bold())
                Text(role).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Text(access).font(.caption)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Color.brandTeal.opacity(0.15))
                .foregroundColor(.brandTeal).cornerRadius(8)
        }
    }
}

// MARK: - Patient Doctors Tab (3rd segment of Community for patients)

struct PatientDoctorsTab: View {
    @Environment(HealthStore.self) var store
    @State private var search       = ""
    @State private var selectedSpec = "All"
    @State private var showFilter   = false
    @State private var selectedDoc  : Doctor? = nil
    @State private var showBook     = false
    @State private var showDocDetail = false
    @State private var detailDoc    : Doctor? = nil

    var allSpecialties: [String] {
        ["All"] + Array(Set(store.doctors.map { $0.specialization })).sorted()
    }

    var filtered: [Doctor] {
        store.doctors.filter { $0.isVerified }.filter { d in
            let matchSpec   = selectedSpec == "All" || d.specialization == selectedSpec
            let matchSearch = search.isEmpty
                || d.name.localizedCaseInsensitiveContains(search)
                || d.specialization.localizedCaseInsensitiveContains(search)
                || d.city.localizedCaseInsensitiveContains(search)
            return matchSpec && matchSearch
        }
    }

    var body: some View {
        VStack(spacing: 12) {

            // ── Search + Filter row ──────────────────────────────────────────
            HStack(spacing: 10) {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Search doctors, specialty, city…", text: $search)
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(12)

                Button { showFilter = true } label: {
                    Image(systemName: selectedSpec != "All"
                          ? "line.3.horizontal.decrease.circle.fill"
                          : "line.3.horizontal.decrease.circle")
                        .font(.title3)
                        .foregroundColor(selectedSpec != "All" ? .white : .brandTeal)
                        .padding(10)
                        .background(selectedSpec != "All" ? Color.brandTeal : Color(.systemGray6))
                        .cornerRadius(12)
                }
            }

            // ── Doctor cards ────────────────────────────────────────────────
            if filtered.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.slash")
                        .font(.system(size: 40)).foregroundColor(.secondary.opacity(0.4))
                    Text("No doctors found")
                        .font(.headline).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity).padding(.top, 30)
            } else {
                ForEach(filtered) { doc in
                    BookDoctorCard(doctor: doc) {
                        selectedDoc = doc
                        showBook = true
                    } onViewProfile: {
                        detailDoc = doc
                        showDocDetail = true
                    }
                }
            }

            // ── Your Appointments strip (shown when patient has bookings) ───
            if !store.appointments.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Divider().padding(.top, 4)
                    Text("Your Appointments")
                        .font(.headline)
                        .padding(.horizontal, 4)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(store.appointments.sorted { $0.date < $1.date }) { appt in
                                PatientApptMiniCard(appointment: appt)
                            }
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .sheet(isPresented: $showBook) {
            if let doc = selectedDoc { BookAppointmentView(doctor: doc) }
        }
        .sheet(isPresented: $showDocDetail) {
            if let doc = detailDoc {
                DoctorProfileDetailView(doctor: doc) {
                    selectedDoc = doc
                    showDocDetail = false
                    showBook = true
                }
            }
        }
        .sheet(isPresented: $showFilter) {
            SpecialtyFilterSheet(specialties: allSpecialties, selected: $selectedSpec)
        }
    }
}

// MARK: - Patient Appointment Mini Card (horizontal strip)

struct PatientApptMiniCard: View {
    let appointment: Appointment

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle()
                    .fill(Color(hex: appointment.doctorColor))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "stethoscope")
                            .font(.caption).foregroundColor(.white)
                    )
                Spacer()
                Text(appointment.isPaid ? "Paid" : "Pending")
                    .font(.caption2.bold())
                    .foregroundColor(appointment.isPaid ? .brandTeal : .orange)
            }
            Text(appointment.doctorName)
                .font(.caption.bold())
                .lineLimit(1)
            Text(appointment.doctorSpec)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
            Text(appointment.date, style: .date)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(appointment.type.rawValue)
                .font(.caption2)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(Color.brandPurple.opacity(0.12))
                .foregroundColor(.brandPurple)
                .cornerRadius(6)
        }
        .padding(12)
        .frame(width: 160)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }
}

// MARK: - Date Extension

extension Date {
    var timeAgo: String {
        let diff = Date().timeIntervalSince(self)
        if diff < 3600 { return "\(Int(diff / 60))m ago" }
        if diff < 86400 { return "\(Int(diff / 3600))h ago" }
        return "\(Int(diff / 86400))d ago"
    }
}

extension Int {
    func formatted() -> String {
        self >= 1000 ? String(format: "%.1fk", Double(self) / 1000) : "\(self)"
    }
}
