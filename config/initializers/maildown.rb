# Necesssary until https://github.com/zombocom/maildown/pull/71 is merged/fixed
Maildown::MarkdownEngine.set_html do |markdown|
  Redcarpet::Markdown.new(Redcarpet::Render::HTML, {}).render(markdown.to_s).html_safe
end
