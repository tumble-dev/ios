//
//  NavigationStackCoordinator.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-17.
//
//  iOS 15 Compatibility:
//  - NavigationStack/NavigationSplitView (iOS 16+) fallback to NavigationView
//  - PresentationDetent (iOS 16+) conditionally applied
//  - Legacy navigation hierarchy built using NavigationLink for iOS 15

import Combine
import SwiftUI

private struct NavigationSplitCoordinatorView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @ObservedObject var navigationSplitCoordinator: NavigationSplitCoordinator
    
    @State private var columnVisibility: Any = {
        if #available(iOS 16.0, *) {
            return NavigationSplitViewVisibility.all
        } else {
            return ()
        }
    }()
    
    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                navigationStack
            } else {
                if #available(iOS 16.0, *) {
                    navigationSplitView
                } else {
                    // Fallback to single view for iOS 15
                    navigationView
                }
            }
        }
        // This needs to be handled on the top level otherwise sheets
        // will be automatically dismissed on hierarchy changes.
        // Embedded NavigationStackCoordinators will present their sheets
        // through the NavigationSplitCoordinator as well.
        .sheet(item: $navigationSplitCoordinator.sheetModule) { module in
            module.coordinator?.toPresentable()
                .id(module.id)
        }
        .fullScreenCover(item: $navigationSplitCoordinator.fullScreenCoverModule) { module in
            module.coordinator?.toPresentable()
                .id(module.id)
        }
        .accessibilityHidden(navigationSplitCoordinator.overlayModule?.coordinator != nil && navigationSplitCoordinator.overlayPresentationMode == .fullScreen)
        .overlay {
            Group {
                if let coordinator = navigationSplitCoordinator.overlayModule?.coordinator {
                    coordinator.toPresentable()
                        .opacity(navigationSplitCoordinator.overlayPresentationMode == .minimized ? 0 : 1)
                        .transition(.opacity)
                }
            }
            .animation(.default, value: navigationSplitCoordinator.overlayPresentationMode)
            .animation(.default, value: navigationSplitCoordinator.overlayModule)
        }
    }
    
    /// The NavigationStack that will be used in compact layouts
    @ViewBuilder
    var navigationStack: some View {
        if #available(iOS 16.0, *) {
            NavigationStack(path: navigationSplitCoordinator.compactLayoutStackModulesBinding) {
                navigationSplitCoordinator.compactLayoutRootModule?.coordinator?.toPresentable()
                    .id(navigationSplitCoordinator.compactLayoutRootModule?.id) // Is a nil ID ok?
                    .navigationDestination(for: NavigationModule.self) { module in
                        module.coordinator?.toPresentable()
                            .id(module.id)
                    }
            }
        } else {
            // iOS 15 fallback using NavigationView
            NavigationView {
                LegacyNavigationStackView(
                    rootModule: navigationSplitCoordinator.compactLayoutRootModule,
                    stackModules: navigationSplitCoordinator.compactLayoutStackModules
                )
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
    
    /// The NavigationSplitView that will be used in non-compact layouts
    @ViewBuilder
    var navigationSplitView: some View {
        if #available(iOS 16.0, *) {
            NavigationSplitView(columnVisibility: createColumnVisibilityBinding()) {
                if let sidebarModule = navigationSplitCoordinator.sidebarModule {
                    sidebarModule.coordinator?.toPresentable()
                        .id(sidebarModule.id)
                } else {
                    navigationSplitCoordinator.placeholderModule.coordinator?.toPresentable()
                        .id(navigationSplitCoordinator.placeholderModule.id)
                }
            } detail: {
                if let detailModule = navigationSplitCoordinator.detailModule {
                    detailModule.coordinator?.toPresentable()
                        .id(detailModule.id)
                } else {
                    navigationSplitCoordinator.placeholderModule.coordinator?.toPresentable()
                        .id(navigationSplitCoordinator.placeholderModule.id)
                }
            }
            .navigationSplitViewStyle(.balanced)
            .navigationDestination(for: NavigationModule.self) { module in
                module.coordinator?.toPresentable()
                    .id(module.id)
            }
            .animation(.default, value: navigationSplitCoordinator.sidebarModule)
            .animation(.default, value: navigationSplitCoordinator.detailModule)
        }
    }
    
    @available(iOS 16.0, *)
    private func createColumnVisibilityBinding() -> Binding<NavigationSplitViewVisibility> {
        Binding(
            get: {
                if let visibility = columnVisibility as? NavigationSplitViewVisibility {
                    return visibility
                }
                return NavigationSplitViewVisibility.all
            },
            set: { newValue in
                columnVisibility = newValue
            }
        )
    }
    
    /// Fallback NavigationView for iOS 15
    @ViewBuilder 
    var navigationView: some View {
        NavigationView {
            Group {
                if let sidebarModule = navigationSplitCoordinator.sidebarModule {
                    sidebarModule.coordinator?.toPresentable()
                        .id(sidebarModule.id)
                } else {
                    navigationSplitCoordinator.placeholderModule.coordinator?.toPresentable()
                        .id(navigationSplitCoordinator.placeholderModule.id)
                }
            }
            
            Group {
                if let detailModule = navigationSplitCoordinator.detailModule {
                    detailModule.coordinator?.toPresentable()
                        .id(detailModule.id)
                } else {
                    navigationSplitCoordinator.placeholderModule.coordinator?.toPresentable()
                        .id(navigationSplitCoordinator.placeholderModule.id)
                }
            }
        }
        .animation(.default, value: navigationSplitCoordinator.sidebarModule)
        .animation(.default, value: navigationSplitCoordinator.detailModule)
    }
}

