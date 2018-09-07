class CareersController < ApplicationController

  def index
    @careers = Career.where(open: true)
    @careers = @careers.order(updated_at: :desc)
    @count = @careers.length
  end

  def show
    @career = Career.find(params[:id])
    @page_title = "#{@career.title}"
  end

  def fin_analyst
  end

  def translators
  end

  def reg_affairs
  end

  def app_restate
  end

  def cs_analyst
  end

  def budget_analyst
  end

  def business_analyst
  end

  def or_analyst
  end

  def it_proj
  end

  def market_analyst
  end

  def accountant
  end

  def fin_analyst
  end

  def data_analyst
  end

  def business_develop
  end

  def pub_relation
  end

  def manage_analyst
  end


end
