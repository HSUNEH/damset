#!/usr/bin/env ruby
# frozen_string_literal: true

require "date"
require "pathname"
require "yaml"

root = Pathname.new(__dir__).join("..").expand_path
wiki = root.join("wiki")
errors = []

required = %w[
  AGENTS.md
  wiki/index.md
  wiki/log.md
  wiki/schema.md
]

required.each do |relative_path|
  path = root.join(relative_path)
  errors << "missing required file: #{relative_path}" unless path.file?
end

pages = Dir[wiki.join("**/*.md").to_s].sort.map { |path| Pathname.new(path) }
allowed_types = %w[index schema product architecture tools playbook decision log]
allowed_statuses = %w[active draft deprecated superseded]

pages.each do |page|
  relative = page.relative_path_from(root)
  content = page.read
  frontmatter = content.match(/\A---\n(.*?)\n---\n/m)

  unless frontmatter
    errors << "#{relative}: missing YAML frontmatter"
    next
  end

  begin
    metadata = YAML.safe_load(frontmatter[1], permitted_classes: [], aliases: false)
  rescue Psych::Exception => error
    errors << "#{relative}: invalid YAML frontmatter (#{error.message.lines.first.strip})"
    next
  end

  unless metadata.is_a?(Hash)
    errors << "#{relative}: frontmatter must be a mapping"
    next
  end

  errors << "#{relative}: invalid or missing type" unless allowed_types.include?(metadata["type"])
  errors << "#{relative}: invalid or missing status" unless allowed_statuses.include?(metadata["status"])

  begin
    Date.iso8601(metadata.fetch("updated"))
  rescue KeyError, ArgumentError, TypeError
    errors << "#{relative}: updated must be a quoted ISO date"
  end

  content.scan(/\[[^\]]+\]\(([^)]+)\)/).flatten.each do |target|
    target = target.strip.delete_prefix("<").delete_suffix(">")
    next if target.empty? || target.start_with?("#")
    next if target.match?(/\A(?:https?:|mailto:|app:)/)

    file_target = target.split("#", 2).first
    resolved = page.dirname.join(file_target).cleanpath
    errors << "#{relative}: broken relative link #{target}" unless resolved.exist?
  end
end

index_path = wiki.join("index.md")
if index_path.file?
  index = index_path.read
  pages.each do |page|
    next if page == index_path

    relative = page.relative_path_from(wiki).to_s
    errors << "wiki/index.md: missing page link (#{relative})" unless index.include?("(#{relative})")
  end
end

log_path = wiki.join("log.md")
if log_path.file?
  log_headings = log_path.read.lines.grep(/\A## \[/)
  heading_pattern = /\A## \[\d{4}-\d{2}-\d{2}\] (?:feature|fix|refactor|qa|docs|decision|maintenance|setup) \| .+/
  log_headings.each do |heading|
    errors << "wiki/log.md: invalid log heading #{heading.strip.inspect}" unless heading.match?(heading_pattern)
  end
end

if errors.empty?
  puts "agent wiki ok (#{pages.length} pages)"
  exit 0
end

warn errors.map { |error| "- #{error}" }.join("\n")
exit 1
