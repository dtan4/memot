require "redcarpet"

module Memot
  class Markdown
    def self.parse_markdown(markdown)
      renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
      renderer.render(markdown)
    end
  end
end