// MARK: - Legacy Navigation for iOS 15

/// A legacy navigation view that simulates NavigationStack behavior on iOS 15
private struct LegacyNavigationStackView: View {
    let rootModule: NavigationModule?
    let stackModules: [NavigationModule]
    
    var body: some View {
        Group {
            if let rootModule = rootModule {
                if stackModules.isEmpty {
                    // Just show the root
                    rootModule.coordinator?.toPresentable()
                        .id(rootModule.id)
                } else {
                    // Build the navigation hierarchy
                    LegacyNavigationHierarchy(
                        rootModule: rootModule,
                        stackModules: stackModules,
                        currentIndex: 0
                    )
                }
            } else {
                Text("No root view configured")
                    .foregroundColor(.secondary)
            }
        }
    }
}

/// Recursive view for building navigation hierarchy on iOS 15
private struct LegacyNavigationHierarchy: View {
    let rootModule: NavigationModule?
    let stackModules: [NavigationModule]
    let currentIndex: Int
    
    @State private var isNavigating = true
    
    var body: some View {
        Group {
            if currentIndex == 0, let rootModule = rootModule {
                // Show root with navigation to first stack item
                ZStack {
                    rootModule.coordinator?.toPresentable()
                        .id(rootModule.id)
                    
                    NavigationLink(
                        destination: nextView,
                        isActive: $isNavigating
                    ) {
                        EmptyView()
                    }
                    .opacity(0)
                    .disabled(stackModules.isEmpty)
                }
            } else if currentIndex <= stackModules.count {
                let moduleIndex = currentIndex - 1
                if moduleIndex < stackModules.count {
                    let module = stackModules[moduleIndex]
                    let isLast = moduleIndex == stackModules.count - 1
                    
                    ZStack {
                        module.coordinator?.toPresentable()
                            .id(module.id)
                        
                        if !isLast {
                            NavigationLink(
                                destination: nextView,
                                isActive: $isNavigating
                            ) {
                                EmptyView()
                            }
                            .opacity(0)
                        }
                    }
                }
            }
        }
        .onAppear {
            isNavigating = currentIndex < stackModules.count
        }
    }
    
    @ViewBuilder
    private var nextView: some View {
        LegacyNavigationHierarchy(
            rootModule: rootModule,
            stackModules: stackModules,
            currentIndex: currentIndex + 1
        )
    }
}

// MARK: - NavigationSplitCoordinator

/// Class responsible for displaying 2 coordinators side by side and collapsing them
/// into a single navigation stack on compact layouts
class NavigationSplitCoordinator: CoordinatorProtocol, ObservableObject, CustomStringConvertible {
    fileprivate let placeholderModule: NavigationModule
    
    var sidebarStackModuleCancellable: AnyCancellable?

