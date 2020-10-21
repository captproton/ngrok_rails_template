# ngrok_rails_template

add the goodness of ngrok to your Rails 6 app

#### Requirements

You'll need the following installed to run the template successfully:

- Ruby 2.5 or higher
- Redis - For ActionCable support
- bundler - `gem install bundler`
- foreman - `gem install foreman`
- rails - `gem install rails`
- Yarn - `brew install yarn` or [Install Yarn](https://yarnpkg.com/en/docs/install)
- Foreman - `gem install foreman` - helps run all your processes in development (for example, ngrok)

#### Create an ngrok subdomain

- Run as a normal template

from github:

```bash
rails app:template LOCATION=https://raw.githubusercontent.com/captproton/ngrok_rails_template/main/template.rb
```

Or if you have downloaded this repo, you can reference template.rb locally:

```bash
rails app:template LOCATION=ngrok_rails_template/template.rb
```

- Run `gem install bundler` from the root of your app

#### Start your rails app

- Run `foreman start` from the root of your app

You should see foreman start four processes

- web (rails)
- worker (sidekiq)
- webpack
- ngrok
