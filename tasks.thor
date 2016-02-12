require 'time'
require 'fileutils'

class Blog < Thor
  include Thor::Actions

  desc 'post TITLE', 'Create a new post with current date'
  def post(title)
    @title = title
    template('_templates/post.tt',
             "_posts/#{date_string}-#{title_string}.markdown")
  end

  desc 'draft TITLE', 'Create a draft with given title'
  def draft(title)
    @title = title
    template('_templates/draft.tt',
             "_drafts/#{title_string}.markdown")
  end

  desc 'publish', 'Move a draft to the post folder, adding date'
  def publish
    drafts = Dir['_drafts/*.markdown']
    abort 'No drafts' if drafts.empty?
    
    drafts.each_with_index do |d, i|
      puts "[#{i}] - #{File.basename(d)}"
    end

    selected = ask 'Please select a draft to publish',
                   limited_to: (0..drafts.size - 1).map(&:to_s)
    file = drafts[selected.to_i]
    dest = "_posts/#{date_string}-#{File.basename(file)}"
    FileUtils.mv(file, dest)
    say "Post #{dest} is created"
  end

  def self.source_root
    File.dirname(__FILE__)
  end
  
  private

  def title_string
    @title.downcase.split(/\s/).join('-') 
  end
  
  def date_string
    Date.today.strftime('%Y-%m-%d')
  end
end
