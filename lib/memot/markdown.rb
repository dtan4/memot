rrequire "redcarpet"

module Memot
  class Markdown
    def parse_markdown(markdown)
      renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
      renderer.render(markdown)
    end
  end
end
