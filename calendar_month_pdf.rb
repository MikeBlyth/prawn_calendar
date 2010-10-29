require 'prawn_extend'
require 'reports_helper'

# Prawn document to generate PDF calendar for a given month
class CalendarMonthPdf < Prawn::Document
include ReportsHelper

    DEFAULT_MARGIN = 36
    DAYS_PER_WEEK = 7
    CELL_PADDING = 2

    # Initialization yields a Prawn document which already has a calendar grid for the given month
    # Parameters
    # * :day_numbers => false  means do not number the boxes
    # * :margins => _n_  :  apply _n_ points margin all around calendar, in addition to normal page margins   
    # * :title => |:month|:month_year|:none|"string"|   (default is :month_year)
    # * :title_format => _hash_    (Prawn formatting parameters to be applied to title) 
    # * :day_number_format => _hash_  (formatting for day numbers) 
    # * :box => _boolean_  (draw box at page margins)
    def initialize(month, year, params={})
      # First, the calculations
      # Consider calendar as having 7 columns (0..6) and row_count rows (0..row_count)
      # First, find where the first of the month will go. Row 0, column first_dow
      params[:page_layout] ||= :landscape
      super(params)   # initialize Prawn::Document with page size, orientation, etc.

      @month = month
      @year = year
      @first = Date.new(year,month,1)
      @last = @first.end_of_month
      @first_wday = @first.wday
      @last_wday = @last.wday
      @row_count = date_to_row_col(@last)[0] + 1  # zero based, so count is one more than last row
      @margins = params[:margins] || DEFAULT_MARGIN
      @calendar_height = bounds.height-2*@margins   # subtract margins equally on top and bottom,
      @calendar_width = bounds.width-2*@margins     # ... and both sides
      @cell_height = @calendar_height/@row_count
      @cell_width = @calendar_width/DAYS_PER_WEEK 
      # Redefine width and height now to eliminate any rounding issues.
      @calendar_width = @right_edge = DAYS_PER_WEEK * @cell_width
      @calendar_height = @top_edge = @row_count*@cell_height  # remember that 0 is bottom, and y increases as we move up on page
      # Start Drawing
      move_down 5
      # Define the title 
      if params[:title].class==String
        title = param[:title]
      else  
        title = case params[:title] || :month_year        # making :month_year the default
          when :none then ''
          when :month then Date::MONTHNAMES[month]
          when :month_year then Date::MONTHNAMES[month] + " #{year}"
          else 'Unrecognized title option'
        end
      end    
      # Draw the title (bounds at this point are still the page margins) 
      text title, {:size=>24, :align=>:center}.merge(params[:title_format] || {})
      stroke_bounds if params[:box]    
      bounding_box([margins,@calendar_height+margins], :width=>@calendar_width, :height=>@calendar_height) do
        # Now, within new bounding_box, everything is relative to calendar itself, not the page or page margins!
        draw_horizontal_lines
        draw_vertical_lines
      end  
      # Number the boxes
      unless params[:day_numbers] == false
        (1..@last.day).each do |d|
          in_box_for_day(d) do
            text d.to_s, {:size=>10, :align=>:left}.merge(params[:day_number_format] || {})
          end   
        end
      end
    end

    # Generate a bounding_box to fit in the cell for the given day. in_day is an alias.
    # Used just like a bounding_box, for example
    # * in_box_for_day(25) {text "Christmas", :align=>:center, :valign=>:center}
    # * in_day(24) {text "Christmas eve"} 
    # Bounds are based on page margins (initial setup) and not on the bottom-left corner of the calendar
    def in_box_for_day(day)
      box_corner = day_to_xy(day)
      box_corner[0] = box_corner[0]+CELL_PADDING+@margins
      box_corner[1] = box_corner[1]-CELL_PADDING+@margins
      box_width = @cell_width-2*CELL_PADDING
      box_height = @cell_height - 2*CELL_PADDING
      bounding_box(box_corner, :width=>box_width, :height=>box_height) do
        yield
      end
    end
    # 
    alias in_day in_box_for_day    

private

    # For any date, find where it goes (zero-based row & column) in a one-month calendar of that month
    def date_to_row_col(date)
      first_dow = Date.new(date.year,date.month,1).wday     # Sunday = 0
       [(date.day+first_dow-1)/7, (date.day+first_dow-1) % 7] 
    end 

    # For a day _this_ month find where it goes (zero-based row & column) 
    def day_to_row_col(day)
      [(day+@first_wday-1)/7, (day+@first_wday-1) % 7]
    end
    
    # Translate row and column to an x,y position representing top-left corner of box
    # Arguments: row_col is an array of the row and column number. row_col[0] is row number, row_col[1] is column.
    # Returns: array of x and y points, where 0,0 is the BOTTOM-left corner of calendar 
    # note that with row-column the vertical component (row) is first, while the return value xy has x first
    def row_col_to_xy(row_col) 
      [ row_col[1]*@cell_width, (@row_count-row_col[0])*@cell_height]  # oh, that was easy!
    end
    
    def day_to_xy(day)
      row_col_to_xy(day_to_row_col(day))
    end

    def draw_horizontal_lines
      move_cursor_to(@top_edge)
      # Top line goes from first day to right margin
      horizontal_line @first_wday*@cell_width, (DAYS_PER_WEEK)*@cell_width
      # These lines go across whole width of calendar
      (1..@row_count-1).each do |r|
        move_down @cell_height
        horizontal_line 0, 7 * @cell_width
      end
      # Bottom line goes from left margin to last day + its cell width
      move_down @cell_height
      horizontal_line 0, @cell_width*(1+@last_wday)
      # this leaves us at the bottom line of the calendar
      stroke
    end

    def draw_vertical_lines
      (0..DAYS_PER_WEEK).each do |d|
        # top position for line
        if d < @first_wday
          top_y = @top_edge-@cell_height
        else
          top_y = @top_edge
        end
        # bottom position for line
        if d < @last_wday + 2
          bottom_y = 0
        else
          bottom_y = @cell_height
        end
        vertical_line top_y, bottom_y, :at => d*@cell_width
      end  
      stroke
    end  

end

