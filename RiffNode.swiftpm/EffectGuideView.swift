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
    @Namespace private var guideNamespace
    
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
                selectedIndex: $selectedCategoryIndex,
                namespace: guideNamespace
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

struct GuideHeaderView: View {
    var body: some View {
        GlassEffectContainer(spacing: 12) {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "text.book.closed")
                        .foregroundStyle(.cyan)
                    Text("EFFECT GUIDE")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                    Spacer()
                }
                
                Text("Learn about guitar effects and how to use them in your signal chain")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
    }
}

// MARK: - Category Selector View

struct CategorySelectorView: View {
    let categories: [any EffectCategoryProviding]
    @Binding var selectedIndex: Int
    let namespace: Namespace.ID
    
    var body: some View {
        GlassEffectContainer(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(categories.enumerated()), id: \.offset) { index, category in
                        CategoryButton(
                            category: category,
                            isSelected: selectedIndex == index,
                            namespace: namespace
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
        }
    }
}

// MARK: - Category Button

struct CategoryButton: View {
    let category: any EffectCategoryProviding
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.name)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(isSelected ? .white : .secondary)
        }
        .buttonStyle(.plain)
        .glassEffect(
            isSelected ? .regular.tint(category.color).interactive() : .regular,
            in: .capsule
        )
        .glassEffectID("category-\(category.name)", in: namespace)
    }
}

// MARK: - Category Description View

struct CategoryDescriptionView: View {
    let category: any EffectCategoryProviding
    
    var body: some View {
        HStack(spacing: 12) {
            Text(category.description)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(category.color.opacity(0.3)), in: .rect(cornerRadius: 0))
    }
}

// MARK: - Effects List View

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
        .glassEffect(
            isExpanded ? .regular.tint(effect.color.opacity(0.2)).interactive() : .regular.interactive(),
            in: .rect(cornerRadius: 16)
        )
        .animation(.spring(duration: 0.3), value: isExpanded)
    }
}

// MARK: - Effect Card Header

struct EffectCardHeader: View {
    let effect: EffectInfoModel
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Color indicator
                Circle()
                    .fill(effect.color)
                    .frame(width: 8, height: 8)
                
                Text(effect.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Spacer()
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Effect Card Details

struct EffectCardDetails: View {
    let effect: EffectInfoModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
                .background(effect.color.opacity(0.3))
            
            EffectDetailRow(
                title: "Function",
                content: effect.function,
                color: .cyan
            )
            
            EffectDetailRow(
                title: "Sound",
                content: effect.sound,
                color: .green
            )
            
            EffectDetailRow(
                title: "How to Use",
                content: effect.howToUse,
                color: .yellow
            )
            
            EffectDetailRow(
                title: "Signal Chain Position",
                content: effect.signalChainPosition,
                color: .orange
            )
            
            EffectDetailRow(
                title: "Famous Users",
                content: effect.famousUsers,
                color: .purple
            )
        }
        .padding()
    }
}

// MARK: - Effect Detail Row

struct EffectDetailRow: View {
    let title: String
    let content: String
    let color: Color
    
    var body: some View {
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

// MARK: - Preview

#Preview {
    EffectGuideView()
}
