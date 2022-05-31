//
//  ProspectsView.swift
//  HotProspects
//
//  Created by Ozgu Ozden on 2022/05/23.
//

import CodeScanner
import SwiftUI
import UserNotifications


struct ProspectsView: View {
    @EnvironmentObject var prospects: Prospects
    @State private var isShowingScanner = false
    @State private var showingConfirmation = false

    let options = ["Paul Hudson\npaul@hackingwithswift.com", "John Bright\nbright@example.com", "Marry Heaven\nmarry@example.com"]
 
    
    enum FilterType {
        case none, contacted, uncontacted
    }
    let filter: FilterType
    
    enum SortType {
        case ascending, descending
    }
    @State private var sort: SortType = .ascending
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredProspects) { prospect in
                    HStack {
                        if prospect.isContacted {
                            Label("", systemImage: "person.crop.circle.fill.badge.checkmark")
                                .accentColor(Color(.systemGreen))

                        } else {
                            Label("", systemImage: "person.crop.circle.badge.xmark")
                                .accentColor(Color(.systemPink))
                        }
                        VStack(alignment: .leading) {
                            Text(prospect.name)
                                .font(.headline)
                            Text(prospect.emailAddress)
                                .foregroundColor(.secondary)
                        }
                    }
                    .swipeActions {
                        if prospect.isContacted {
                            Button {
                                prospects.toggle(prospect)
                            } label: {
                                Label("Mark Uncontacted", systemImage: "person.crop.circle.badge.xmark")
                            }
                            .tint(.blue)
                        } else {
                            Button {
                                prospects.toggle(prospect)
                            } label: {
                                Label("Mark Contacted", systemImage: "person.crop.circle.fill.badge.checkmark")
                            }
                            .tint(.green)
                            Button {
                                addNotification(for: prospect)
                            } label: {
                                Label("Remind Me", systemImage: "bell")
                            }
                            .tint(.orange)
                        }
                    }
                }
            }
                .navigationTitle(title)
                .toolbar {
                    ToolbarItem(placement: .primaryAction ) {
                        Button {
                           isShowingScanner = true
                        } label: {
                            Label("Scan", systemImage: "qrcode.viewfinder")
                        }
                    }
                    ToolbarItem(placement: .automatic) {
                        Button {
                           showingConfirmation = true
                        } label: {
                            Label("Sorting", systemImage: "arrow.up.arrow.down.square")
                        }
                    }
                }
                .sheet(isPresented: $isShowingScanner) {
                    CodeScannerView(codeTypes: [.qr], simulatedData: options[Int.random(in: 0..<options.count)], completion: handleScan)
                }
                .confirmationDialog("Sorting", isPresented: $showingConfirmation) {
                    Button("A to Z") {
                        sort = .ascending
                    }
                    Button("Z to A") {
                        sort = .descending
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("choose sort options")
                }
                
        }
    }
    
    var title: String {
        switch filter {
        case .none:
            return "Everyone"
        case .contacted:
            return "Contacted People"
        case .uncontacted:
            return "Uncontacted People"
        }
    }
    var filteredProspects: [Prospect] {
        
        var p: [Prospect] = []
        
        switch filter {
            case .none:
                p = prospects.people
            case .contacted:
                p = prospects.people.filter { $0.isContacted }
            case .uncontacted:
                p = prospects.people.filter { !$0.isContacted }
        }
        
        switch sort {
            case .ascending:
            return p.sorted { (p1: Prospect, p2: Prospect) -> Bool in
                return p1.name < p2.name
            }
            case .descending:
            return p.sorted { (p1: Prospect, p2: Prospect) -> Bool in
                return p1.name > p2.name
            }
        }
    }
    func handleScan(result: Result<ScanResult, ScanError>) {
        isShowingScanner = false
        
        switch result {
        case .success(let result):
            let details = result.string.components(separatedBy: "\n")
            guard details.count == 2 else { return }

            let person = Prospect()
            person.name = details[0]
            person.emailAddress = details[1]
            prospects.add(person)
        case .failure(let error):
            print("Scanning failed: \(error.localizedDescription)")
        }
    }
    func addNotification(for prospect: Prospect) {
        let center = UNUserNotificationCenter.current()

        let addRequest = {
            let content = UNMutableNotificationContent()
            content.title = "Contact \(prospect.name)"
            content.subtitle = prospect.emailAddress
            content.sound = UNNotificationSound.default

            var dateComponents = DateComponents()
            dateComponents.hour = 9
//            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            center.add(request)
            
        }

        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                addRequest()
            } else {
                center.requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                    if success {
                        addRequest()
                    } else {
                        print("D'oh")
                    }
                }
            }
        }
    }
}

struct ProspectsView_Previews: PreviewProvider {
    static var previews: some View {
        ProspectsView(filter: .none)
            .environmentObject(Prospects())
    }
}
