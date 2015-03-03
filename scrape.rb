# include required gems
require 'find'
require 'rubygems'
require 'nokogiri'
require 'sanitize'
require 'csv'

# set up some global variables
$count = 0
$pages = Array.new
$base_path = "/Users/kevinquillen/Downloads/VelirFacelift-master/"

# generic function to replace MS word smart quotes and apostrophes
def strip_bad_chars(text)
  text.gsub!(/"/, "'");
  text.gsub!(/\u2018/, "'");
  text.gsub!(/[”“]/, '"');
  text.gsub!(/’/, "'");
  return text
end

# extra muscle for body content cleaning
def clean_body(text)
  text = strip_bad_chars(text)
  text.gsub!(/(\r)?\n/, "");
  text.gsub!(/\s+/, ' ');

  # clean start and end whitespace
  text = text.strip;
  return text
end

# this is the main logic that recursively searches from the current directory down, and parses the HTML files.
def parse_html_files
  Find.find(Dir.getwd) do |file|
    if !File.directory? file and File.extname(file) == '.html'
      # exclude and skip if in a bad directory
      # we may be on an html file, but some we just do not want
      current = File.new(file).path

      # skip these folders entirely
      if current.match(/(blog|old|draft|archive|font)/i)
        next
      end

      # open file, pluck content out by its element(s)
      page = Nokogiri::HTML(open(file));

      # grab title
      title = page.css('title').text.to_s;
      title = strip_bad_chars(title)

      # for page title, destroy any pipes and MS pipes and return the first match
      title.sub!('Velir | ', '')

      # Grab hero title and tagline
      hero = page.css('article.type-centered h2').text
      hero_tagline = page.css('article.type-centered .type-hero').text

      # grab the body content
      body = page.css('.outer-wrapper .row .columns').to_html
      body = clean_body(body)

      # clean the file path
      path = File.new(file).path
      path.gsub! $base_path, "/"

      # if we have content, add this as a page to our page array
      if (body.length > 0)
        $count += 1
        puts "Processing " + title

        # insert into array
        data = {
          'title' => title,
          'path' => path,
          'hero' => hero,
          'hero_tagline' => hero_tagline,
          'body' => body,
        }

        $pages.push data
      end
    end
  end

  write_csv($pages)
  report($count)
end

# This creates a CSV file from the $posts array created above
def write_csv(pages)
  CSV.open('pages.csv', 'w' ) do |writer|
    writer << ["title", "path", "hero", "hero_tagline", "body"]
    $pages.each do |c|
      writer << [c['title'], c['path'], c['hero'], c['hero_tagline'], c['body']]
    end
  end
end

# echo to the console how many posts were written to the CSV file.
def report(count)
  puts "#{$count} html files were processed to #{Dir.getwd}/pages.csv"
end

# trigger everything
parse_html_files
