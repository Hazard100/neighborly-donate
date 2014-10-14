# coding: utf-8
class ProjectsController < ApplicationController
  after_filter :verify_authorized, except: [:index, :video, :video_embed, :embed,
                                            :embed_panel, :comments, :budget,
                                            :reward_contact, :send_reward_email,
                                            :start]

  respond_to :html

  def new
    @project = Project.new(user: current_user)
    authorize @project
  end

  def index
    projects_vars = {
      #coming_soon: :soon,
      #ending_soon: :expiring,
      featured:    :featured,
      recommended: :recommends,
      successful:  :successful
    }

    projects_vars.each do |var_name, scope|
      instance_variable_set "@#{var_name}", ProjectsForHome.send(scope)
    end

    @successful = @successful.take(2) if browser.mobile?
    @channels = Channel.with_state('online').order('RANDOM()').limit(4)
    @press_assets = PressAsset.order('created_at DESC').limit(5)

    investment_section_variables
  end

  def create
    @project = Project.new(permitted_params[:project].merge(user: current_user))
    authorize @project
    @project.save
    respond_with @project, location: success_project_path(@project)
  end

  def success
    authorize resource
  end

  def edit
    authorize resource
    respond_with resource
  end

  def update
    authorize resource
    respond_with Project.update(resource.id, permitted_params[:project]),
      location: edit_project_path(@project)
  end

  def show
    authorize resource
    set_facebook_url_admin(resource.user)
    render :about if request.xhr?
  end

  def comments
    @project = resource
  end

  def reports
    authorize resource
  end

  def budget
    @project = resource
  end

  %w(embed video_embed).each do |method_name|
    define_method method_name do
      @title = resource.name
      render layout: 'embed'
    end
  end

  def embed_panel
    @project = resource
    render layout: !request.xhr?
  end

  def start
    @projects = ProjectsForHome.successful[0..3]
    @channel  = channel.decorate if channel
  end

  private

  def permitted_params
    params.permit(policy(@project || Project).permitted_attributes)
  end

  def resource
    @project ||= Project.find_by_permalink!(params[:id])
  end

  def permitted_params
    params.permit(policy(@project || Project).permitted_attributes)
  end

  def investment_section_variables
    @user = current_user || User.new
    @user.build_investment_prospect unless @user.investment_prospect

    @invest_from_otions = if current_user
                            { url: user_path(current_user, investment_prospect: true), method: :put }
                           else
                             { url: sign_up_path }
                           end
    statistic = Neighborly::Admin::Statistics.all.to_a.first
    @total_investors = statistic.total_users
    @total_pledged_for_investment = statistic.total_contributed.to_f +
      InvestmentProspect.sum(:value)

    user_limit = browser.mobile? ? 6 : 18
    @users = User.where('uploaded_image IS NOT NULL').with_profile_type('personal').order("RANDOM()").limit(user_limit)
  end
end
