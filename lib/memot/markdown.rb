require "redcarpet"

module Memot
  class Markdown
    def self.parse_markdown(markdown)
      markdown = markdown.gsub("<", "&lt;").gsub(">", "&gt;")
      renderer = Redcarpet::Markdown.new(Redcarpet::Render::XHTML, autolink: true)

      renderer.render(markdown) rescue markdown
    end
  end
end
