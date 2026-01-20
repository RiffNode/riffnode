import SwiftUI

// MARK: - Effect Guide View
// Following Clean Architecture: View Layer (Presentation)
// Following Single Responsibility: Only handles UI rendering
// Following Dependency Inversion: Depends on protocol, not concrete implementation

struct EffectGuideView: View {
    
    // MARK: - Dependencies (Dependency Injection)
    
    private let guideService: EffectGuideServiceProtocol
    
    // MARK: - State
    
    @State private var selectedCategoryIndex: Int = 0
    @State private var expandedEffectId: UUID? = nil
    
    // MARK: - Initialization
    
    init(guideService: EffectGuideServiceProtocol = EffectGuideService.shared) {
        self.guideService = guideService
    }
    
    // MARK: - Computed Properties
    
    private var categories: [any EffectCategoryProviding] {
        guideService.categories
    }
    
    private var selectedCategory: (any EffectCategoryProviding)? {
        guard selectedCategoryIndex < categories.count else { return nil }
        return categories[selectedCategoryIndex]
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            GuideHeaderView()
            
            CategorySelectorView(
                categories: categories,
                selectedIndex: $selectedCategoryIndex
            )
            
            if let category = selectedCategory {
                CategoryDescriptionView(category: category)
                
                EffectsListView(
                    effects: category.effects,
                    expandedEffectId: $expandedEffectId
                )
            }
        }
        .background(Color(red: 0.05, green: 0.05, blue: 0.1))
    }
}

// MARK: - Guide Header View
// Following Single Responsibility: Only renders header

struct GuideHeaderView: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "book.fill")
                    .foregroundStyle(.yellow)
                Text("EFFECT PEDAL GUIDE")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                Spacer()
            }
            
            Text("Learn about different types of guitar effects and how to use them")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color.black.opacity(0.3))
    }
}

// MARK: - Category Selector View
// Following Single Responsibility: Only handles category selection UI

struct CategorySelectorView: View {
    let categories: [any EffectCategoryProviding]
    @Binding var selectedIndex: Int
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(categories.enumerated()), id: \.offset) { index, category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedIndex == index
                    ) {
                        withAnimation(.spring(duration: 0.3)) {
                            selectedIndex = index
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color.black.opacity(0.2))
    }
}

// MARK: - Category Button
// Following Single Responsibility: Only renders a single category button

struct CategoryButton: View {
    let category: any EffectCategoryProviding
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 12))
                Text(category.name)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? category.color : Color.gray.opacity(0.3))
            )
            .foregroundStyle(isSelected ? .black : .white)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Description View
// Following Single Responsibility: Only renders category description

struct CategoryDescriptionView: View {
    let category: any EffectCategoryProviding
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.title2)
                .foregroundStyle(category.color)
            
            Text(category.description)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(category.color.opacity(0.1))
    }
}

// MARK: - Effects List View
// Following Single Responsibility: Only renders the list of effects

struct EffectsListView: View {
    let effects: [any EffectInfoProviding]
    @Binding var expandedEffectId: UUID?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(effects.enumerated()), id: \.offset) { index, effect in
                    if let effectModel = effect as? EffectInfoModel {
                        EffectCardView(
                            effect: effectModel,
                            isExpanded: expandedEffectId == effectModel.id
                        ) {
                            withAnimation(.spring(duration: 0.3)) {
                                expandedEffectId = expandedEffectId == effectModel.id ? nil : effectModel.id
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Effect Card View
// Following Single Responsibility: Only renders a single effect card

struct EffectCardView: View {
    let effect: EffectInfoModel
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            EffectCardHeader(effect: effect, isExpanded: isExpanded, onTap: onTap)
            
            if isExpanded {
                EffectCardDetails(effect: effect)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            isExpanded ? effect.color.opacity(0.5) : Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                )
        )
        .animation(.spring(duration: 0.3), value: isExpanded)
    }
}

// MARK: - Effect Card Header
// Following Single Responsibility: Only renders card header

struct EffectCardHeader: View {
    let effect: EffectInfoModel
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(effect.color.opacity(0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: effect.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(effect.color)
                }
                
                Text(effect.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Spacer()
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
            .padding()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Effect Card Details
// Following Single Responsibility: Only renders expanded details

struct EffectCardDetails: View {
    let effect: EffectInfoModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
                .background(effect.color.opacity(0.3))
            
            EffectDetailRow(
                title: "Function",
                content: effect.function,
                icon: "gearshape.fill",
                color: .cyan
            )
            
            EffectDetailRow(
                title: "Sound",
                content: effect.sound,
                icon: "speaker.wave.3.fill",
                color: .green
            )
            
            EffectDetailRow(
                title: "How to Use",
                content: effect.howToUse,
                icon: "hand.point.up.fill",
                color: .yellow
            )
            
            EffectDetailRow(
                title: "Signal Chain Position",
                content: effect.signalChainPosition,
                icon: "arrow.right.circle.fill",
                color: .orange
            )
            
            EffectDetailRow(
                title: "Famous Users",
                content: effect.famousUsers,
                icon: "star.fill",
                color: .purple
            )
        }
        .padding()
    }
}

// MARK: - Effect Detail Row
// Following Single Responsibility: Only renders a single detail row

struct EffectDetailRow: View {
    let title: String
    let content: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(color)
                
                Text(content)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    EffectGuideView()
}
