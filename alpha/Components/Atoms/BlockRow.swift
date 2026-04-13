import SwiftUI

struct BlockRow: Identifiable {
    let id: UUID
    let blocks: [CanvasBlock]

    var isGrouped: Bool { blocks.count > 1 }

    static func group(_ blocks: [CanvasBlock]) -> [BlockRow] {
        var rows: [BlockRow] = []
        var i = 0
        while i < blocks.count {
            let block = blocks[i]
            if let gid = block.rowGroupID {
                var grouped = [block]
                var j = i + 1
                while j < blocks.count, blocks[j].rowGroupID == gid {
                    grouped.append(blocks[j])
                    j += 1
                }
                rows.append(BlockRow(id: gid, blocks: grouped))
                i = j
            } else {
                rows.append(BlockRow(id: block.id, blocks: [block]))
                i += 1
            }
        }
        return rows
    }
}
