import Combine
import Foundation
import SwiftUI

class OperationInfoViewModel: ObservableObject {
  struct Environment {
    var operation: AnyPublisher<HomebrewOperation, Never>
  }

  struct Operation: Identifiable {
    typealias ID = HomebrewOperation.ID

    let id: ID
    let name: String
    let status: String
  }

  @Published private(set) var operations: [Operation] = []

  init(environment: Environment) {
    environment.operation
      .scan([]) { operations, operation in
        let newOperation = Operation(
          id: operation.id,
          name: operation.command.name,
          status: operation.status.name
        )
        var ops = operations
        if let index = ops.firstIndex(where: { $0.id == operation.id }) {
          ops[index] = newOperation
        } else {
          ops.append(newOperation)
        }
        return ops
      }
      .receive(on: DispatchQueue.main)
      .assign(to: &$operations)
  }
}

extension OperationInfoViewModel {
  convenience init(repository: PackageRepository) {
    self.init(environment: Environment(operation: repository.operationPublisher))
  }
}

struct OperationInfoView: View {
  @ObservedObject var viewModel: OperationInfoViewModel

  var body: some View {
    VStack(alignment: .leading) {
      Text("Homebrew Operations")
      List(viewModel.operations) { operation in
        Text(operation.name)
        Spacer()
        Text(operation.status)
      }
    }
    .padding()
    .frame(minWidth: 350, minHeight: 400)
  }
}

private extension HomebrewCommand {
  var name: String {
    switch self {
    case .list: return "Refreshing packages"
    case .info(let package): return "Getting info for \"\(package)\""
    case .uninstall(let package): return "Uninstalling \"\(package)\""
    case .update: return "Updating packages"
    case .upgrade(.all): return "Upgrading all packages"
    case .upgrade(.only(let package)): return "Upgrading \"\(package)\""
    }
  }
}

private extension HomebrewOperation.Status {
  var name: String {
    switch self {
    case .queued: return "Queued"
    case .running: return "Running"
    case .cancelled: return "Cancelled"
    case .completed(let result): return "Completed: Status \(result.status)"
    }
  }
}