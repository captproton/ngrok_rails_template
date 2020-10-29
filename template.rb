require "fileutils"
require "shellwords"


# Supporting Methods
# Copied from: https://github.com/mattbrictson/rails-template
# Add this template directory to source_paths so that Thor actions like
# copy_file and template resolve against our source files. If this file was
# invoked remotely via HTTP, that means the files are not present locally.
# In that case, use `git clone` to download them to a local temporary dir.
def add_template_repository_to_source_path
  if __FILE__ =~ %r{\Ahttps?://}
    require "tmpdir"
    source_paths.unshift(tempdir = Dir.mktmpdir("ngrok_rails_template-"))
    at_exit { FileUtils.remove_entry(tempdir) }
    git clone: [
      "--quiet",
      "https://github.com/captproton/ngrok_rails_template.git",
      tempdir
    ].map(&:shellescape).join(" ")

    if (branch = __FILE__[%r{ngrok_rails_template/(.+)/template.rb}, 1])
      Dir.chdir(tempdir) { git checkout: branch }
    end
  else
    source_paths.unshift(File.dirname(__FILE__))
  end
end

def request_and_keep_subdomain
  r6 = generate_six_digit_rand
  @subdomain ||=
    ask_with_default("Ngrok subdomain name (only numbers or letters)?", :blue, "subdomain#{r6}")
end

def request_and_keep_app_port
  @app_port ||=
  ask_with_default("Localhost port for Rails app?", :blue, "5000")
end

def set_name_instance_vars
  @app_subdomain      = @subdomain
  @app_tunnel_name    = "#{@app_subdomain}rails"

  @asset_subdomain    = "#{@subdomain}"  
  @asset_tunnel_name  = "#{@asset_subdomain}webpack"
  @asset_tunnel_uri   = "#{@asset_subdomain}.ngrok.io"
  @ngrok_dashboard    = "http://127.0.0.1:4040/"
end
def add_env_vars
    run "touch .env"
    app_port = @app_port || '5000'
    # env_vars
    env_vars_array = [" ", "APP_TUNNEL=#{@app_tunnel_name}", "APP_PORT=#{@app_port}", "ASSETS_TUNNEL=#{@asset_tunnel_name}", "ASSET_TUNNEL_URI=#{@asset_tunnel_uri} ", " "
                ]
    env_vars = env_vars_array.join("\n")
    # append $ASSETS_TUNNEL, and $APP_TUNNEL and $APP_PORT
    append_to_file '.env', env_vars


end

def add_gems_to_gemfile
      # add rack-cors dotenv-rails
    gems_array  = [" ",
                  "gem 'rack-cors', '~> 1.1', '>= 1.1.1' #ngrok testing", 
                  "gem 'dotenv-rails', '~> 2.7', '>= 2.7.6', groups: [:development, :test] #ngrok testing",
                  " "
                  ]
    gems        = gems_array.join("\n")
    # append $ASSETS_TUNNEL, and $APP_TUNNEL and $APP_PORT
    append_to_file 'Gemfile'

end

def add_rack_cors_initializer
  remove_file "config/initializers/cors.rb"
  copy_file   "config/initializers/cors.rb"                
end

def replace_files
    remove_file "Procfile.dev"
    copy_file   "Procfile.dev"
end

def insert_host_config_regex
  comment_and_config = ["\n", '  # Allow all ngrok hosts access', 
                        '  config.hosts << /[a-z0-9]+\.ngrok\.io/',
                         "\n"]
                        .join("\n")
  insert_into_file "config/environments/development.rb",
    comment_and_config,
    after: "Rails.application.configure do"


end

def add_dotenv_with_yarn
    # ensuring that yarn is up-to-date before adding
    run "yarn install --check-files"
    run "yarn add dotenv"
end

def add_ngrok_tunnel_config
    # example configuration:
    #
    #   gocarlgo-rails:
    #     addr: 3330
    #     proto: http
    #     bind_tls: true
    #     subdomain: gocarlgo2
    #   gocarlgo-webpack:
    #     addr: 3035
    #     proto: http
    #     bind_tls: true
    #     subdomain: gocarlgo2go
    #     host-header: localhost:3035    
    run "touch ~/.ngrok2/ngrok.yml"

    rails_tunnel_name       = "#{@app_tunnel_name}"
    rails_tunnel_addr       = "#{@app_port}"
    rails_subdomain         = "#{@app_subdomain}"
    webpack_tunnel_name     = "#{@asset_tunnel_name}"
    webpack_subdomain       = "#{@asset_subdomain}"

    rails_config =      "  #{rails_tunnel_name}\:" + "\n" + 
                        "    addr\: #{rails_tunnel_addr}" + "\n" +
                        '    proto: http' + "\n" +
                        '    bind_tls: true' + "\n" +
                        "    subdomain\: #{rails_subdomain}" + "\n"

    webpack_config =    "  #{webpack_tunnel_name}\:" + "\n" + 
                        "    addr\: 3035" + "\n" +
                        '    proto: http' + "\n" +
                        '    bind_tls: true' + "\n" +
                        "    subdomain\: #{webpack_subdomain}" + "\n"
    
    append_to_file '~/.ngrok2/ngrok.yml', rails_config
    append_to_file '~/.ngrok2/ngrok.yml', webpack_config

end

def ask_with_default(question, color, default)
  # this method is copied and pasted.  We probably could refactor the color symbol.
  return default unless $stdin.tty?
  question = (question.split("?") << " [#{default}]?").join
  answer = ask(question, color)
  answer.to_s.strip.empty? ? default : answer
end

def generate_six_digit_rand
  (rand(10 ** 10).to_s.rjust(10,'0').to_i * 0.0001).to_i
end

# Main setup
# 4 files to change
# * Procfile.dev
# * config/initializers/cors.rb
# * .env
# * ~/.ngrok2/ngrok.yml

# add dotenv
add_template_repository_to_source_path

request_and_keep_subdomain
request_and_keep_app_port
set_name_instance_vars


say "** setting enviromental vars!"
add_env_vars
say "** adding gems for CORS and dotenv vars"
add_gems_to_gemfile
say "** adding initializer for CORS settings (you may want to adjust)"
add_rack_cors_initializer
say "** adding tunnels to ngrok"
add_ngrok_tunnel_config
say "** updating Procfile.dev and webpack config, including CORS for ngrok"
replace_files
say "** updating webpack dev settings for ngrok"
insert_host_config_regex
## Grand Finale
say "Your new ngrok web address is #{@subdomain}.ngrok.io"
say "Your new ngrok webpack address is #{@asset_tunnel_uri}"
say "Your ngrok dashboard is at #{@ngrok_dashboard}"
say "#####"
say "REMEMBER to `bundle install` your new gems. "
say "Thanks, come again!"