    @Published fileprivate var sidebarModule: NavigationModule? {
        didSet {
            if let oldValue {
                logPresentationChange("Remove sidebar", oldValue)
                oldValue.tearDown()
                sidebarStackModuleCancellable = nil
            }
            
            if let sidebarModule {
                logPresentationChange("Set sidebar", sidebarModule)
                sidebarModule.coordinator?.start()
                if let observableCoordinator = sidebarModule.coordinator as? NavigationStackCoordinator {
                    sidebarStackModuleCancellable = observableCoordinator.$stackModules.sink { [weak self] _ in
                        self?.objectWillChange.send()
                    }
                }
            }
        }
    }
    
    /// The currently displayed sidebar coordinator
    var sidebarCoordinator: (any CoordinatorProtocol)? {
        sidebarModule?.coordinator
    }

    var detailCoordinatorCancellable: AnyCancellable?
    
    @Published fileprivate var detailModule: NavigationModule? {
        didSet {
            if let oldValue {
                logPresentationChange("Remove detail", oldValue)
                oldValue.tearDown()
                detailCoordinatorCancellable = nil
            }
            
            if let detailModule {
                logPresentationChange("Set detail", detailModule)
                detailModule.coordinator?.start()
                if let observableCoordinator = detailModule.coordinator as? NavigationStackCoordinator {
                    detailCoordinatorCancellable = Publishers.CombineLatest(observableCoordinator.$rootModule, observableCoordinator.$stackModules).sink { [weak self] _ in
                        self?.objectWillChange.send()
                    }
                }
            }
        }
    }
    
    /// The currently displayed detail coordinator
    var detailCoordinator: (any CoordinatorProtocol)? {
        detailModule?.coordinator
    }
    
    @Published fileprivate var sheetModule: NavigationModule? {
        didSet {
            if let oldValue {
                logPresentationChange("Remove sheet", oldValue)
                oldValue.tearDown()
            }
            
            if let sheetModule {
                logPresentationChange("Set sheet", sheetModule)
                sheetModule.coordinator?.start()
            }
        }
    }
    
    /// The currently displayed sheet coordinator
    var sheetCoordinator: (any CoordinatorProtocol)? {
        sheetModule?.coordinator
    }
    
    @Published fileprivate var fullScreenCoverModule: NavigationModule? {
        didSet {
            if let oldValue {
                logPresentationChange("Remove fullscreen cover", oldValue)
                oldValue.tearDown()
            }
            
            if let fullScreenCoverModule {
                logPresentationChange("Set fullscreen cover", fullScreenCoverModule)
                fullScreenCoverModule.coordinator?.start()
            }
        }
    }
    
    // periphery:ignore - might be useful to have
    /// The currently displayed fullscreen cover coordinator
    var fullScreenCoverCoordinator: (any CoordinatorProtocol)? {
        fullScreenCoverModule?.coordinator
    }
    
    @Published fileprivate var overlayModule: NavigationModule? {
        didSet {
            if let oldValue {
                logPresentationChange("Remove overlay", oldValue)
                oldValue.tearDown()
            }
            
            if let overlayModule {
                logPresentationChange("Set overlay", overlayModule)
                overlayModule.coordinator?.start()
            }
        }
    }
    
    /// The currently displayed overlay coordinator
    var overlayCoordinator: (any CoordinatorProtocol)? {
        overlayModule?.coordinator
    }
    
    enum OverlayPresentationMode { case fullScreen, minimized }
    @Published fileprivate var overlayPresentationMode: OverlayPresentationMode = .minimized
    
    fileprivate var compactLayoutRootModule: NavigationModule? {
        if let sidebarNavigationStackCoordinator = sidebarModule?.coordinator as? NavigationStackCoordinator {
            if let sidebarRootModule = sidebarNavigationStackCoordinator.rootModule {
                return sidebarRootModule
            }
        } else if let sidebarModule {
            return sidebarModule
        }
        return nil
    }
    
    var compactLayoutRootCoordinator: (any CoordinatorProtocol)? {
        compactLayoutRootModule?.coordinator
    }

    var compactLayoutStackModules: [NavigationModule] {
        get {
            compactLayoutStackModulesBinding.wrappedValue
        }
        set {
            compactLayoutStackModulesBinding.wrappedValue = newValue
        }
    }

