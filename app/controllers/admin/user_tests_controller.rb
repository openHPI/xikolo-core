# frozen_string_literal: true

class Admin::UserTestsController < Abstract::FrontendController
  before_action do
    raise AbstractController::ActionNotFound unless Xikolo.config.beta_features['show_user_tests']
  end

  def index
    authorize! 'grouping.user_test.index'

    @user_tests = Xikolo.api(:grouping).value!.rel(:user_tests).get.value!.map do |user_test|
      UserTestPresenter.create user_test
    end
  end

  def show
    authorize! 'grouping.user_test.export'

    user_test = Xikolo.api(:grouping).value!.rel(:user_test).get(
      id: params[:id],
      statistics: true,
      export: params[:format] == 'csv'
    ).value!

    respond_to do |format|
      format.html { @user_test = UserTestPresenter.create(user_test, get_dependent: true) }
      format.csv { render plain: user_test['csv'] }
    end
  end

  def new
    authorize! 'grouping.user_test.manage'

    @form = Admin::UserTestForm.new(
      'test_groups' => [
        {'name' => 'Control', 'description' => '', 'flippers' => []},
        {'name' => 'Alternative', 'description' => '', 'flippers' => []},
      ]
    )
  end

  def edit
    authorize! 'grouping.user_test.manage'

    @form = Admin::UserTestForm.from_resource(
      user_test.merge({
        'test_groups' => user_test.rel(:test_groups).get,
        'metrics' => user_test.rel(:metrics).get,
        'filters' => user_test.rel(:filters).get,
      }.transform_values(&:value!))
    )
  end

  def create
    authorize! 'grouping.user_test.manage'

    @form = Admin::UserTestForm.from_params params

    if (user_test = @form.save)
      add_flash_message :success, t(:'flash.success.user_test_created')
      redirect_to user_test_path(id: user_test['id'])
    else
      add_flash_message :error, t(:'flash.error.user_test_not_created')
      render action: :new
    end
  end

  def update
    authorize! 'grouping.user_test.manage'

    @form = Admin::UserTestForm.from_params params
    @form.id = user_test['id']
    @form.persisted!

    if @form.save
      add_flash_message :success, t(:'flash.success.user_test_updated')
      redirect_to user_test_path(id: user_test['id'])
    else
      add_flash_message :error, t(:'flash.error.user_test_not_updated')
      render action: :edit
    end
  end

  def destroy
    authorize! 'grouping.user_test.manage'

    Xikolo.api(:grouping).value!.rel(:user_test).delete(id: params[:id]).value!
    add_flash_message :success, t(:'flash.success.user_test_deleted')
    redirect_to user_tests_path
  rescue Restify::ClientError
    add_flash_message :error, t(:'flash.error.user_test_not_deleted')
    redirect_to user_tests_path
  end

  private

  def user_test
    @user_test ||= Xikolo.api(:grouping).value!
      .rel(:user_test).get(id: params[:id]).value!
  end
end
