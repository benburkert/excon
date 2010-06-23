require 'sinatra'

class BasicApp < Sinatra::Base
  get '/' do
    ''
  end
end

class WaitApp < Sinatra::Base
  get '/id/:id/wait/:wait' do |id, wait|
    sleep wait.to_i
    id.to_s
  end

end

map '/wait' do
  run WaitApp
end

map '/' do
  run BasicApp
end