    fileprivate lazy var compactLayoutStackModulesBinding: Binding<[NavigationModule]> = Binding(get: { [weak self] in
        self?.getCompactStackModules() ?? []
    }, set: { [weak self] newValue in
        self?.setCompactStackModules(newValue)
    })

    private func getCompactStackModules() -> [NavigationModule] {
        // Start building the new compact layout navigation stack
        var stackModules: [NavigationModule] = []
        // If the sidebar is a stackCoordinator then use it's root as the compact layout root
        // and push its children to the compact layout stack
        if let sidebarNavigationStackCoordinator = sidebarModule?.coordinator as? NavigationStackCoordinator {
            stackModules.append(contentsOf: sidebarNavigationStackCoordinator.stackModules)
        }

        // If the detail is a stackCoordinator then push its root and children to the compact layout stack
        if let detailNavigationStackCoordinator = detailModule?.coordinator as? NavigationStackCoordinator {
            if let detailRootCoordinator = detailNavigationStackCoordinator.rootModule {
                stackModules.append(detailRootCoordinator)
            }

            stackModules.append(contentsOf: detailNavigationStackCoordinator.stackModules)
        } else if let detailModule { // Otherwise just push it entirely
            stackModules.append(detailModule)
        }
        return stackModules
    }

    private func setCompactStackModules(_ modules: [NavigationModule]) {
        guard compactLayoutStackModules != modules else { return }

        let diffs = modules.difference(from: compactLayoutStackModules)
        diffs.forEach { change in
            switch change {
            case .insert:
                break
            case .remove(_, let module, _):
                processCompactLayoutStackModuleRemoval(module)
            }
        }
    }

    var compactLayoutStackCoordinators: [any CoordinatorProtocol] {
        compactLayoutStackModules.compactMap(\.coordinator)
    }
    
    /// Default NavigationSplitCoordinator initialiser
    /// - Parameter placeholderCoordinator: coordinator to use if no siderbar or detail is set
    init(placeholderCoordinator: CoordinatorProtocol) {
        placeholderModule = NavigationModule(placeholderCoordinator)
    }
    
    /// Set the coordinator to be used on the split's left pannel
    /// - Parameters:
    ///   - coordinator: the sidebar coordinator
    ///   - animated: whether the transition should be animated
    ///   - dismissalCallback: called when this particular sidebar coordinator has removed/replaced
    func setSidebarCoordinator(_ coordinator: (any CoordinatorProtocol)?, animated: Bool = true, dismissalCallback: (() -> Void)? = nil) {
        guard let coordinator else {
            sidebarModule = nil
            return
        }
        
        if sidebarModule?.coordinator === coordinator {
            fatalError("Cannot use the same coordinator more than once")
        }

        var transaction = Transaction()
        transaction.disablesAnimations = !animated

        withTransaction(transaction) {
            sidebarModule = NavigationModule(coordinator, dismissalCallback: dismissalCallback)
        }
    }
    
    /// Set the coordinator to be used on the split's right pannel
    /// - Parameters:
    ///   - coordinator: the detail coordinator
    ///   - animated: whether the transition should be animated
    ///   - dismissalCallback: called when this particular detail coordinator has removed/replaced
    func setDetailCoordinator(_ coordinator: (any CoordinatorProtocol)?, animated: Bool = true, dismissalCallback: (() -> Void)? = nil) {
        guard let coordinator else {
            detailModule = nil
            return
        }
        
        if detailModule?.coordinator === coordinator {
            fatalError("Cannot use the same coordinator more than once")
        }

        var transaction = Transaction()
        transaction.disablesAnimations = !animated

        withTransaction(transaction) {
            detailModule = NavigationModule(coordinator, dismissalCallback: dismissalCallback)
        }
    }
    
    /// Present a sheet on top of the split view
    /// - Parameters:
    ///   - coordinator: the coordinator to display
    ///   - animated: whether the transition should be animated
    ///   - dismissalCallback: called when the sheet has been dismissed, programatically or otherwise
    func setSheetCoordinator(_ coordinator: (any CoordinatorProtocol)?, animated: Bool = true, dismissalCallback: (() -> Void)? = nil) {
        guard let coordinator else {
            sheetModule = nil
            return
        }
        
        if sheetModule?.coordinator === coordinator {
            fatalError("Cannot use the same coordinator more than once")
        }

        var transaction = Transaction()
        transaction.disablesAnimations = !animated

        withTransaction(transaction) {
            sheetModule = NavigationModule(coordinator, dismissalCallback: dismissalCallback)
        }
    }
    
