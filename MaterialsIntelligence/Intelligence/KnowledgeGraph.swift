import Foundation

/// A read-only snapshot of the existing repository, never a second persistence layer.
struct KnowledgeGraph {
    struct Edge: Identifiable, Equatable {
        let id: String
        let from: String
        let to: String
        let predicate: String
        let claimID: String?
        let derived: Bool
    }
    struct Path: Identifiable {
        let recordIDs: [String]
        let edges: [Edge]
        var id: String { recordIDs.last ?? "" }
    }
    struct Traversal {
        let paths: [Path]
        let truncated: Bool
    }
    struct Comparison {
        let record: KnowledgeRecord
        let claims: [EngineeringClaim]
        let links: [Edge]
        let sources: [KnowledgeRecord]
        let standards: [KnowledgeRecord]
    }
    let records: [String: KnowledgeRecord]
    let claims: [String: EngineeringClaim]
    let edges: [Edge]
    private let adjacency: [String: [Edge]]

    init(store: KnowledgeStore) throws {
        self.init(records: try store.records(), claims: try store.claims(), relationships: try store.relationships())
    }
    init(records: [KnowledgeRecord], claims: [EngineeringClaim], relationships: [KnowledgeRelationship]) {
        self.records = Dictionary(uniqueKeysWithValues: records.map { ($0.id, $0) })
        self.claims = Dictionary(uniqueKeysWithValues: claims.map { ($0.id, $0) })
        let ids = Set(records.map(\.id))
        var links = relationships.filter { ids.contains($0.fromID) && ids.contains($0.toID) }.map {
            Edge(id: "relationship:" + $0.id, from: $0.fromID, to: $0.toID, predicate: $0.predicate, claimID: $0.supportingClaimID, derived: false)
        }
        links += claims.filter { ids.contains($0.subjectID) && ids.contains($0.sourceID) && $0.status != .archived && $0.status != .superseded }.map {
            Edge(id: "claim:" + $0.id, from: $0.subjectID, to: $0.sourceID, predicate: "cites source", claimID: $0.id, derived: true)
        }
        edges = links.sorted { $0.id < $1.id }
        var index: [String: [Edge]] = [:]
        for edge in edges { index[edge.from, default: []].append(edge); index[edge.to, default: []].append(edge) }
        adjacency = index
    }
    func neighbors(_ id: String) -> [Edge] { adjacency[id] ?? [] }
    /// Bidirectional browsing does not reverse the meaning of an edge. One shortest path per record.
    func traverse(from root: String, depth: Int = 2, limit: Int = 100) -> Traversal {
        guard records[root] != nil else { return Traversal(paths: [], truncated: false) }
        let depth = min(max(depth, 0), 6), limit = min(max(limit, 0), 500)
        var queue = [Path(recordIDs: [root], edges: [])], visited: Set<String> = [root]
        var result: [Path] = [], head = 0, truncated = false
        while head < queue.count {
            let path = queue[head]; head += 1
            let current = path.recordIDs.last!
            for edge in neighbors(current) {
                let next = edge.from == current ? edge.to : edge.from
                guard !visited.contains(next) else { continue }
                guard path.edges.count < depth, result.count < limit else { truncated = true; continue }
                visited.insert(next)
                let nextPath = Path(recordIDs: path.recordIDs + [next], edges: path.edges + [edge])
                queue.append(nextPath); result.append(nextPath)
            }
        }
        return Traversal(paths: result, truncated: truncated)
    }
    func compare(_ ids: [String]) -> [Comparison] {
        var seen = Set<String>()
        return ids.filter { seen.insert($0).inserted }.compactMap { id in
            guard let record = records[id] else { return nil }
            let evidence = claims.values.filter { $0.subjectID == id }.sorted { ($0.predicate, $0.id) < ($1.predicate, $1.id) }
            let links = neighbors(id)
            let sourceIDs = Set(evidence.map(\.sourceID))
            let related = Set(links.flatMap { [$0.from, $0.to] })
            return Comparison(record: record, claims: evidence, links: links,
                sources: sourceIDs.compactMap { records[$0] }.sorted { $0.id < $1.id },
                standards: related.compactMap { records[$0] }.filter { $0.kind == .standard }.sorted { $0.id < $1.id })
        }
    }
}
