import SwiftUI

@main
struct MountAIScholarApp: App {
    @State private var activeTab: MainTab = .story
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ZStack {
                    Color(red: 0.03, green: 0.05, blue: 0.10)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        // Barre supérieure de statut
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "brain.head.profile")
                                    .foregroundColor(.cyan)
                                    .font(.title3)
                                Text("Mount AI Scholar")
                                    .font(.headline)
                                    .fontWeight(.black)
                            }
                            
                            Spacer()
                            
                            if activeTab != .hub && activeTab != .story {
                                Button(action: { activeTab = .hub }) {
                                    Label("Hub Principal", systemImage: "chevron.left")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.cyan)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.cyan.opacity(0.15))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.4))
                        
                        // Vue active
                        Group {
                            switch activeTab {
                            case .story:
                                WWDCInteractiveStoryView(activeTab: $activeTab)
                            case .hub:
                                MainHubView(selectedTab: $activeTab)
                            case .sl2t:
                                SL2TScannerView()
                            case .arPhonemes:
                                ArKitScannerView()
                            case .dyslexia:
                                DyslexiaReadingView()
                            case .quiz:
                                SignQuizView()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
