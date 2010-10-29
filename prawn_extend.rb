class Prawn::Document
  # 
  # Flow text in any number of columns with automatic continuing to next page
  # * uses entire bounds height and width unless margins are included in options
  # * always starts in first column regardless of current state of page
  # * uses text_box method
  # Options include (default)
  # *    :columns => n (2)
  # *    :top_margin => n (0)
  # *    :bottom_margin => n (0)
  # *    :gutter => n (18)
  # * any other options are also passed to text_box so you can use :size, :style, or whatever.
  def flow_in_columns(text, options)
      # Get any options or use defaults
      gutter = options[:gutter] || 18
      columns = options[:columns] || 2
      top_margin = options[:top_margin] || 0
      bottom_margin = options[:bottom_margin] || 0
      # calculate column left edges and widths (all are same width)
      col_width = (bounds.width-(columns-1)*gutter)/columns
      col_left_edge = []
      0.upto(columns-1) do |x|
        col_left_edge << x*(col_width+gutter)
      end  

      # Initialize for setting text    
      excess_text = text  # excess_text will keep whatever is left over after filling a given column
      column_number = 0
    
      # now repeat cycle of fill a column, fill next column with leftover text, etc., 
      # ... going to next page after filling all the columns on current page
      until excess_text.empty?
        excess_text = text_box(excess_text, {
          :width => col_width,
          :height => bounds.height-top_margin-bottom_margin,
          :overflow => :truncate,
          :at => [col_left_edge[column_number], bounds.top-top_margin],
        }.merge(options)) # merge any options sent as parameters, which could include :align, :style etc.
        column_number = (column_number+1) % columns
        start_new_page if column_number == 0 && excess_text > ''
      end
  end #method

  class BoundingBox
    def to_s
         return "[#{self.left},#{self.top}], width=#{self.width}, height=#{self.height}"
    end
  end

end #class

