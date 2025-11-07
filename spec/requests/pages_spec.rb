require 'rails_helper'

RSpec.describe 'Pages', type: :request do
  it 'GET / (home) returns success' do
    get '/'
    expect(response).to have_http_status(:ok)
  end

  it 'GET /association returns success' do
    get '/association'
    expect(response).to have_http_status(:ok)
  end
end

