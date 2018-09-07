class Admin::WeekListingsController < Admin::BaseController
  before_filter :require_admin
  def index
    @dates = []                           # 存放日期
    @week_new_listings_counts = []
    @week_expired_listings_counts = []
    @sum_listings_counts = []
    @days = 7                             # 查询天数：默认7天,8日的间隔
    end_time = Time.now                   # 结束日期：默认到今天为止
    start_time = Time.now - 7.days        # 开始日期：默认一个星期前

    # 计算开始日期，结束日期，查询天数
    if !params[:week_listings_start].blank? and !params[:week_listings_end].blank?
      start_time = params[:week_listings_start].to_time
      end_time = params[:week_listings_end].to_time
      @days = ((end_time - start_time)/60/60/24).to_i
    end
    # 查询网站
    if !params[:week_listings_sites].blank?
      sites = params[:week_listings_sites]
      @sites = sites.blank? ? ['bushari'] : sites
    else
      @sites = ['bushari']
    end

    # 计算相关的listings
    @days.times {|i| @dates.push(end_time - i.day)}
    @dates.push(start_time)
    site_lis = []
    @sites.each do |site|
      site_lis.push(Listing.send(site.sub('-', '').to_sym))
    end

    site_lis.each_with_index do |li, i|
      new_listings_count = []
      @dates.each_with_index do |date, index|
        new_listings_count.push(li.where(status: 0).where(
        "created_at < ? and created_at > ?", date, @dates[index + 1]
        ).count) if index < @days
      end
      @week_new_listings_counts << new_listings_count

      expired_listings_count = []
      @dates.each_with_index do |date, index|
        expired_listings_count.push(li.where("status > 0").where(
        "updated_at < ? and updated_at > ?", date, @dates[index + 1]
        ).count) if index < @days
      end
      @week_expired_listings_counts << expired_listings_count

      sum_listings_count = []
      start_sum_count = li.where(status: 0).where("created_at < ?", end_time).count
      sum_listings_count.push(start_sum_count)
      @dates.each_with_index do |date, index|
        if index < @days - 1
          start_sum_count = start_sum_count - @week_new_listings_counts[i][index] + @week_expired_listings_counts[i][index]
          sum_listings_count.push(start_sum_count)
        end
      end
      @sum_listings_counts << sum_listings_count

    end

  end
end
