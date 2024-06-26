# frozen_string_literal: true
require "jekyll"

require_relative "../patch/context"
require_relative "../patch/doc_manager"
require_relative "../patch/site"
require_relative "../util/link_index"
require_relative "../util/parser"

module Jekyll
  module WikiRefs

    class Generator < Jekyll::Generator

      def generate(site)
        return if $wiki_conf.disabled?

        @site ||= site
        @context ||= Jekyll::WikiRefs::Context.new(site)

        # setup helper classes
        @parser = Parser.new(@site)
        @site.link_index = LinkIndex.new(@site)

        @site.doc_mngr.all.each do |doc|
          if doc.content.nil?
            Jekyll.logger.debug "Skipping:", "Content in #{doc.relative_path} is nil"
          elsif
            filename = File.basename(doc.basename, File.extname(doc.basename))
            @parser.parse(filename, doc.content)
            @site.link_index.populate(doc, @parser.wikilink_blocks, @parser.wikilink_inlines)
          end
        end
        # wait until all docs are processed before assigning backward facing metadata,
        # this ensures all attributed/backlinks are collected for assignment
        @site.doc_mngr.all.each do |doc|
          # populate frontmatter metadata from (wiki)link index
          @site.link_index.assign_metadata(doc)
        end
      end

    end

  end
end
