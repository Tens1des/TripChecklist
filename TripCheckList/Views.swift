import SwiftUI

// MARK: - Trips List

struct TripsListView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingNewTrip = false
    @State private var tripPendingDeletion: Trip? = nil

    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("My trips")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Everything for easy packing")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Trips List
                if appState.trips.filter({ !$0.isArchived }).isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "suitcase")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("No trips yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Create your first checklist")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 60)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(appState.trips.filter { !$0.isArchived }) { trip in
                                NavigationLink(value: trip.id) {
                                    TripCard(
                                        trip: trip,
                                        onDelete: { tripPendingDeletion = trip },
                                        onArchive: { archiveTrip(trip) }
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingNewTrip) {
                NewTripSheet { title, icon in
                    let newTrip = Trip(title: title, iconName: icon)
                    appState.trips.append(newTrip)
                }
            }
            .navigationDestination(for: UUID.self) { tripId in
                if let trip = appState.trips.first(where: { $0.id == tripId }) {
                    TripDetailView(tripId: trip.id)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                Button {
                    showingNewTrip = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 100)
            }
        }
        .alert("Delete trip?", isPresented: Binding(get: { tripPendingDeletion != nil }, set: { if !$0 { tripPendingDeletion = nil } })) {
            Button("Cancel", role: .cancel) { tripPendingDeletion = nil }
            Button("Delete", role: .destructive) {
                if let trip = tripPendingDeletion { deleteTrip(trip) }
                tripPendingDeletion = nil
            }
        } message: {
            if let trip = tripPendingDeletion { Text("This will remove \(trip.title) and its items.") }
        }
    }

    private func deleteTrip(_ trip: Trip) {
        appState.trips.removeAll { $0.id == trip.id }
    }

    private func archiveTrip(_ trip: Trip) {
        if let index = appState.trips.firstIndex(of: trip) {
            appState.trips[index].isArchived = true
        }
    }
}

struct TripCard: View {
    let trip: Trip
    var onDelete: (() -> Void)? = nil
    var onArchive: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        if let icon = trip.iconName {
                            Image(systemName: icon)
                                .foregroundColor(.blue)
                        }
                        Text(trip.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    }
                    
                    if let startDate = trip.startDate, let endDate = trip.endDate {
                        Text(formatDateRange(startDate, endDate))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 10) {
                    // Status Badge
                    Text(trip.status.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(statusColor)
                        .clipShape(Capsule())

                    if let onArchive { Button { onArchive() } label: { Image(systemName: "archivebox").foregroundColor(.blue) } }
                    if let onDelete { Button(role: .destructive) { onDelete() } label: { Image(systemName: "trash").foregroundColor(.red) } }
                }
            }
            
