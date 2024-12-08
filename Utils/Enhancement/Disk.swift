#if canImport(Disk)

import Disk

public extension Disk.Directory {
    static let appGroup = Disk.Directory.sharedContainer(appGroupName: "group.com.fduhole.danxi")
}

#else

import Foundation

// MARK: API

public enum Directory {
    case applicationSupport
    case caches
    case appGroup
}

public class Disk {
    public static func save<T: Encodable>(_ value: T, to directory: Directory, as path: String, encoder: JSONEncoder = JSONEncoder()) throws {
        if path.hasSuffix("/") {
            throw LocatableError()
        }
        do {
            let url = try createURL(for: path, in: directory)
            let data = try encoder.encode(value)
            try createSubfoldersBeforeCreatingFile(at: url)
            try data.write(to: url, options: .atomic)
        } catch {
            throw error
        }
    }
    
    public static func save(data: Data, to directory: Directory, as path: String) throws {
        if path.hasSuffix("/") {
            throw LocatableError()
        }
        do {
            let url = try createURL(for: path, in: directory)
            try data.write(to: url, options: .atomic)
        } catch {
            throw error
        }
    }
    
    public static func retrieve<T: Decodable>(_ path: String, from directory: Directory, as type: T.Type, decoder: JSONDecoder = JSONDecoder()) throws -> T {
        if path.hasSuffix("/") {
            throw LocatableError()
        }
        do {
            let url = try getExistingFileURL(for: path, in: directory)
            let data = try Data(contentsOf: url)
            let value = try decoder.decode(type, from: data)
            return value
        } catch {
            throw error
        }
    }
    
    public static func remove(_ path: String, from directory: Directory) throws {
        do {
            let url = try getExistingFileURL(for: path, in: directory)
            try FileManager.default.removeItem(at: url)
        } catch {
            throw error
        }
    }
    
}

// MARK: - Helpers

extension Disk {
    static func createSubfoldersBeforeCreatingFile(at url: URL) throws {
        do {
            let subfolderUrl = url.deletingLastPathComponent()
            var subfolderExists = false
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: subfolderUrl.path, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    subfolderExists = true
                }
            }
            if !subfolderExists {
                try FileManager.default.createDirectory(at: subfolderUrl, withIntermediateDirectories: true, attributes: nil)
            }
        } catch {
            throw error
        }
    }
    
    static func createURL(for path: String?, in directory: Directory) throws -> URL {
        let filePrefix = "file://"
        let validPath: String? = nil

        var baseURL: URL?
        switch directory {
        case .caches:
            baseURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        case .applicationSupport:
            baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        case .appGroup:
            baseURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.fduhole.danxi")
        }
        
        if var url = baseURL {
            if let validPath = validPath {
                url = url.appendingPathComponent(validPath, isDirectory: false)
            }
            if url.absoluteString.lowercased().prefix(filePrefix.count) != filePrefix {
                let fixedUrlString = filePrefix + url.absoluteString
                url = URL(string: fixedUrlString)!
            }
            return url
        }
        
        throw LocatableError()
    }
    
    static func getExistingFileURL(for path: String?, in directory: Directory) throws -> URL {
        do {
            let url = try createURL(for: path, in: directory)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
            throw LocatableError()
        } catch {
            throw error
        }
    }
}

#endif
