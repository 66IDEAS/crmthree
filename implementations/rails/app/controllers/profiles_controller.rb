# frozen_string_literal: true

class ProfilesController < ApplicationController
  def show
    @profile = params[:id].present? ? UserProfile.find(params[:id]) : current_profile
    authorize @profile
    @portfolio = Crm::PerformancePortfolio.for(@profile)
    @manager = TimelinePolicy.new(pundit_user, :timeline).team?
  end

  def update
    authorize current_profile
    result = Crm::DataSourceRouter.for(object_type: "UserProfile", identity: pundit_user)
    result = result.value.update(current_profile.id, profile_params) if result.success?

    if result.success?
      redirect_to profile_path, notice: "Profile preferences saved."
    else
      flash.now[:alert] = result.errors.to_sentence.presence || "Profile preferences could not be saved."
      @profile = current_profile
      @portfolio = Crm::PerformancePortfolio.for(@profile)
      @manager = TimelinePolicy.new(pundit_user, :timeline).team?
      render :show, status: result.status
    end
  end

  private

  def profile_params
    params.require(:user_profile).permit(:theme_preference, :language_preference)
  end
end