            // Progress Bar
            VStack(spacing: 10) {
                ProgressView(value: Double(trip.completedItemCount), total: Double(max(trip.totalItemCount, 1)))
                    .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                    .scaleEffect(x: 1, y: 1.8, anchor: .center)
                
                HStack(spacing: 16) {
                    Label("\(trip.completedItemCount)/\(trip.totalItemCount)", systemImage: "checkmark.circle")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if trip.totalWeightKg > 0 {
                        Label(String(format: "%.1f/%.1f кг", trip.packedWeightKg, trip.totalWeightKg), systemImage: "scalemass")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Details
            HStack(spacing: 16) {
                Label("\(trip.categoryCount) category", systemImage: "folder")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if trip.totalWeightKg > 0 {
                    Label(String(format: "%.1f кг / %.1f кг", trip.packedWeightKg, trip.totalWeightKg), systemImage: "scalemass")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
    
    private var statusColor: Color {
        switch trip.status {
        case .new: return .green
        case .inProgress: return .blue
        case .ready: return .green
        }
    }
    
    private var progressColor: Color {
        switch trip.status {
        case .new: return .gray
        case .inProgress: return .blue
        case .ready: return .green
        }
    }
    
    private func formatDateRange(_ start: Date, _ end: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM"
        
        let startStr = formatter.string(from: start)
        let endStr = formatter.string(from: end)
        
        return "\(startStr) - \(endStr)"
    }
}

struct TripRow: View {
    let trip: Trip
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(trip.title).font(.headline)
            ProgressView(value: Double(trip.completedItemCount), total: Double(max(trip.totalItemCount, 1)))
            HStack(spacing: 12) {
                Label("\(trip.completedItemCount)/\(trip.totalItemCount)", systemImage: "checkmark.circle")
                if trip.totalWeightKg > 0 {
                    Label(String(format: "%.1f/%.1f kg", trip.packedWeightKg, trip.totalWeightKg), systemImage: "scalemass")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}

struct NewTripSheet: View {
    var onCreate: (String, String?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var selectedIcon: String = "airplane"
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var selectedTripType: TripType = .leisure
    @State private var selectedTemplate: TripTemplate? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header with gradient
                    HStack {
                        Button("Cancel") { dismiss() }
                            .foregroundColor(.white)
                        Spacer()
                        Text("New trip")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Spacer()
                        Button("Create") {
                            onCreate(title.isEmpty ? "New trip" : title, selectedIcon)
                            dismiss()
                        }
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(
                        .rect(topLeadingRadius: 0, bottomLeadingRadius: 16, bottomTrailingRadius: 16, topTrailingRadius: 0)
                    )
                    
                    VStack(alignment: .leading, spacing: 20) {
                        // Trip Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Trip name")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("For example: Vacation in Paris", text: $title)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Icon Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Choose an icon")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                                ForEach(iconOptions, id: \.self) { icon in
                                    Button {
                                        selectedIcon = icon
                                    } label: {
                                        Image(systemName: icon)
                                            .font(.title2)
                                            .foregroundColor(selectedIcon == icon ? .white : .primary)
                                            .frame(width: 40, height: 40)
                                            .background(selectedIcon == icon ? Color.blue : Color(UIColor.secondarySystemBackground))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                        }
                        
                        // Date Pickers
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Trip dates")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Start date")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    DatePicker("", selection: $startDate, displayedComponents: .date)
                                        .datePickerStyle(CompactDatePickerStyle())
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("End date")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    DatePicker("", selection: $endDate, displayedComponents: .date)
                                        .datePickerStyle(CompactDatePickerStyle())
                                }
                            }
                        }
                        
                        // Trip Type
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Trip type")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 12) {
                                ForEach(TripType.allCases, id: \.self) { type in
                                    TripTypeButton(
                                        type: type,
                                        isSelected: selectedTripType == type
                                    ) {
                                        selectedTripType = type
                                    }
                                }
                            }
                        }
                        
                        // Templates
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Use a template")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            VStack(spacing: 12) {
                                ForEach(TripTemplate.allCases, id: \.self) { template in
                                    TemplateCard(
                                        template: template,
                                        isSelected: selectedTemplate == template
                                    ) {
                                        selectedTemplate = template
                                    }
                                }
                                
                                Button {
                                    selectedTemplate = nil
                                } label: {
                                    Text("Create from scratch")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 8)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private let iconOptions = [
        "airplane", "car", "suitcase", "leaf", "mountain.2", "camera",
        "ferry", "tram.fill", "bus", "bicycle", "tent", "house",
        "building.2", "airplane.departure", "figure.walk", "figure.run"
    ]
}

enum TripType: String, CaseIterable {
    case leisure = "leisure"
    case work = "work"
    case adventure = "adventure"
    case family = "family"
    
    var displayName: String {
        switch self {
        case .leisure: return "Leisure"
        case .work: return "Work"
        case .adventure: return "Adventure"
        case .family: return "Family"
        }
    }
    
    var iconName: String {
        switch self {
        case .leisure: return "sun.max"
        case .work: return "briefcase"
        case .adventure: return "mountain.2"
        case .family: return "figure.2.and.child.holdinghands"
        }
    }
}

struct TripTypeButton: View {
    let type: TripType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: type.iconName)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(type.displayName)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 60, height: 50)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

enum TripTemplate: String, CaseIterable {
    case beach = "beach"
    case ski = "ski"
    case city = "city"
    
    var displayName: String {
        switch self {
        case .beach: return "Beach Vacation"
        case .ski: return "Ski Resort"
        case .city: return "City Tour"
        }
    }
    
    var description: String {
        switch self {
        case .beach: return "25 items. Swimsuit, towel, sunscreen..."
        case .ski: return "30 items. Skis, jacket, thermal wear..."
        case .city: return "20 items. Camera, maps, comfy shoes..."
        }
    }
    
    var iconName: String {
        switch self {
        case .beach: return "umbrella"
        case .ski: return "snowflake"
        case .city: return "building.2"
        }
    }
    
    var color: Color {
        switch self {
        case .beach: return .blue
        case .ski: return .purple
        case .city: return .green
        }
    }
}

struct TemplateCard: View {
    let template: TripTemplate
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: template.iconName)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(template.color)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(template.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Trip Detail

struct TripDetailView: View {
    @EnvironmentObject var appState: AppState
    let tripId: UUID
    @State private var showAddItem = false
    @State private var showOnlyRemaining = false
    @State private var editingItem: TripItem?
    @State private var showCategoryManager = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let binding = Binding(get: {
            appState.trips.first(where: { $0.id == tripId }) ?? Trip(title: "")
        }, set: { updated in
            if let idx = appState.trips.firstIndex(where: { $0.id == updated.id }) {
                appState.trips[idx] = updated
            }
        })

        let trip = binding.wrappedValue

        return VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                }
                
                Text(trip.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                if let startDate = trip.startDate, let endDate = trip.endDate {
                    Text(formatDateRange(startDate, endDate))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            // Progress Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Packing progress")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(spacing: 8) {
                    let percent = Int(Double(trip.completedItemCount) / Double(max(trip.totalItemCount, 1)) * 100.0)
                    HStack {
                        Text("\(percent)%")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Spacer()
                    }
                    
                    ProgressView(value: Double(trip.completedItemCount), total: Double(max(trip.totalItemCount, 1)))
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                    
                    HStack(spacing: 16) {
                        Text("\(trip.completedItemCount) of \(trip.totalItemCount) items packed")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if trip.totalWeightKg > 0 {
                            Text(String(format: "%.1f/%.1f kg", trip.packedWeightKg, trip.totalWeightKg))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Filter Toggle
                HStack(spacing: 0) {
                    Button {
                        showOnlyRemaining = false
                    } label: {
                        Text("All items")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(showOnlyRemaining ? .secondary : .white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(showOnlyRemaining ? Color.clear : Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    
                    Button {
                        showOnlyRemaining = true
                    } label: {
                        Text("Remaining (\(trip.totalItemCount - trip.completedItemCount))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(showOnlyRemaining ? .white : .secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(showOnlyRemaining ? Color.blue : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // Items List
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(groupedItems(trip: trip), id: \.key) { category, items in
                        VStack(alignment: .leading, spacing: 12) {
                            // Category Header
                            HStack {
                                Image(systemName: category.iconName)
                                    .foregroundColor(.blue)
                                    .font(.title3)
                                
                                Text(category.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text("(\(items.filter { $0.isChecked }.count)/\(items.count))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 20)
                            
                            // Items
                            VStack(spacing: 8) {
                                ForEach(items) { item in
                                    ItemCard(item: item) { toggled in
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            updateItem(itemId: item.id) { $0.isChecked.toggle() }
                                        }
                                    }
                                    .onTapGesture {
                                        showEditItem(item)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            
            Spacer()
        }
        .navigationBarHidden(true)
        .overlay(alignment: .bottomTrailing) {
                Button {
                    showAddItem = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Add item")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 100)
        }
        .sheet(item: $editingItem) { item in
            EditItemSheet(item: item, categories: appState.categories) { updatedItem in
                updateItem(itemId: updatedItem.id) { $0 = updatedItem }
            }
        }
        .sheet(isPresented: $showCategoryManager) {
            CategoryManagerView(categories: appState.categories) { newCategory in
                appState.addCustomCategory(newCategory)
            } onDelete: { category in
                appState.deleteCategory(category)
            }
        }
        .sheet(isPresented: $showAddItem) {
            AddItemSheet(categories: appState.categories) { newItem in
                updateTrip { $0.items.append(newItem) }
            }
        }

        func updateTrip(_ body: (inout Trip) -> Void) {
            if let idx = appState.trips.firstIndex(where: { $0.id == tripId }) {
                var copy = appState.trips[idx]
                body(&copy)
                appState.trips[idx] = copy
            }
        }

        func updateItem(itemId: UUID, _ body: (inout TripItem) -> Void) {
            if let tidx = appState.trips.firstIndex(where: { $0.id == tripId }) {
                if let iidx = appState.trips[tidx].items.firstIndex(where: { $0.id == itemId }) {
                    var item = appState.trips[tidx].items[iidx]
                    body(&item)
                    appState.trips[tidx].items[iidx] = item
                    
                    // Update trip status
                    appState.trips[tidx].updateStatus()
                }
            }
        }

        func showEditItem(_ item: TripItem) {
            editingItem = item
        }
        
        func formatDateRange(_ start: Date, _ end: Date) -> String {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ru_RU")
            formatter.dateFormat = "d MMMM"
            
            let startStr = formatter.string(from: start)
            let endStr = formatter.string(from: end)
            
            return "\(startStr) - \(endStr)"
        }

        func groupedItems(trip: Trip) -> [(key: TripCategory, value: [TripItem])] {
            var items = trip.items
            if showOnlyRemaining {
                items = items.filter { !$0.isChecked }
            }
            items.sort { lhs, rhs in
                if lhs.isChecked != rhs.isChecked { return !lhs.isChecked && rhs.isChecked }
                if lhs.importance != rhs.importance { return lhs.importance.rawValue < rhs.importance.rawValue }
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
            let grouped = Dictionary(grouping: items, by: { $0.category })
            return grouped.sorted { $0.key.name < $1.key.name }
        }
    }
}

struct ItemCard: View {
    let item: TripItem
    var onToggle: (Bool) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                onToggle(!item.isChecked)
            } label: {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isChecked ? .green : .secondary)
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.title)
                        .font(.headline)
                        .fontWeight(item.importance == .high ? .semibold : .regular)
                        .foregroundColor(.primary)
                    
                    if item.importance == .high {
                        Image(systemName: "star.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    if let w = item.weightKg {
                        Text(String(format: "%.1f кг", w))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let note = item.note, !note.isEmpty {
                    Text(note)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct ItemRow: View {
    let item: TripItem
    var onToggle: (Bool) -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Button {
                onToggle(!item.isChecked)
            } label: {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isChecked ? .green : .secondary)
                    .font(.title3)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(item.title)
                        .fontWeight(item.importance == .high ? .semibold : .regular)
                    if item.importance == .high {
                        Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.orange)
                    }
                }
                if let note = item.note, !note.isEmpty {
                    Text(note).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let w = item.weightKg {
                Text(String(format: "%.1f kg", w)).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddItemSheet: View {
    let categories: [TripCategory]
    var onAdd: (TripItem) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var note: String = ""
    @State private var selectedCategory: TripCategory?
    @State private var importance: TripItem.Importance = .medium
    @State private var weightText: String = ""
    @State private var quantity: Int = 1

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with gradient
                HStack {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                    Spacer()
                    Text("Add item")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Spacer()
                    Button("Add") {
                        let weight = Double(weightText.replacingOccurrences(of: ",", with: "."))
                        let item = TripItem(
                            title: title.isEmpty ? "Item" : title,
                            note: note.isEmpty ? nil : note,
                            category: selectedCategory ?? .documents,
                            importance: importance,
                            weightKg: weight,
                            quantity: quantity
                        )
                        onAdd(item)
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(
                    .rect(topLeadingRadius: 0, bottomLeadingRadius: 16, bottomTrailingRadius: 16, topTrailingRadius: 0)
                )

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Quick Add (examples)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Quick add")
                                .font(.headline)
                            
                            LazyVStack(spacing: 8) {
                                quickAddButton(title: "Phone charger")
                                quickAddButton(title: "T-Shirts")
                                quickAddButton(title: "Sunscreen")
                            }
                        }

                        // Custom item fields
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Or create your own")
                                .font(.headline)
                            
                            TextField("Item name", text: $title)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        // Category grid
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.headline)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                ForEach(categories) { cat in
                                    Button {
                                        selectedCategory = cat
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: cat.iconName)
                                            Text(cat.name)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(12)
                                        .background((selectedCategory?.id == cat.id ? Color.blue : Color.gray.opacity(0.1)))
                                        .foregroundColor(selectedCategory?.id == cat.id ? .white : .primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                }
                            }
                        }

                        // Importance
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Importance")
                                .font(.headline)
                            HStack {
                                importanceChip(.low, title: "Low")
                                importanceChip(.medium, title: "Medium")
                                importanceChip(.high, title: "High")
                            }
                        }

                        // Weight and quantity
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Weight and quantity")
                                .font(.headline)
                            HStack(spacing: 12) {
                                TextField("0.5", text: $weightText)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(maxWidth: 120)
                                Text("kg")
                                    .foregroundColor(.secondary)

                                Spacer()

                                HStack(spacing: 12) {
                                    Button { quantity = max(1, quantity - 1) } label: { Image(systemName: "minus.circle") }
                                    Text("\(quantity)").frame(minWidth: 20)
                                    Button { quantity += 1 } label: { Image(systemName: "plus.circle") }
                                }
                            }
                        }

                        // Note
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Note (optional)")
                                .font(.headline)
                            TextField("Additional info or reminder", text: $note)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func quickAddButton(title: String) -> some View {
        Button {
            self.title = title
        } label: {
            HStack {
                Text(title)
                Spacer()
                Image(systemName: "plus")
            }
            .padding(12)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func importanceChip(_ value: TripItem.Importance, title: String) -> some View {
        Button { importance = value } label: {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(importance == value ? Color.blue : Color.gray.opacity(0.1))
                .foregroundColor(importance == value ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

struct EditItemSheet: View {
    let item: TripItem
    let categories: [TripCategory]
    var onSave: (TripItem) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var note: String
    @State private var selectedCategory: TripCategory
    @State private var importance: TripItem.Importance
    @State private var weightText: String

    init(item: TripItem, categories: [TripCategory], onSave: @escaping (TripItem) -> Void) {
        self.item = item
        self.categories = categories
        self.onSave = onSave
        self._title = State(initialValue: item.title)
        self._note = State(initialValue: item.note ?? "")
        self._selectedCategory = State(initialValue: item.category)
        self._importance = State(initialValue: item.importance)
        self._weightText = State(initialValue: item.weightKg.map { String(format: "%.1f", $0) } ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Item name", text: $title)
                    TextField("Note (optional)", text: $note)
                }
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories) { cat in
                        Text(cat.name).tag(cat)
                    }
                }
                Picker("Importance", selection: $importance) {
                    Text("Low").tag(TripItem.Importance.low)
                    Text("Medium").tag(TripItem.Importance.medium)
                    Text("High").tag(TripItem.Importance.high)
                }
                TextField("Weight (kg)", text: $weightText)
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("Edit Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let weight = Double(weightText.replacingOccurrences(of: ",", with: "."))
                        var updatedItem = item
                        updatedItem.title = title.isEmpty ? "Item" : title
                        updatedItem.note = note.isEmpty ? nil : note
                        updatedItem.category = selectedCategory
                        updatedItem.importance = importance
                        updatedItem.weightKg = weight
                        onSave(updatedItem)
                        dismiss()
                    }.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct CategoryManagerView: View {
    let categories: [TripCategory]
    var onAdd: (TripCategory) -> Void
    var onDelete: (TripCategory) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddCategory = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(categories) { category in
                    HStack {
                        Text(category.name)
                        Spacer()
                        if !category.system {
                            Button("Delete") {
                                onDelete(category)
                            }
                            .foregroundStyle(.red)
                        }
                    }
                }
            }
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add") { showingAddCategory = true }
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                AddCategorySheet { name in
                    let newCategory = TripCategory(name: name, system: false, iconName: "folder")
                    onAdd(newCategory)
                }
            }
        }
    }
}

struct AddCategorySheet: View {
    var onAdd: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Category name", text: $name)
            }
            .navigationTitle("Add Category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(name.isEmpty ? "New Category" : name)
                        dismiss()
                    }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - History

struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("History")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Your completed trips")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                if appState.trips.filter({ $0.isArchived }).isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("No history yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Completed trips will appear here")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 60)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(appState.trips.filter { $0.isArchived }) { trip in
                                HistoryCard(trip: trip) {
                                    var copy = trip
                                    copy.id = UUID()
                                    copy.isArchived = false
                                    appState.trips.append(copy)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
}

struct HistoryCard: View {
    let trip: Trip
    let onDuplicate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Completed: \(trip.completedItemCount)/\(trip.totalItemCount)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Duplicate") {
                    onDuplicate()
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Achievements

struct AchievementsView: View {
    @EnvironmentObject var achievementService: AchievementService
    @State private var showingNewAchievement: AchievementDefinition?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Achievements")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Collected \(achievementService.unlockedAchievements.count) of \(AchievementDefinition.all.count) awards")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Progress Bar
                VStack(spacing: 8) {
                    ProgressView(
                        value: Double(achievementService.unlockedAchievements.count),
                        total: Double(AchievementDefinition.all.count)
                    )
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                // Achievements Grid
                ScrollView {
                    let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(AchievementDefinition.all, id: \.id) { definition in
                            AchievementBlock(
                                definition: definition,
                                isUnlocked: achievementService.isUnlocked(definition.id)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
            .alert("New achievement!", isPresented: .constant(showingNewAchievement != nil)) {
                Button("OK") { showingNewAchievement = nil }
            } message: {
                if let achievement = showingNewAchievement {
                    Text(achievement.description)
                }
            }
        }
    }
}

struct AchievementCard: View {
    let definition: AchievementDefinition
    let isUnlocked: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: definition.iconName)
                    .font(.title2)
                    .foregroundStyle(isUnlocked ? definition.color : .secondary)
                    .frame(width: 36, height: 36)
                    .background((isUnlocked ? definition.color : .gray).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(definition.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(isUnlocked ? .primary : .secondary)
                    .lineLimit(2)

                Text(definition.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}

struct AchievementBlock: View {
    let definition: AchievementDefinition
    let isUnlocked: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: definition.iconName)
                    .font(.title2)
                    .foregroundStyle(isUnlocked ? definition.color : .secondary)
                    .frame(width: 36, height: 36)
                    .background((isUnlocked ? definition.color : .gray).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Spacer()
                if isUnlocked {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                }
            }
            Text(definition.title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(isUnlocked ? .primary : .secondary)
                .lineLimit(2)
            Text(definition.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}

// MARK: - Settings (simplified)

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Settings")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("App personalization")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Profile")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Choose avatar")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 12) {
                                    ForEach(["suitcase", "airplane", "backpack", "globe.europe.africa"], id: \.self) { icon in
                                        Button {
                                            appState.settings.avatarSymbolName = icon
                                        } label: {
                                            Image(systemName: icon)
                                                .font(.title2)
                                                .foregroundColor(appState.settings.avatarSymbolName == icon ? .white : .primary)
                                                .frame(width: 50, height: 50)
                                                .background(appState.settings.avatarSymbolName == icon ? Color.blue : Color.gray.opacity(0.15))
                                                .clipShape(Circle())
                                        }
                                    }
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("User name")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                TextField("Enter name", text: Binding(get: { appState.settings.displayName }, set: { appState.settings.displayName = $0 }))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                        .padding(20)
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                        
                        // Appearance Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Appearance")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Theme")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Picker("Theme", selection: Binding(get: { appState.settings.theme }, set: { appState.settings.theme = $0 })) {
                                    Text("System").tag(UserSettings.Theme.system)
                                    Text("Light").tag(UserSettings.Theme.light)
                                    Text("Dark").tag(UserSettings.Theme.dark)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("App language")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Picker("Language", selection: Binding(get: { appState.settings.language }, set: { appState.settings.language = $0 })) {
                                    Text("English").tag(UserSettings.AppLanguage.english)
                                    Text("Russian").tag(UserSettings.AppLanguage.russian)
                                    Text("Spanish").tag(UserSettings.AppLanguage.spanish)
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Text size")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Slider(value: Binding(get: { appState.settings.textScale }, set: { appState.settings.textScale = $0 }), in: 0.9...1.3) {
                                    Text("Text size")
                                }
                                
                                Text("Medium")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(20)
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
}


