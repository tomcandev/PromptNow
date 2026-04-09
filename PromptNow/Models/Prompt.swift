import Foundation
import SwiftData

@Model
class Prompt: Codable {
  enum CodingKeys: String, CodingKey {
    case id, title, content, tags, category, isFavorite, createdAt, updatedAt
  }

  var id: UUID = UUID()
  var title: String = ""
  var content: String = ""
  var tags: [String] = []
  var category: String = ""
  var isFavorite: Bool = false
  var createdAt: Date = Date.now
  var updatedAt: Date = Date.now

  init(
    id: UUID = UUID(),
    title: String = "",
    content: String = "",
    tags: [String] = [],
    category: String = "",
    isFavorite: Bool = false,
    createdAt: Date = Date.now,
    updatedAt: Date = Date.now
  ) {
    self.id = id
    self.title = title
    self.content = content
    self.tags = tags
    self.category = category
    self.isFavorite = isFavorite
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
    title = try container.decode(String.self, forKey: .title)
    content = try container.decode(String.self, forKey: .content)
    tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
    category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
    isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
    createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date.now
    updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date.now
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(title, forKey: .title)
    try container.encode(content, forKey: .content)
    try container.encode(tags, forKey: .tags)
    try container.encode(category, forKey: .category)
    try container.encode(isFavorite, forKey: .isFavorite)
    try container.encode(createdAt, forKey: .createdAt)
    try container.encode(updatedAt, forKey: .updatedAt)
  }
}
