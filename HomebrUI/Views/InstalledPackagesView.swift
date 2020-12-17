import Combine
import SwiftUI

class InstalledPackagesViewModel: ObservableObject {
  struct Environment {
    var packages: AnyPublisher<[Package], Never>
    var isRefreshing: AnyPublisher<Bool, Never>
    var uninstall: (Package) -> Void
  }

  @Published private(set) var isRefreshing: Bool = false
  @Published private(set) var packages: [Package] = []

  @Input var query: String = ""

  private let environment: Environment

  init(environment: Environment) {
    self.environment = environment

    environment.isRefreshing
      .receive(on: DispatchQueue.main)
      .assign(to: &$isRefreshing)

    Publishers
      .CombineLatest(environment.packages, $query.removeDuplicates())
      .map { packages, query in
        if query.isEmpty {
          return packages
        }
        return packages.filter { package in
          package.name.localizedCaseInsensitiveContains(query)
        }
      }
      .receive(on: DispatchQueue.main)
      .assign(to: &$packages)
  }

  func uninstall(package: Package) {
    environment.uninstall(package)
  }
}

extension InstalledPackagesViewModel {
  convenience init(repository: PackageRepository) {
    self.init(
      environment: Environment(
        packages: repository.packages,
        isRefreshing: repository.refreshing,
        uninstall: repository.uninstall
      )
    )
  }
}

struct InstalledPackagesView: View {
  @ObservedObject var viewModel: InstalledPackagesViewModel

  var body: some View {
    VStack(spacing: 0) {
      PackageFilterView(query: $viewModel.query)
      PackageListView(
        packages: viewModel.packages,
        action: { action in
          switch action {
          case .uninstall(let package):
            viewModel.uninstall(package: package)
          }
        }
      )
      Spacer(minLength: 0)
      if viewModel.isRefreshing {
        PackageRefreshIndicator()
      }
    }
    .frame(minWidth: 250, maxWidth: 300)
  }
}

private struct PackageFilterView: View {
  @Binding var query: String

  var body: some View {
    TextField("Filter", text: $query)
      .textFieldStyle(RoundedBorderTextFieldStyle())
      .padding(8)
  }
}

private struct PackageListView: View {
  enum Action {
    case uninstall(Package)
  }

  let packages: [Package]
  let action: (Action) -> Void

  var body: some View {
    List {
      Section(header: Text("Formulae")) {
        ForEach(packages) { package in
          NavigationLink(destination: PackageDetailView(package: package)) {
            Text(package.name)
            Spacer()
            Text(package.version)
              .foregroundColor(.secondary)
          }
          .contextMenu {
            Button("Uninstall") {
              action(.uninstall(package))
            }
          }
        }
      }
    }
    .listStyle(SidebarListStyle())
  }
}

private struct PackageRefreshIndicator: View {
  var body: some View {
    VStack {
      Divider()
      HStack {
        Text("Refreshing")
          .font(.callout)
        Spacer()
        ProgressView()
          .scaleEffect(0.5)
      }
      .padding([.leading, .trailing])
      .padding(.bottom, 8)
    }
  }
}