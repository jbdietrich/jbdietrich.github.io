require 'kramdown'
require 'fileutils'
require 'date'
require 'rss'
require 'find'

# Configuration all the things!
site_url = 'https://wruby.btxx.org'
site_name = 'wruby'
author_name = 'Bradley Taunt'

posts_dir = 'posts'
pages_dir = 'pages'
public_dir = 'public'

output_dir = 'build'
posts_output_dir = "#{output_dir}/posts"
pages_output_dir = "#{output_dir}/"

header_file = 'header.html'
footer_file = 'footer.html'
root_index_file = 'index.md'
rss_file = "#{output_dir}/index.atom"

# Make sure output directories exist
[posts_output_dir, pages_output_dir].each { |dir| FileUtils.mkdir_p(dir) }

# Read the footer content
footer_content = File.read(footer_file)

# Replace the title meta tag in the header.html
def replace_title_placeholder(header_content, title)
  header_content.gsub('<title>{{TITLE}}</title>', "<title>#{title}</title>")
end

# Grab the title from each markdown file
def extract_title_from_md(lines)
  first_line = lines.first
  first_line&.start_with?('# ') ? first_line[2..-1].strip : 'Blog Index'
end

# Convert markdown files
def process_markdown_files(input_directory, output_directory, header_content, footer_content)
  items = []

  Find.find(input_directory) do |path|
    next unless path =~ /\.md\z/

    md_content = File.read(path)
    lines = md_content.lines

    title = extract_title_from_md(lines)
    date = Date.parse(lines[2]&.strip || '') rescue Date.today
    html_content = Kramdown::Document.new(md_content).to_html

    relative_path = path.sub(input_directory + '/', '').sub('.md', '')
    item_dir = File.join(output_directory, relative_path)
    output_file = "#{item_dir}/index.html"
    FileUtils.mkdir_p(item_dir)

    header = replace_title_placeholder(header_content, title)
    File.write(output_file, header + html_content + footer_content)

    items << { title: title, date: date, link: relative_path + '/', content: html_content }
  end

  items
end

# Create the root index file
def generate_index(posts, header_content, footer_content, root_index_file, output_dir, posts_dir)
  root_index_content = File.read(root_index_file)
  root_title = extract_title_from_md(root_index_content.lines)
  root_html = Kramdown::Document.new(root_index_content).to_html

  header = replace_title_placeholder(header_content, root_title)

  index_content = header + root_html + "<ul class=\"posts\">\n"
  posts.each { |post| index_content << "<li><span>#{post[:date]}</span><a href='/#{posts_dir}/#{post[:link]}'>#{post[:title]}</a></li>\n" }
  index_content << "</ul>\n" + footer_content

  File.write("#{output_dir}/index.html", index_content)
end

# Generate the RSS feed
def generate_rss(posts, rss_file, author_name, site_name, site_url, posts_dir)
  rss = RSS::Maker.make("atom") do |maker|
    maker.channel.author = author_name
    maker.channel.updated = Time.now.to_s
    maker.channel.about = site_url
    maker.channel.title = "#{site_name} RSS Feed"

    posts.each do |post|
      maker.items.new_item do |item|
        item.link = "#{site_url}/#{posts_dir}/#{post[:link]}"
        item.title = post[:title]
        item.updated = post[:date].to_s
        item.content.type = 'html'
        item.content.content = post[:content]
      end
    end
  end

  File.write(rss_file, rss)
end

# Process header, posts, pages, etc.
header_content = File.read(header_file)

posts = process_markdown_files(posts_dir, posts_output_dir, header_content, footer_content).sort_by { |post| -post[:date].to_time.to_i }
pages = process_markdown_files(pages_dir, pages_output_dir, header_content, footer_content)

generate_index(posts, header_content, footer_content, root_index_file, output_dir, posts_dir)
FileUtils.cp_r(public_dir, output_dir)
generate_rss(posts, rss_file, author_name, site_name, site_url, posts_dir)

puts "Blog built successfully in '#{output_dir}' folder. Have a great day!"
