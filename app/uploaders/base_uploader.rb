# encoding: utf-8
require 'carrierwave/processing/mini_magick'
class BaseUploader < CarrierWave::Uploader::Base

  include CarrierWave::MiniMagick
  storage  (Rails.env.development? ? :file : :fog)

  process :resize_to_limit => [1500, 1200]

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def extension_white_list
    [/jpe?g/i, 'gif', 'png', 'bmp']
  end

  def custom_decorator_resize(*arg)
    if arg.size == 1
      arg = arg.first.split(/x/i)
    end
    width, height = arg.map(&:to_i)
    rate = width / height.to_f

    manipulate! do |origin_file|
      origin_width = origin_file[:width]
      origin_height = origin_file[:height]
      origin_rate = origin_width / origin_height.to_f

      if rate > origin_rate
        crop_width = origin_width
        crop_height = crop_width / rate
      else
        crop_height = origin_height
        crop_width = crop_height * rate
      end

      # 截取中间部分
      x1 = (origin_width - crop_width) / 2
      x2 = x1 + crop_width
      y1 = (origin_height - crop_height) / 2
      y2 = y1 + crop_height
      origin_file.crop("#{x2-x1}X#{y2-y1}+#{x1}+#{y1}")
      origin_file.resize("#{width}X#{height}")
      origin_file
    end
  end
end