    /// Present a fullscreen cover on top of the split view
    /// - Parameters:
    ///   - coordinator: the coordinator to display
    ///   - animated: whether the transition should be animated
    ///   - dismissalCallback: called when the fullscreen cover has been dismissed, programatically or otherwise
    func setFullScreenCoverCoordinator(_ coordinator: (any CoordinatorProtocol)?, animated: Bool = true, dismissalCallback: (() -> Void)? = nil) {
        guard let coordinator else {
            fullScreenCoverModule = nil
            return
        }
        
        if fullScreenCoverModule?.coordinator === coordinator {
            fatalError("Cannot use the same coordinator more than once")
        }

        var transaction = Transaction()
        transaction.disablesAnimations = !animated

        withTransaction(transaction) {
            fullScreenCoverModule = NavigationModule(coordinator, dismissalCallback: dismissalCallback)
        }
    }
    
    /// Present an overlay on top of the split view
    /// - Parameters:
    ///   - coordinator: the coordinator to display
    ///   - presentationMode: how the coordinator should be presented
    ///   - animated: whether the transition should be animated
    ///   - dismissalCallback: called when the overlay has been dismissed, programatically or otherwise
    func setOverlayCoordinator(_ coordinator: (any CoordinatorProtocol)?,
                               presentationMode: OverlayPresentationMode = .fullScreen,
                               animated: Bool = true,
                               dismissalCallback: (() -> Void)? = nil) {
        guard let coordinator else {
            overlayModule = nil
            return
        }
        
        if overlayModule?.coordinator === coordinator {
            fatalError("Cannot use the same coordinator more than once")
        }

        var transaction = Transaction()
        transaction.disablesAnimations = !animated

        withTransaction(transaction) {
            overlayPresentationMode = presentationMode
            overlayModule = NavigationModule(coordinator, dismissalCallback: dismissalCallback)
        }
    }
    
    /// Updates the presentation of the overlay coordinator.
    /// - Parameters:
    ///   - mode: The type of presentation to use.
    ///   - animated: whether the transition should be animated
    func setOverlayPresentationMode(_ mode: OverlayPresentationMode, animated: Bool = true) {
        var transaction = Transaction()
        transaction.disablesAnimations = !animated
        
        withTransaction(transaction) {
            overlayPresentationMode = mode
        }
    }
        
    // MARK: - CoordinatorProtocol
    
    func toPresentable() -> AnyView {
        AnyView(NavigationSplitCoordinatorView(navigationSplitCoordinator: self))
    }
    
    func stop() {
        releaseAllCoordinatorReferences()
    }
    
    // MARK: - CustomStringConvertible

    var description: String {
        switch (sidebarModule?.coordinator, detailModule?.coordinator) {
        case (.some(let sidebarCoordinator), .some(let detailCoordinator)):
            return "NavigationSplitCoordinator(\(sidebarCoordinator) | \(detailCoordinator))"
        case (.some(let sidebarCoordinator), .none):
            return "NavigationSplitCoordinator(\(sidebarCoordinator) | Empty)"
        case (.none, .some(let detailCoordinator)):
            return "NavigationSplitCoordinator(Empty | \(detailCoordinator))"
        case (.none, .none):
            return "NavigationSplitCoordinator(Empty | Empty)"
        }
    }
    
    // MARK: - Private
    
    /// The NavigationStack has a tendency to hold on to path items for longer than needed. We work around that by manually nilling the coordinator
    /// when a NavigationModule is dismissed. As the NavigationModule is just a wrapper multiple instances of it continuing living is of no consequence
    /// https://stackoverflow.com/questions/73885353/found-a-strange-behaviour-of-state-when-combined-to-the-new-navigation-stack/
    ///
    /// For added complexity, the NavigationSplitCoordinator has an internal compact layout NavigationStack for which we need to manually nil things again
    private func releaseAllCoordinatorReferences() {
        sidebarModule?.tearDown()
        detailModule?.tearDown()
        sheetModule?.tearDown()
        fullScreenCoverModule?.tearDown()
        
        compactLayoutRootModule?.tearDown()
        compactLayoutStackModules.forEach { module in
            module.tearDown()
        }
    }
    
