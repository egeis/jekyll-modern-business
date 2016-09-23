module Drops
  class BreadcrumbItem < Liquid::Drop
    extend Forwardable

    def_delegator :@page, :data
    def_delegator :@page, :url

    # --
    # Initialize a new instance.
    # --
    def initialize(page, payload)
      @payload = payload
      @page = page
    end

    # --
    # The title of the post or page.
    # @return [String]
    # --
    def title
      @page.data["breadcrumb"] != nil ? @page.data["breadcrumb"] : @page.data["title"]
    end
  end
end