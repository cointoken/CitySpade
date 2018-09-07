module ImageHelper
  def origin_height
    self[:dimensions][1]
  end
  def origin_width
    self[:dimensions][0]
  end

  def origin_rate
    origin_width / origin_height.to_f
  end

  def size_limit?(width, height)
    if origin_width < width
      return false #if (width - origin_width) / origin_width.to_f > 0.1
    end
    if origin_height < height
      return false #if (height - origin_height) / origin_height.to_f > 0.1
    end
    true
  end

  def decorator_resize(*arg)
    if arg.size  == 1
      arg = arg.first.split(/x/i)
    end
    width, height = arg.map(&:to_i)
    if size_limit?(width, height)
      rate = width / height.to_f
      if rate > origin_rate 
        crop_width = origin_width
        crop_height = crop_width / rate
      else
        crop_height = origin_height
        crop_width   = crop_height * rate
      end
      x1 = (origin_width - crop_width) / 2
      x2 = x1 + crop_width 
      y1 = (origin_height - crop_height) / 2
      y2 = y1 + crop_height
      crop("#{x2-x1}X#{y2-y1}+#{x1}+#{y1}")
      resize("#{width}X#{height}")
    else
      resize_with_bg(width, height)
    end
  end
  def resize_with_bg(width, height)
    combine_options do |c|
      c.gravity 'center'
      c.background 'white'
      c.resize "#{width}x#{height}" if origin_height > height || origin_width > width
      c.extent "#{width}x#{height}"
      c.border 1
      c.bordercolor '#cccccc'
    end
  end
end