    private func logPresentationChange(_ change: String, _ module: NavigationModule) {
        if let coordinator = module.coordinator {
            AppLogger.shared.info("\(self) \(change): \(coordinator)")
        }
    }
    
    /// Manually process changes to the compact layout navigation stack and update embedded components
    /// We need to either: pop from the detail, nil the detail or pop from the sidebar
    private func processCompactLayoutStackModuleRemoval(_ module: NavigationModule) {
        if let sidebarNavigationStackCoordinator = sidebarModule?.coordinator as? NavigationStackCoordinator {
            if sidebarNavigationStackCoordinator.stackModules.contains(module) {
                sidebarNavigationStackCoordinator.stackModules.removeAll { $0 == module }
            }
        }
        
        if module == detailModule {
            detailModule = nil
        }
        
        if let detailNavigationStackCoordinator = detailModule?.coordinator as? NavigationStackCoordinator {
            if detailNavigationStackCoordinator.stackModules.contains(module) {
                detailNavigationStackCoordinator.stackModules.removeAll { $0 == module }
            } else if module == detailNavigationStackCoordinator.rootModule {
                detailModule = nil
            }
        }
    }
}

// MARK: - NavigationStackCoordinator

/// Class responsible for displaying a normal "NavigationController" style hierarchy
class NavigationStackCoordinator: ObservableObject, CoordinatorProtocol, CustomStringConvertible {
    private(set) weak var navigationSplitCoordinator: NavigationSplitCoordinator?
    
    @Published fileprivate var rootModule: NavigationModule? {
        didSet {
            if let oldValue {
                logPresentationChange("Remove root", oldValue)
                oldValue.tearDown()
            }
            
            if let rootModule {
                logPresentationChange("Set root", rootModule)
                rootModule.coordinator?.start()
            }
        }
    }
    
    // The stack's current root coordinator
    var rootCoordinator: (any CoordinatorProtocol)? {
        rootModule?.coordinator
    }
    
    @Published fileprivate var sheetModule: NavigationModule? {
        didSet {
            if let oldValue {
                logPresentationChange("Remove sheet", oldValue)
                oldValue.tearDown()
            }
            
            if let sheetModule {
                logPresentationChange("Set sheet", sheetModule)
                sheetModule.coordinator?.start()
            }
        }
    }
    
