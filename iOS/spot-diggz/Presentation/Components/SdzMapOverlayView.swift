import SwiftUI

enum SdzSpotType: String, CaseIterable, Identifiable {
    case park
    case street

    var id: String { rawValue }

    var tagValue: String {
        switch self {
        case .park:
            return "パーク"
        case .street:
            return "ストリート"
        }
    }

    var label: String {
        switch self {
        case .park:
            return "スケートパーク"
        case .street:
            return "ストリート"
        }
    }
}

struct SdzMapOverlayView: View {
    @Binding var searchText: String
    @Binding var selectedSpotType: SdzSpotType?
    @Binding var selectedTags: Set<String>
    @Binding var isFilterExpanded: Bool
    let tagOptions: [String]

    var body: some View {
        VStack(spacing: SdzSpacing.sm) {
            HStack(spacing: SdzSpacing.sm) {
                SdzSearchBar(
                    placeholder: "スポットを探す...",
                    text: $searchText,
                    style: .floating
                )
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isFilterExpanded.toggle()
                    }
                }) {
                    Image(systemName: isFilterExpanded ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .font(.title3)
                        .foregroundColor(.sdzStreet)
                        .padding(SdzSpacing.sm)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .accessibilityLabel("フィルタ")
            }

            if isFilterExpanded {
                VStack(spacing: SdzSpacing.sm) {
                    spotTypeChips
                    tagFilterChips
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, SdzSpacing.lg)
        .padding(.top, SdzSpacing.sm)
    }

    private var spotTypeChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SdzSpacing.sm) {
                SdzChip(
                    title: "すべて",
                    isSelected: selectedSpotType == nil
                ) {
                    selectedSpotType = nil
                }
                ForEach(SdzSpotType.allCases) { spotType in
                    SdzChip(
                        title: spotType.label,
                        isSelected: selectedSpotType == spotType
                    ) {
                        selectedSpotType = spotType
                    }
                }
            }
            .padding(.vertical, SdzSpacing.xs)
        }
    }

    private var tagFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SdzSpacing.sm) {
                Menu {
                    ForEach(tagOptions, id: \.self) { tag in
                        Button {
                            toggleTag(tag)
                        } label: {
                            Label(tag, systemImage: selectedTags.contains(tag) ? "checkmark" : "plus")
                        }
                    }
                } label: {
                    Image(systemName: "tag.circle.fill")
                        .font(SdzTypography.title2)
                        .foregroundColor(tagOptions.isEmpty ? .gray : Color.sdzStreet)
                        .padding(.vertical, SdzSpacing.xs)
                        .accessibilityLabel("タグを追加")
                }
                .buttonStyle(.plain)
                .disabled(tagOptions.isEmpty)

                ForEach(selectedTags.sorted(), id: \.self) { tag in
                    SdzChip(
                        title: tag,
                        isSelected: true,
                        systemImage: "xmark.circle.fill"
                    ) {
                        toggleTag(tag)
                    }
                }
            }
            .padding(.vertical, SdzSpacing.xs)
        }
    }

    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
}
