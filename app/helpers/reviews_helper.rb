module ReviewsHelper
  def display_review_title(review)
    review.title
  end

  def display_review_only_address(review)
    review.real_address
  end

  def display_review_neighborhood(review)
    review.political_area.try(:short_name)
  end

  def short_comment(review, len = 300, more = true)
    (truncate(strip_tags(review.comment), length: len, separator: ' ') || '') + (more ? link_to(' more>>', review, class: 'light') : '')
  end

  def time_ago_display(time, str = 'Reviewed')
    tmp = Time.now - time
    result =  ""
    [:day, :hour, :minute, :second].each do |tm|
      s = (tmp / 1.send(tm)).to_i
      if s > 0
        tm = "#{tm}s" if s > 1
        result = "#{str} #{s} #{tm} ago"
        break
      end
    end
    result
  end

  def render_required_label(*arg)
    val = arg.delete_at(-1)
    opt = {}
    if val.is_a?(Hash)
      opt = val
      val = arg.delete_at(-1)
    end
    label_tag arg.first, opt do
      content_tag(:span, '*', class: 'star') + \
        content_tag(:span, val)
    end
  end

  def render_rating_stars(form_object,obj = nil, is_tmpl_flag = false)
    obj ||= @review
    unless is_tmpl_flag
      obj.rating_stars.map do |rate|
        rate_i = obj.send rate
        content_tag :div, class: 'input select-circle-container' do
          content_tag(:label, rate.split('_').map(&:capitalize).join(' ') + ':') + content_tag(:div, class: 'select-items') do
            (0..4).map do |i|
              content_tag :i, nil, class: "fa fa-star #{rate_i ? (rate_i > i ? 'selected' : nil) : nil}", data:{index: i, name: rate}
            end.join.html_safe + form_object.hidden_field(rate)
          end
        end
      end.join
    else
      "{%if review_type == 0 %}" + begin
                                     obj.review_type = 0
                                     obj.rating_stars.map do |rate|
                                       rate_i = obj.send rate
                                       content_tag :div, class: 'input select-circle-container' do
                                         content_tag(:label, rate.split('_').map(&:capitalize).join(' ') + ':') + content_tag(:div, class: 'select-items') do
                                           (0..4).map do |i|
                                             content_tag :i, nil, class: "fa fa-star #{rate_i ? (rate_i > i ? 'selected' : nil) : nil}", data:{index: i, name: rate}
                                           end.join.html_safe + form_object.hidden_field(rate)
                                         end
                                       end
                                     end.join
      end +
      "{%else%}" + begin
                     obj.review_type = 1
                     obj.rating_stars.map do |rate|
                       rate_i = obj.send rate
                       content_tag :div, class: 'input select-circle-container' do
                         content_tag(:label, rate.split('_').map(&:capitalize).join(' ') + ':') + content_tag(:div, class: 'select-items') do
                           (0..4).map do |i|
                             content_tag :i, nil, class: "fa fa-star #{rate_i ? (rate_i > i ? 'selected' : nil) : nil}", data:{index: i, name: rate}
                           end.join.html_safe + form_object.hidden_field(rate)
                         end
                       end
                     end.join
      end + '{%/if%}'
    end
  end

  def safe_html_with_strong comment
    strip_comment = strip_tags comment
    comment.gsub(/\<b\>.*\<\/b\>/){|s| strip_comment = strip_comment.gsub(s[3..-5], s) }
    strip_comment
  end

  # def render_average_overall_quality(venue)
  #   if venue.overall_quality && venue.overall_quality > 0
  #     rating = venue.round_rating(:overall_quality)
  #     content_tag :div, class: 'rating-result', itemscope: true, itemtype: "http://data-vocabulary.org/Review-aggregate" do
  #       content_tag :div, class: 'rating-all-items' do
  #         5.times.map{|i|
  #           content_tag :i,nil ,class: "fa fa-square-star-big #{i < rating ? 'selected' : nil} #{rating - i == 0.5 ? "half" : nil }"
  #         }.join.html_safe
  #       end.concat(
  #       content_tag(:div, class: 'rating-score'){
  #         content_tag(:span, venue.overall_quality, itemprop: 'average').concat('/').concat(
  #           content_tag(:span, 5, itemprop:'best')
  #         )
  #       }).concat(content_tag(:span, venue.reviews.size, itemprop: 'count', class: 'hide'))
  #     end
  #   end
  # end

  def toggle_review_comment(review, len = 500)
    if review.comment.length <= len
      content_tag :p, class: 'description', itemprop: 'description'  do
        review.comment
      end
    else
      content_tag(:div, class: 'short-comment', id: "short-comment-#{review.id}"){
        content_tag(:p, class: 'summary', itemprop: 'summary'){truncate(strip_tags(review.comment), length: 500, separator: ' ') +
                                                               link_to(' more>>', 'javascript:void(0);', class: 'more-or-less',
                                                                       data: {show: "#long-comment-#{review.id}", hide: "#short-comment-#{review.id}"} )}
      } + content_tag(:div, class: 'long-comment', id: "long-comment-#{review.id}"){
        content_tag(:p, class: 'description', itemprop: 'description'){raw(strip_tags(review.comment)) +
                                                                       link_to(' <<less', 'javascript:void(0);',
                                                                               class: 'more-or-less',
                                                                               data: {show: "#short-comment-#{review.id}", hide:"#long-comment-#{review.id}"}) +
                                                                       render("grocery_and_laundry_comments", review: review)}}
    end
  end

  def review_comment_photos(review, index)
    if review.images.present?
       content_tag(:ul, class: "review-comment-imgs") {
        review.images[0..1].map do |img|
          content_tag(:li) {
            link_to "#{img.url}", class: "fancybox", rel: "review-comment-gallery-#{index + 1}" do
              image_tag(img.url, class: "review-comment-img")
            end
          }
        end.inject(&:+)
      }
    end
  end

 
end
