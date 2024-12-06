# frozen_string_literal: true

module AssetHelper
  def asset_path(file)
    File.expand_path(File.join('../../assets', file), __FILE__)
  end
end

Gurke.world.include AssetHelper
