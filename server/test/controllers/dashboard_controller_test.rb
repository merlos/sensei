require "test_helper"
require "minitest/mock"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    Sensor.create!(code: "temp_kitchen", name: "Temperature Kitchen", units: "C", value_type: "float")
    @auth = { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials("sensei", "secret") }
  end

  def with_dashboard_credentials(&block)
    credentials = Rails.application.credentials
    credentials.stub(:dig, ->(*keys) { keys.last == :dashboard_username ? nil : "secret" }, &block)
  end

  test "update sensor group, then render dashboard pages" do
    with_dashboard_credentials do
      patch "/dashboard/sensor/temp_kitchen/update",
        params: { field: "group_name", group_name: " Kitchen " }.to_json,
        headers: @auth.merge("Content-Type" => "application/json")
      assert_response :success
      assert_equal "Kitchen", JSON.parse(response.body)["value"]
      assert_equal "Kitchen", Sensor.find_by!(code: "temp_kitchen").group_name

      get "/dashboard", headers: @auth
      assert_response :success
      assert_includes response.body, 'data-inline-edit-field-value="group_name"'
      assert_includes response.body, 'value="Kitchen"'

      get "/dashboard/sensor/temp_kitchen", headers: @auth
      assert_response :success
      assert_includes response.body, 'value="Kitchen"'
    end
  end

  test "clearing the group sets it to nil" do
    Sensor.find_by!(code: "temp_kitchen").update!(group_name: "Kitchen")
    with_dashboard_credentials do
      patch "/dashboard/sensor/temp_kitchen/update",
        params: { field: "group_name", group_name: "" }.to_json,
        headers: @auth.merge("Content-Type" => "application/json")
      assert_response :success
    end
    assert_nil Sensor.find_by!(code: "temp_kitchen").group_name
  end
end
