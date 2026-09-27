import Foundation
@main struct KnowledgeGraphTests {
    static func check(_ value: @autoclosure () -> Bool, _ label: String) { precondition(value(), label) }
    static func main() throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "graph-\(UUID()).sqlite")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = try KnowledgeStore(url: url)
        let a = KnowledgeRecord(id: "a", kind: .material, name: "Synthetic alloy A")
        let b = KnowledgeRecord(id: "b", kind: .mechanism, name: "Synthetic mechanism")
        let c = KnowledgeRecord(id: "c", kind: .standard, name: "Synthetic standard")
        let d = KnowledgeRecord(id: "d", kind: .component, name: "Synthetic component")
        let source = KnowledgeRecord(id: "s", kind: .source, name: "Synthetic evidence")
        for r in [a,b,c,d,source] { try store.save(r) }
        let claim = EngineeringClaim(id: "e", subjectID: a.id, predicate: "property", statement: "Synthetic finding", sourceID: source.id, locator: "p1", status: .reviewed)
        try store.save(claim)
        let storedClaim = try store.claim(id: claim.id)!
        for edge in [KnowledgeRelationship(id: "1", fromID: "a", predicate: "susceptible", toID: "b", supportingClaimID: "e"), KnowledgeRelationship(id: "2", fromID: "b", predicate: "context", toID: "c"), KnowledgeRelationship(id: "3", fromID: "c", predicate: "cycle", toID: "a"), KnowledgeRelationship(id: "4", fromID: "c", predicate: "applies", toID: "d")] { try store.save(edge) }
        let graph = try KnowledgeGraph(store: store)
        check(Set(graph.traverse(from: "a", depth: 1).paths.map(\.id)) == ["b","c","s"], "first hop includes derived source")
        let paths = graph.traverse(from: "a", depth: 6).paths
        check(paths.count == 4 && Set(paths.map(\.id)).count == 4, "cycles and unique destinations")
        check(paths.first { $0.id == "d" }?.edges.count == 2, "shortest multi hop")
        check(graph.traverse(from: "missing").paths.isEmpty, "missing root")
        check(graph.traverse(from: "a", depth: 0).paths.isEmpty, "zero depth")
        check(graph.traverse(from: "a", limit: 1).paths.count == 1 && graph.traverse(from: "a", limit: 1).truncated, "limits observable")
        check(graph.edges.first { $0.id == "relationship:1" }?.claimID == claim.id, "stored provenance")
        check(graph.edges.first { $0.id == "claim:e" }?.to == source.id, "derived provenance")
        let comparison = graph.compare(["a", "b", "a"])
        check(comparison.count == 2 && comparison[0].claims == [storedClaim] && comparison[0].sources == [source], "comparison retains exact evidence and timestamps")
        check(comparison[0].standards == [c], "comparison standard")
        var archived = storedClaim; archived.status = .archived; try store.save(archived)
        let archivedGraph = try KnowledgeGraph(store: store)
        check(!archivedGraph.edges.contains { $0.id == "claim:e" }, "archived derivation excluded")
        check(archivedGraph.claims[claim.id]?.status == .archived, "stored edge still exposes archived provenance")
        let records = (0..<10000).map { KnowledgeRecord(id: "n\($0)", kind: .material, name: "Node \($0)") }
        let links = (1..<10000).map { KnowledgeRelationship(id: "l\($0)", fromID: "n0", predicate: "synthetic", toID: "n\($0)") }
        let start = Date()
        let large = KnowledgeGraph(records: records, claims: [], relationships: links).traverse(from: "n0", depth: 6, limit: 9000)
        check(large.paths.count == 500 && large.truncated, "hard safety cap")
        check(Date().timeIntervalSince(start) < 5, "representative 10000-node snapshot")
        print("KnowledgeGraph tests passed (10000 records, cycles, provenance, limits, comparison)")
    }
}
