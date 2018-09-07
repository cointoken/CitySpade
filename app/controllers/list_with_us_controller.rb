class ListWithUsController < ApplicationController
  def new
    @list_with_us = ListWithUs.new
  end

  def create
    @list_with_us = ListWithUs.new(list_with_us_params)

    respond_to do |format|
      if @list_with_us.save
        ListWithUsWorker.perform_async(@list_with_us.id)
        format.html
      else
        format.html { render action: "new" }
      end
    end
  end

  private
  def list_with_us_params
    params.require(:list_with_us).permit(:identity, :listing_type, :sydication,
    :specify, :company_website, :listing_feed_url, :email, :contact_number)
  end
end
