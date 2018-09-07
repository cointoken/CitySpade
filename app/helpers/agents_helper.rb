module AgentsHelper
  def short_remark(agent, len = 450, more = true)
    return if agent.remark.blank?
    if agent.remark.size <= len + 20
      content_tag :p do
        agent.remark
      end
    else
      content_tag(:div, class: 'short-remark'){
        content_tag(:p,truncate(strip_tags(agent.remark), length: len, separator: ' ') +
                    link_to(' more>>', 'javascript:void(0);', class: 'more-or-less',
                            data: {show: '.long-remark', hide: '.short-remark'} ))
      } + content_tag(:div, class: 'long-remark'){
        content_tag(:p){raw(strip_tags(agent.remark)) + link_to(' <<less', 'javascript:void(0);', class: 'more-or-less',
                                                                data: {show: '.short-remark', hide: '.long-remark'} )}
      }
      #   (truncate(strip_tags(agent.remark), length: len, separator: ' ')) + (link_to(' more>>', agent, class: 'light') +
      #    content_tag(:div, class: "long-remark"){ content_tag(:p, strip_tags(agent.remark))})

    end
  end
end
