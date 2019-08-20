require 'etc'

module CapGun
  class Notifer

    attr_accessor :capistrano

    def initialize(capistrano)
      self.capistrano = capistrano
    end

    def current_user
      Etc.getlogin
    end

    def deployed_to
      "deployed%r".sub('%r') {
        if capistrano[:stage]
          " to #{capistrano[:stage]}"
        elsif capistrano[:rails_env]
          " to #{capistrano[:rails_env]}"
        else
          ""
        end
      }
    end

    def summary
      %[#{capistrano[:application]} was #{deployed_to} by #{current_user} at #{release_time}.]
    end

    def local_datetime_zone_offset
      @local_datetime_zone_offset ||= DateTime.now.offset
    end

    def local_timezone
      @current_timezone ||= Time.now.zone
    end

    def release_time
      humanize_release_time(capistrano[:current_release])
    end

    def previous_revision
      capistrano.fetch(:previous_revision, "n/a")
    end

    def previous_release_time
      humanize_release_time(capistrano[:previous_release])
    end

    def subject
      "#{email_prefix} #{capistrano[:application]} #{deployed_to}"
    end

    def comment
      "Comment: #{capistrano[:comment]}.\n" if capistrano[:comment]
    end

  end
end

json = {
    status: "#{capistrano[:current_release]}",
    application: "#{capistrano[:application]}",
    deployer: "#{current_user}",
    revision: "#{capistrano[:current_revision]}",
    environment: "#{capistrano[:deploy_to]}",
    branch: "#{capistrano[:branch]}",
}.to_json

system("aws lambda invoke --function arn:aws:lambda:us-east-1:198454647815:function:deploy-notifier-DeployNotifier-14F6DEAH0NMBI --payload #{json} /dev/null")
