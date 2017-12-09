class Care
  def initialize(page_size)
    @page_size = page_size.to_i
    raise ArgumentError, "The page size must be a positive Integer" unless @page_size > 0
    @pages = {}
    @lowest_known_empty_page = nil
  end

  def byteslice(io, at, n_bytes)
    first_page = at / @page_size
    last_page = (at + n_bytes) / @page_size
    local_offset_on_first_page = at % @page_size

    relevant_pages = (first_page..last_page).map{|i| hydrate_page(io, i) }

    slab = relevant_pages.join
    slice = slab.byteslice(local_offset_on_first_page, n_bytes)

    if slice && !slice.empty?
      slice
    else
      nil
    end
  end

  def hydrate_page(io, page_i)
    # Avoid trying to read the page if we know there is no content to fill it
    # in the underlying IO
    if @lowest_known_empty_page && page_i >= @lowest_known_empty_page
      return nil
    end

    @pages[page_i] ||= begin
      io.seek(page_i * @page_size)
      read_result = io.read(@page_size)

      if read_result.nil?
        if @lowest_known_empty_page.nil? || @lowest_known_empty_page > page_i
          @lowest_known_empty_page = page_i
        end
      end

      read_result
    end
  end
end