    private var _presentationDetents: Any = {
        if #available(iOS 16.0, *) {
            return Set<PresentationDetent>()
        } else {
            return ()
        }
    }()
    
    @available(iOS 16.0, *)
    var presentationDetents: Set<PresentationDetent> {
        get {
            _presentationDetents as! Set<PresentationDetent>
        }
        set {
            _presentationDetents = newValue
        }
    }
    
    /// Set presentation detents (iOS 16+ only)
    @available(iOS 16.0, *)
    func setPresentationDetents(_ detents: Set<PresentationDetent>) {
        presentationDetents = detents
    }
    
    /// Convenience method to safely set presentation detents without availability checks
    func configurePresentation(detents: Any? = nil) {
        if #available(iOS 16.0, *), let detents = detents as? Set<PresentationDetent> {
            _presentationDetents = detents
        }
    }
    
    // The currently presented sheet coordinator
    // Sheets will be presented through the NavigationSplitCoordinator if provided
    var sheetCoordinator: (any CoordinatorProtocol)? {
        if let navigationSplitCoordinator {
            return navigationSplitCoordinator.sheetCoordinator
        }
        
        return sheetModule?.coordinator
    }
    
    @Published fileprivate var fullScreenCoverModule: NavigationModule? {
        didSet {
            if let oldValue {
                logPresentationChange("Remove fullscreen cover", oldValue)
                oldValue.tearDown()
            }
            
            if let fullScreenCoverModule {
                logPresentationChange("Set fullscreen cover", fullScreenCoverModule)
                fullScreenCoverModule.coordinator?.start()
            }
        }
    }
    
    // periphery:ignore - might be useful to have
    // The currently presented fullscreen cover coordinator
    // Fullscreen covers will be presented through the NavigationSplitCoordinator if provided
    var fullScreenCoverCoordinator: (any CoordinatorProtocol)? {
        if let navigationSplitCoordinator {
            return navigationSplitCoordinator.fullScreenCoverCoordinator
        }
        
        return fullScreenCoverModule?.coordinator
    }
    
    @Published fileprivate var stackModules = [NavigationModule]() {
        didSet {
            let diffs = stackModules.difference(from: oldValue)
            diffs.forEach { change in
                switch change {
                case .insert(_, let module, _):
                    logPresentationChange("Push", module)
                    module.coordinator?.start()
                case .remove(_, let module, _):
                    logPresentationChange("Pop", module)
                    module.tearDown()
                }
            }
        }
    }
    
    // The current navigation stack. Excludes the rootCoordinator
    var stackCoordinators: [any CoordinatorProtocol] {
        stackModules.compactMap(\.coordinator)
    }
    
    /// If this NavigationStackCoordinator will be embedded into a NavigationSplitCoordinator pass it here
    /// so that sheet presentations are done through it. Otherwise sheets will not be presented properly
    /// and dismissed automatically in compact layouts
    /// - Parameter navigationSplitCoordinator: The expected parent NavigationSplitCoordinator
    init(navigationSplitCoordinator: NavigationSplitCoordinator? = nil) {
        self.navigationSplitCoordinator = navigationSplitCoordinator
    }
    
    /// Set the coordinator to be used on the stack's root
    /// - Parameters:
    ///   - coordinator: the root coordinator
    ///   - animated: whether to animate the transition or not. Default is true
    ///   - dismissalCallback: called when this root coordinator has removed/replaced
    func setRootCoordinator(_ coordinator: (any CoordinatorProtocol)?, animated: Bool = true, dismissalCallback: (() -> Void)? = nil) {
        guard let coordinator else {
            rootModule = nil
            return
        }
        
        if rootModule?.coordinator === coordinator {
            fatalError("Cannot use the same coordinator more than once")
        }
        
        popToRoot(animated: false)

        var transaction = Transaction()
        transaction.disablesAnimations = !animated

        withTransaction(transaction) {
            rootModule = NavigationModule(coordinator, dismissalCallback: dismissalCallback)
        }
    }
    
    /// Pushes a new coordinator on the navigation stack
    /// - Parameters:
    ///   - coordinator: the coordinator to be displayed
    ///   - animated: whether to animate the transition or not. Default is true
    ///   - dismissalCallback: called when the coordinator has been popped, programatically or otherwise
    func push(_ coordinator: any CoordinatorProtocol, animated: Bool = true, dismissalCallback: (() -> Void)? = nil) {
        var transaction = Transaction()
        transaction.disablesAnimations = !animated

        withTransaction(transaction) {
            stackModules.append(NavigationModule(coordinator, dismissalCallback: dismissalCallback))
        }
    }
    
    /// Pop all the coordinators from the stack, returning to the root coordinator
    /// - Parameter animated: whether to animate the transition or not. Default is true
    func popToRoot(animated: Bool = true) {
        guard !stackModules.isEmpty else {
            return
        }

        var transaction = Transaction()
        transaction.disablesAnimations = !animated

        withTransaction(transaction) {
            stackModules.removeAll()
        }
    }
    
    /// Removes the last coordinator from the navigation stack
    /// - Parameter animated: whether to animate the transition or not. Default is true
    func pop(animated: Bool = true) {
        var transaction = Transaction()
        transaction.disablesAnimations = !animated

        withTransaction(transaction) {
            _ = stackModules.popLast()
        }
    }
    
    /// Present a sheet on top of the stack. If this NavigationStackCoordinator is embedded within a NavigationSplitCoordinator
    /// then the presentation will be proxied to the split
    /// - Parameters:
    ///   - coordinator: the coordinator to display
    ///   - animated: whether to animate the transition or not. Default is true

    ///   - dismissalCallback: called when the sheet has been dismissed, programatically or otherwise
    func setSheetCoordinator(_ coordinator: (any CoordinatorProtocol)?, animated: Bool = true, dismissalCallback: (() -> Void)? = nil) {
        if let navigationSplitCoordinator {
            navigationSplitCoordinator.setSheetCoordinator(coordinator, dismissalCallback: dismissalCallback)
            return
        }
        
        guard let coordinator else {
            sheetModule = nil
            return
        }
        
        if sheetModule?.coordinator === coordinator {
            fatalError("Cannot use the same coordinator more than once")
        }

        var transaction = Transaction()
        transaction.disablesAnimations = !animated

        withTransaction(transaction) {
            sheetModule = NavigationModule(coordinator, dismissalCallback: dismissalCallback)
        }
    }

    // periphery:ignore - might be useful to have
    /// Present a fullscreen cover on top of the stack. If this NavigationStackCoordinator is embedded within a NavigationSplitCoordinator
    /// then the presentation will be proxied to the split
    /// - Parameters:
    ///   - coordinator: the coordinator to display
    ///   - animated: whether to animate the transition or not. Default is true
    ///   - dismissalCallback: called when the fullscreen cover has been dismissed, programatically or otherwise
    func setFullScreenCoverCoordinator(_ coordinator: (any CoordinatorProtocol)?, animated: Bool = true, dismissalCallback: (() -> Void)? = nil) {
        if let navigationSplitCoordinator {
            navigationSplitCoordinator.setFullScreenCoverCoordinator(coordinator, dismissalCallback: dismissalCallback)
            return
        }
        
        guard let coordinator else {
            fullScreenCoverModule = nil
            return
        }
        
        if fullScreenCoverModule?.coordinator === coordinator {
            fatalError("Cannot use the same coordinator more than once")
        }

        var transaction = Transaction()
        transaction.disablesAnimations = !animated

        withTransaction(transaction) {
            fullScreenCoverModule = NavigationModule(coordinator, dismissalCallback: dismissalCallback)
        }
    }
    
    // MARK: - CoordinatorProtocol
    
    func toPresentable() -> AnyView {
        let view = NavigationStackCoordinatorView(navigationStackCoordinator: self)
        
        if #available(iOS 16.0, *) {
            return AnyView(view.presentationDetents(presentationDetents))
        } else {
            return AnyView(view)
        }
    }
    
    /// The NavigationStack has a tendency to hold on to path items for longer than needed. We work around that by manually nilling the coordinator
    /// when a NavigationModule is dismissed. As the NavigationModule is just a wrapper multiple instances of it continuing living is of no consequence
    /// https://stackoverflow.com/questions/73885353/found-a-strange-behaviour-of-state-when-combined-to-the-new-navigation-stack/
    func stop() {
        rootModule?.tearDown()
        sheetModule?.tearDown()
        fullScreenCoverModule?.tearDown()
        
        stackModules.forEach { module in
            module.tearDown()
        }
    }
    
    // MARK: - CustomStringConvertible
    
    var description: String {
        if let rootCoordinator = rootModule?.coordinator {
            return "NavigationStackCoordinator(\(rootCoordinator))"
        } else {
            return "NavigationStackCoordinator(Empty)"
        }
    }
    
    // MARK: - Private
    
    private func logPresentationChange(_ change: String, _ module: NavigationModule) {
        if let coordinator = module.coordinator {
            AppLogger.shared.info("\(self) \(change): \(coordinator)")
        }
    }
}

private struct NavigationStackCoordinatorView: View {
    @ObservedObject var navigationStackCoordinator: NavigationStackCoordinator
    
    var body: some View {
        Group {
            if #available(iOS 16.0, *) {
                NavigationStack(path: $navigationStackCoordinator.stackModules) {
                    navigationStackCoordinator.rootModule?.coordinator?.toPresentable()
                        .id(navigationStackCoordinator.rootModule?.id)
                        .navigationDestination(for: NavigationModule.self) { module in
                            module.coordinator?.toPresentable()
                                .id(module.id)
                        }
                }
            } else {
                NavigationView {
                    LegacyNavigationStackView(
                        rootModule: navigationStackCoordinator.rootModule,
                        stackModules: navigationStackCoordinator.stackModules
                    )
                }
                .navigationViewStyle(StackNavigationViewStyle())
            }
        }
        .sheet(item: $navigationStackCoordinator.sheetModule) { module in
            module.coordinator?.toPresentable()
                .id(module.id)
        }
        .fullScreenCover(item: $navigationStackCoordinator.fullScreenCoverModule) { module in
            module.coordinator?.toPresentable()
                .id(module.id)
        }
        .animation(.default, value: navigationStackCoordinator.rootModule)
    }
}
