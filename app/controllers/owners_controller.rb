class OwnersController < ApplicationController
  def new
    @owner = Owner.new
  end

  def create
    @owner = Owner.new(owner_params)
    respond_to do |format|
      if @owner.save
        OwnerWorker.perform_async(@owner.id)
        format.html
      else
        format.html { render action: "new" }
      end
    end
  end

  private
  def owner_params
    params.require(:owner).permit(:name, :street_address, :city, :zipcode,
                                 :email, :phone)
  end
end
