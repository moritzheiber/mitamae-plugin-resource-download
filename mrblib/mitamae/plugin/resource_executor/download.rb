module ::MItamae
  module Plugin
    module ResourceExecutor
      class Download < ::MItamae::ResourceExecutor::Base

        UrlInvalidError = Class.new(StandardError)
        ModeInvalidError = Class.new(StandardError)
        CheckSumMismatchError = Class.new(StandardError)

        MODE_REGEXP = /0?[0-7]{3}/

        def apply
          unless current.exists && desired.checksum == current.checksum
              download_file(desired.url, @temp_path)
              compare_checksum(desired.checksum, checksum(@temp_path)) if desired.checksum
              install_file(@temp_path, desired.destination)
          else
              MItamae.logger.info "#{desired.destination} has already been downloaded. Skipping."
          end
        end

        private

        def pre_action
          @temp_path ||= "/tmp/mitamae_download_#{::Random.srand.to_s}"
        end

        def run_action(action)
          super
          if FileTest.exists?(@temp_path)
            ::File.unlink(@temp_path)
          end
        end

        def set_current_attributes(current, action)
          dest = attributes.destination

          current.exists = FileTest.exists?(dest)
          current.checksum = checksum(dest) if current.exists
        end

        def set_desired_attributes(desired, action)
          case action
          when :fetch
            desired.exists = true
            desired.mode = validated_mode(attributes.mode) if attributes.mode
            desired.owner = attributes.owner if attributes.owner
            desired.group = attributes.group if attributes.group
            desired.checksum = attributes.checksum if attributes.checksum

            raise UrlInvalidError, 'The specified URL is invalid' unless validate_url(attributes.url)
            desired.url = attributes.url
          end
        end

        def download_file(url, dest)
          run_specinfra(:download_file, url, dest)
        end

        def compare_checksum(desired, actual)
          raise CheckSumMismatchError,
            "Checksums do not match (expected #{desired}, is #{actual})." unless desired == actual
        end

        def install_file(src, dest)
          cmd = ['install','-D']
          cmd << "-m#{desired.mode}" if desired.mode
          cmd << "-o #{desired.owner}" if desired.owner
          cmd << "-g #{desired.group}" if desired.group
          cmd.concat([src, dest])

          run_command(cmd)
        end

        def checksum(file)
          run_specinfra(:get_file_sha256sum, file).stdout.chomp
        end

        def validated_mode(mode)
          raise ModeInvalidError, 'Invalid mode line' unless mode =~ MODE_REGEXP
          mode
        end

        def validate_url(source_url)
          source_url =~ ::URI::regexp
        end
      end
    end
  end
end
