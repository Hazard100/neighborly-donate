require 'spec_helper'

describe AuthorizationObserver do
  let(:authorization) { create(:authorization, user: create(:user, facebook_url: 'http://facebook.com/neighborly')) }

  it 'should set facebook_url to nil' do
    user = authorization.user
    expect(user.facebook_url).to eq 'http://facebook.com/neighborly'
    authorization.destroy
    user.reload
    expect(user.facebook_url).to be_nil
  end

  describe '#after_commit' do
    it 'calls Webhook::EventRegister' do
      expect(Webhook::EventRegister).to receive(:new).with(authorization, created: true)
      authorization.run_callbacks(:commit)
    end
  end
end
