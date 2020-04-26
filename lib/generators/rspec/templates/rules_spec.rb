# frozen_string_literal: true

require '<%= File.exists?('spec/rails_helper.rb') ? 'rails_helper' : 'spec_helper' %>'

RSpec.describe <%= class_name %><%= Bali.config.suffix %> do

end
