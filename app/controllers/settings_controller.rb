class SettingsController < ApplicationController

  def index
    @pager_duty_service_key = Setting.where(key: 'pager_duty_service_key').first_or_initialize 
    @alert_after_fail_count = Setting.where(key: 'alert_after_fail_count').first_or_initialize
  end

  def set_pager_duty_service_key
    set_setting params, 'pager_duty_service_key'
  end

  # How many times must a test fail before alerting?
  # Used to prevent false alarms due to temporary network issues.
  def set_alert_after_fail_count
    set_setting params, 'alert_after_fail_count'
  end

  def set_setting params, key
    info_msgs = []
    error_msgs = []

    value = params[:setting][:value] if params[:setting]

    if !value.blank?
      setting = Setting.where(key: key).first_or_initialize
      setting.value = value
      if setting.save
        info_msgs << "#{key} updated"
      end
    else
      error_msgs << "#{key} cannot be blank."
    end

    if error_msgs.size > 0
      flash[:danger] = error_msgs.join(' ')
    elsif info_msgs.size > 0
      flash[:success] = info_msgs.join(' ')
    end

    respond_to do |format|
      format.js
      format.html {redirect_to settings_path}
    end
  end

end