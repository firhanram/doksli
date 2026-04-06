import Foundation

// MARK: - Tree mutation helpers for SidebarView
// Extracted to reduce per-file type checker load during Release builds.

enum SidebarTreeHelpers {

    static func removeItem(requestId: UUID?, folderId: UUID?, from items: [Item]) -> [Item] {
        items.compactMap { item in
            switch item {
            case .request(let r):
                if let rid = requestId, r.id == rid { return nil }
                return item
            case .folder(let f):
                if let fid = folderId, f.id == fid { return nil }
                var folder = f
                folder.items = removeItem(requestId: requestId, folderId: folderId, from: f.items)
                return .folder(folder)
            }
        }
    }

    static func insertAfter(requestId: UUID, newItem: Item, in items: [Item]) -> [Item] {
        var result: [Item] = []
        for item in items {
            switch item {
            case .request(let r):
                result.append(item)
                if r.id == requestId {
                    result.append(newItem)
                }
            case .folder(let f):
                var folder = f
                folder.items = insertAfter(requestId: requestId, newItem: newItem, in: f.items)
                result.append(.folder(folder))
            }
        }
        return result
    }

    static func addToFolder(folderId: UUID, newItem: Item, in items: [Item]) -> [Item] {
        items.map { item in
            switch item {
            case .folder(let f):
                var folder = f
                if f.id == folderId {
                    folder.items.append(newItem)
                } else {
                    folder.items = addToFolder(folderId: folderId, newItem: newItem, in: f.items)
                }
                return .folder(folder)
            case .request:
                return item
            }
        }
    }

    static func extractItem(itemId: UUID, from items: [Item], extracted: inout Item?) -> [Item] {
        items.compactMap { item in
            switch item {
            case .request(let r):
                if r.id == itemId {
                    extracted = item
                    return nil
                }
                return item
            case .folder(var f):
                if f.id == itemId {
                    extracted = item
                    return nil
                }
                f.items = extractItem(itemId: itemId, from: f.items, extracted: &extracted)
                return .folder(f)
            }
        }
    }

    static func insertIntoFolder(folderId: UUID, item: Item, in items: [Item]) -> [Item] {
        items.map { existing in
            switch existing {
            case .folder(var f):
                if f.id == folderId {
                    f.items.append(item)
                } else {
                    f.items = insertIntoFolder(folderId: folderId, item: item, in: f.items)
                }
                return .folder(f)
            case .request:
                return existing
            }
        }
    }

    static func renameRequestInItems(requestId: UUID, newName: String, in items: [Item]) -> [Item] {
        items.map { item in
            switch item {
            case .request(var stub):
                if stub.id == requestId { stub.name = newName }
                return .request(stub)
            case .folder(var f):
                f.items = renameRequestInItems(requestId: requestId, newName: newName, in: f.items)
                return .folder(f)
            }
        }
    }

    static func renameFolderInItems(folderId: UUID, newName: String, in items: [Item]) -> [Item] {
        items.map { item in
            switch item {
            case .request:
                return item
            case .folder(var f):
                if f.id == folderId { f.name = newName }
                f.items = renameFolderInItems(folderId: folderId, newName: newName, in: f.items)
                return .folder(f)
            }
        }
    }

    static func collectRequestIds(in items: [Item], folderId: UUID, into ids: inout [UUID]) {
        for item in items {
            switch item {
            case .request(let stub):
                ids.append(stub.id)
            case .folder(let f):
                if f.id == folderId {
                    collectAllRequestIds(in: f.items, into: &ids)
                } else {
                    collectRequestIds(in: f.items, folderId: folderId, into: &ids)
                }
            }
        }
    }

    static func collectAllRequestIds(in items: [Item], into ids: inout [UUID]) {
        for item in items {
            switch item {
            case .request(let stub): ids.append(stub.id)
            case .folder(let f): collectAllRequestIds(in: f.items, into: &ids)
            }
        }
    }
}
