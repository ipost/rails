# frozen_string_literal: true

module Rails::Command::CredentialsCommand::Merging # :nodoc:
  GITATTRIBUTES_ENTRY = <<~END
    config/credentials/*.yml.enc merge=rails_credentials
    config/credentials.yml.enc merge=rails_credentials
  END

  def enroll_project_in_credentials_merging
    if enrolled_in_credentials_merging?
      say "Project is already enrolled in credentials file merging."
    else
      gitattributes.write(GITATTRIBUTES_ENTRY, mode: "a")
      configure_merging_driver

      say "Enrolled project in credentials file merging!"
      say "Rails ensures the rails_credentials diff driver is set when running `credentials:edit`. See `credentials:help` for more."
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

    def merging_driver_configured?
      system "git config --get diff.rails_credentials.textconv", out: File::NULL
    end

    def configure_merging_driver
      system <<~COMMAND
        git config merge.rails_credentials.driver \
          'bin/rails credentials:merge %A %O %B %P'
      COMMAND
    end

    def remove_merging_driver
      system <<~COMMAND
        git config --unset merge.rails_credentials.driver
      COMMAND
    end

    def gitattributes
      Rails.root.join(".gitattributes")
    end
end
