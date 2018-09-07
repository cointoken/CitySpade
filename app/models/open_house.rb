class OpenHouse < ActiveRecord::Base
  belongs_to :listing
  default_scope ->{ where('(open_date = :today and hour(end_time) >= :end_hour)
                          or open_date > :today or
                          (`loop` = :loop and (expired_date >= :today or expired_date is null))',
                          today: Date.today, loop: true, end_hour: Time.now.hour) }

  scope :listings, -> { Listing.enables.where(id: distinct(:listing_id).select(:listing_id)) }

  def f_date(format = "%a, %b %-d")
    unless self.loop
      open_date.strftime(format)
    else
      wdays = self.listing.open_houses.where("hour(begin_time) = ? and hour(end_time) = ?", self.begin_time.hour, self.end_time.hour)
        .to_a.uniq{|s| s.open_date.wday}
        .sort{|x, y|
        (x.open_date.wday == 0 ? 7 : x.open_date.wday) <=> (y.open_date.wday == 0 ? 7 : y.open_date.wday)}
          .map{|s| s.open_date.strftime("%a")}
        if wdays.size == 1
          wdays[0]
        else
          "#{wdays[0]} - #{wdays[-1]}"
        end
    end
  end

  def real_date_to_calendar
    if self.loop
      r_d = self.open_date
      while r_d < Date.today
        r_d += self.next_days.day
      end
    else
      r_d = self.open_date
    end
    r_d.strftime("%Y%m%d")
  end

  def real_end_date_to_i
    if self.loop
      real_date_to_calendar
    else
      self.open_date.strftime("%Y%m%d")
    end
  end

  def use_utc?
    if begin_time.hour == 0
      end_time.hour < 20 && end_time.hour >= 12
    else
      (end_time.hour < 20 && begin_time.hour > 8 && end_time.hour > begin_time.hour)||
      begin_time.in_time_zone("Eastern Time (US & Canada)").hour < 7
      #end_time.in_time_zone("Eastern Time (US & Canada)").hour > 21
    end
  end

  def f_begin_time
    use_begin_time.strftime("%l:%M %p")
  end

  def f_end_time
    use_end_time.strftime("%l:%M %p")
  end

  def use_begin_time
    use_utc? ? begin_time : begin_time.in_time_zone("Eastern Time (US & Canada)")
  end

  def use_end_time
    use_utc? ? end_time : end_time.in_time_zone("Eastern Time (US & Canada)")
  end

  def f_time
    f_begin_time + " - " + f_end_time
  end

  def open_time
    "#{self.f_date} ( #{self.f_begin_time} - #{self.f_end_time} )"
  end


  def google_calendar_link opt = {}
    opt= {action: 'TEMPLATE', text: 'Open House with CitySpade',
          dates:"#{self.real_date_to_calendar}T#{use_begin_time.strftime("%H%M%S")}/#{self.real_end_date_to_i}T#{use_end_time.strftime("%H%M%S")}",
    }.merge opt
    "https://www.google.com/calendar/render?#{opt.to_param}"
  end

  def self.default
    new open_date: Date.today + rand(10).day, begin_time: '9:00 am', end_time: '4:20 pm'
  end
end
