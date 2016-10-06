# "paging" =>
#       "per_page" =>
#
#
#
#
#

module Jekyll
  class Page
    attr_accessor :dir
  end

  module Generators
    class Pagination < Generator
      # This generator is safe from arbitrary code execution.
      safe true

      # Generate paginated pages if necessary.
      #
      # site - The Site.
      #
      # Returns nothing.
      def generate(site)
        puts site.config['paging']
      
        puts 'Paginating: Blog'
        paginate(site, '/blog/index.html', 'blog')
        puts 'Paginating: Project'
        paginate(site, '/portfolio/index.html', 'project')
        puts 'Paginating: Blog Categories'
        paginate_categories(site, site.config['paging']['blog']['category_dir'], 'blog_category_index.html', site.categories['blog'], 'blog')
        puts 'Paginating: Portfolio Categories'
        paginate_categories(site, site.config['paging']['project']['category_dir'], 'portfolio_category_index.html', site.categories['project'], 'project')
      end

      # Paginates the blog's posts. Renders the index.html file into paginated
      # directories, e.g.: page2/index.html, page3/index.html, etc and adds more
      # site-wide data.
      #
      # site - The Site.
      # page - The index.html Page that requires pagination.
      #
      # {"paginator" => { "page" => <Number>,
      #                   "per_page" => <Number>,
      #                   "posts" => [<Post>],
      #                   "total_posts" => <Number>,
      #                   "total_pages" => <Number>,
      #                   "previous_page" => <Number>,
      #                   "next_page" => <Number> }}
      def paginate(site, page_path, category)
        all_posts = site.site_payload['site']['categories'][category]

        page = site.pages.select do |page|
          path = "#{page.dir}/#{page.name}"
          path == page_path
        end.first

        pages = Pager.calculate_pages(all_posts, site.config['paging'][category]['per_page'].to_i)
        (1..pages).each do |num_page|
          pager = Pager.new(site, num_page, all_posts, pages, page)
          
          if num_page > 1
            newpage = Page.new(site, site.source, page.dir, page.name)
            newpage.pager = pager
            newpage.dir = File.join(page.dir, "page#{num_page}")
            site.pages << newpage
          else
            page.pager = pager
          end
          
        end
      end

      def paginate_categories(site, category_path, category_layout, posts, category_index)
        categories = []
        restricted_categories = ['blog', 'project']
        

        for post in posts
          for post_category in site.categories
            categories.push(post_category) unless restricted_categories.include? post_category
          end
        end

        categories.sort!.uniq!
        
        for category in categories
          all_posts = site.site_payload['site']['categories'][category]

          page = site.pages.select do |page|
            path = "#{page.dir}/#{page.name}"
            path == "#{category_path}/#{category}/index.html"
          end.first
          
          pages = Pager.calculate_pages(all_posts, site.config['paging'][category_index]['per_page'].to_i)
          (1..pages).each do |num_page|
            pager = Pager.new(site, num_page, all_posts, pages, page)
            if num_page > 1
              newpage = CategoryIndex.new(site, site.source, page.dir, category, category_layout)
              newpage.pager = pager
              newpage.dir = File.join(page.dir, "page#{num_page}")
              site.pages << newpage
            else
              page.pager = pager
            end
          end 
        end       
      end
    end
  end

  class Pager
    attr_reader :page, :per_page, :posts, :total_posts, :total_pages,
      :previous_page, :previous_page_path, :next_page, :next_page_path

    # Calculate the number of pages.
    #
    # all_posts - The Array of all Posts.
    # per_page  - The Integer of entries per page.
    #
    # Returns the Integer number of pages.
    def self.calculate_pages(all_posts, per_page)
      (all_posts.size.to_f / per_page.to_i).ceil
    end

    # Determine if the subdirectories of the two paths are the same relative to source
    #
    # source        - the site source
    # page_dir      - the directory of the Jekyll::Page
    # paginate_path - the absolute paginate path (from root of FS)
    #
    # Returns whether the subdirectories are the same relative to source
    def self.in_hierarchy(source, page_dir, paginate_path)
      return false if paginate_path == File.dirname(paginate_path)
      return false if paginate_path == Pathname.new(source).parent
      page_dir == paginate_path ||
        in_hierarchy(source, page_dir, File.dirname(paginate_path))
    end

    # Static: Return the pagination path of the page
    #
    # site     - the Jekyll::Site object
    # num_page - the pagination page number
    # target_page - the page where pagination is occurring
    #
    # Returns the pagination path as a string
    def self.paginate_path(site, num_page, target_page)
      return nil if num_page.nil?
      return target_page.url if num_page <= 1
      format = site.config['paging']['permalink']
      format = format.sub(':num', num_page.to_s)
      ensure_leading_slash(format)
    end

    # Static: Return a String version of the input which has a leading slash.
    #         If the input already has a forward slash in position zero, it will be
    #         returned unchanged.
    #
    # path - a String path
    #
    # Returns the path with a leading slash
    def self.ensure_leading_slash(path)
      path[0..0] == "/" ? path : "/#{path}"
    end

    # Static: Return a String version of the input without a leading slash.
    #
    # path - a String path
    #
    # Returns the input without the leading slash
    def self.remove_leading_slash(path)
      ensure_leading_slash(path)[1..-1]
    end

    # Initialize a new Pager.
    #
    # config    - The Hash configuration of the site.
    # page      - The Integer page number.
    # all_posts - The Array of all the site's Posts.
    # num_pages - The Integer number of pages or nil if you'd like the number
    #             of pages calculated.
    def initialize(site, page, all_posts, num_pages = nil, target_page)
      @page = page
      @per_page = site.config['custom_paginate'].to_i
      @total_pages = num_pages || Pager.calculate_pages(all_posts, @per_page)

      if @page > @total_pages
        raise RuntimeError, "page number can't be greater than total pages: #{@page} > #{@total_pages}"
      end

      init = (@page - 1) * @per_page
      offset = (init + @per_page - 1) >= all_posts.size ? all_posts.size : (init + @per_page - 1)

      @total_posts = all_posts.size
      @posts = all_posts[init..offset]
      @previous_page = @page != 1 ? @page - 1 : nil
      @previous_page_path = Pager.paginate_path(site, @previous_page, target_page)
      @next_page = @page != @total_pages ? @page + 1 : nil
      @next_page_path = Pager.paginate_path(site, @next_page, target_page)
    end

    # Convert this Pager's data to a Hash suitable for use by Liquid.
    #
    # Returns the Hash representation of this Pager.
    def to_liquid
      {
        'page' => page,
        'per_page' => per_page,
        'posts' => posts,
        'total_posts' => total_posts,
        'total_pages' => total_pages,
        'previous_page' => previous_page,
        'previous_page_path' => previous_page_path,
        'next_page' => next_page,
        'next_page_path' => next_page_path
      }
    end
  end
end