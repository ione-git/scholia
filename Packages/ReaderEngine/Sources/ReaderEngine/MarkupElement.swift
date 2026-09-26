import Foundation

nonisolated final class MarkupElement {
    let name: String
    let namespace: String?
    let attributes: [String: String]
    fileprivate(set) var text = ""
    fileprivate(set) var children: [MarkupElement] = []

    fileprivate init(name: String, namespace: String?, attributes: [String: String]) {
        self.name = name
        self.namespace = namespace
        self.attributes = attributes
    }

    static func parse(_ data: Data) -> MarkupElement? {
        let builder = TreeBuilder()
        let parser = XMLParser(data: data)
        parser.shouldProcessNamespaces = true
        parser.delegate = builder
        guard parser.parse() else { return nil }
        return builder.root
    }

    func descendants(named name: String, namespace: String?) -> [MarkupElement] {
        children.flatMap { child in
            let matches = child.name == name && (namespace == nil || child.namespace == namespace)
            return (matches ? [child] : []) + child.descendants(named: name, namespace: namespace)
        }
    }
}

nonisolated private final class TreeBuilder: NSObject, XMLParserDelegate {
    private(set) var root: MarkupElement?
    private var path: [MarkupElement] = []

    func parser(
        _ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?,
        attributes: [String: String]
    ) {
        let element = MarkupElement(name: elementName, namespace: namespaceURI, attributes: attributes)
        if let parent = path.last {
            parent.children.append(element)
        } else {
            root = element
        }
        path.append(element)
    }

    func parser(
        _ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?
    ) {
        path.removeLast()
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        path.last?.text += string
    }
}
