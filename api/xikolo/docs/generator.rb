# frozen_string_literal: true

require 'fileutils'
require 'erb'

module Xikolo
  module Docs
    class Generator
      include ERB::Util

      def initialize(directory, root)
        @target = directory
        @root = root
      end

      def generate!
        ensure_target_directory!

        generate_index!
      end

      private

      def ensure_target_directory!
        $stdout.puts "Ensuring that #{@target} directory exists"
        FileUtils.mkpath @target
      end

      def generate_index!
        endpoints = sorted_endpoints

        output = template_result 'index.html', binding
        ::File.write("#{@target}/index.html", output)
      end

      def template_result(filename, variables)
        template = ERB.new ::File.read("api/xikolo/docs/templates/#{filename}.erb")
        template.result variables
      end

      def sorted_endpoints
        @root.json_api_endpoints.sort_by {|key, _val| key }.to_h
      end
    end
  end
end
