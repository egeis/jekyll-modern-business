module Jekyll

  class CategoryPage < Page
    def initialize(site, base, dir, category)
      @site = site
      @base = base
      @dir = dir
      @name = 'index.html'

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'category_index.html')
      self.data['paginate']['category'] = "#{category}"
      self.data['category'] = category

      category_title_prefix = site.config['category_title_prefix']
      self.data['title'] = "#{category_title_prefix}#{category}"
    end
  end

  class CategoryPageGenerator < Generator
    safe true
    priority :highest

    def generate(site)
      if site.layouts.key? 'category_index'
        dir = site.config['category_dir'] || 'categories'
        site.categories.each_key do |category|
            new_page = CategoryPage.new(site, site.source, File.join(dir, category), category)
            Octopress::Paginate.paginate(new_page)
            site.pages << new_page
        end
      end
    end
  end

end