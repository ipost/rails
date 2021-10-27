# frozen_string_literal: true

module Rails::Command::CredentialsCommand::Merging # :nodoc:
  DRIVER_NAME = 'rails_credentials'

  GITATTRIBUTES_ENTRY = <<~END
    config/credentials/*.yml.enc merge=#{DRIVER_NAME}
    config/credentials.yml.enc merge=#{DRIVER_NAME}
  END

  def enroll_project_in_credentials_merging
    if enrolled_in_credentials_merging?
      say "Project is already enrolled in credentials file merging."
    else
      gitattributes.write(GITATTRIBUTES_ENTRY, mode: "a")
      configure_merging_driver

      say "Enrolled project in credentials file merging!"
    end
  end

  def disenroll_project_from_credentials_merging
    if enrolled_in_credentials_merging?
      gitattributes.write(gitattributes.read.gsub(GITATTRIBUTES_ENTRY, ""))
      gitattributes.delete if gitattributes.empty?
      remove_merging_driver

      say "Disenrolled project from credentials file merging!"
    else
      say "Project is not enrolled in credentials file merging."
    end
  end

  private
    def enrolled_in_credentials_merging?
      gitattributes.file? && gitattributes.read.include?(GITATTRIBUTES_ENTRY)
    end

    def configure_merging_driver
      system <<~COMMAND
        git config merge.#{DRIVER_NAME}.driver 'bin/rails credentials:merge %A %O %B %P'
      COMMAND
    end

    def remove_merging_driver
      system <<~COMMAND
        git config --unset merge.#{DRIVER_NAME}.driver
      COMMAND
    end

    def gitattributes
      Rails.root.join(".gitattributes")
    end
end
