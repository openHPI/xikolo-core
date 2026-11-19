# frozen_string_literal: true

require 'prawn'
require 'prawn/qrcode'

module Certificate
  class RecordRenderer
    def self.as_pdf(data)
      RecordPdf.new(data).render
    end

    class RecordPdf
      def initialize(data)
        @data = data
        @pdf = Prawn::Document.new(
          template: @data.template_path,
          page_size: 'A4',
          page_layout: :landscape,
          left_margin: 0,
          right_margin: 0,
          top_margin: 0,
          bottom_margin: 0
        )

        update_fonts!
        qrcode!
        dynamic_content!
      end

      def render
        @pdf.render
      end

      private

      def update_fonts!
        fonts.each do |name, file|
          next unless File.exist?(file) # Skip font it is not included in the assets.

          io = File.open(file, 'rb')
          # Specifying a font family name is required to use the same name from the config (without
          # appending `-Regular`).
          # We cannot use subsetting for now, see https://github.com/prawnpdf/prawn/issues/1361
          font = Prawn::Font.load(@pdf, io, subset: false, family: name)
          # Set identifier to avoid conflicts with other fonts. See https://github.com/prawnpdf/prawn/issues/1362#issuecomment-2359409580
          font.instance_variable_set(:@identifier, "#{name}-Xikolo")
          @pdf.font_families.update(name => {normal: font})
        end
        # Explicitly set the fallback font to the first font in the list.
        # Otherwise, Prawn's default would be `Helvetica`.
        @pdf.fallback_fonts = [fonts.keys.first]
      end

      def qrcode!
        return unless @data.qrcode_pos

        y = @data.qrcode_pos[:y] - @pdf.bounds.height
        @pdf.print_qr_code(
          @data.qrcode_url,
          pos: [@data.qrcode_pos[:x], y.abs],
          dot: 1.25,
          stroke: true
        )
      end

      def dynamic_content!
        return if @data.dynamic_content.blank?

        @pdf.svg(
          @data.dynamic_content,
          at: [0, @pdf.bounds.height],
          width: @pdf.bounds.width,
          # Rather than `Times-Roman` as a default in `prawn-svg`, we use the first font in the list.
          fallback_font_name: fonts.keys.first
        )
      end

      def fonts
        # fallback to default Open Sans if there are no brand-specific fonts
        return default_fonts unless Xikolo.config.certificate&.dig('fonts')

        Xikolo.config.certificate['fonts'].transform_values do |file|
          Rails.root.join('app', 'assets', 'fonts', file).to_s
        end
      end

      def default_fonts
        {
          OpenSansRegular: Rails.root.join('app', 'assets', 'fonts', 'OpenSans-Regular.ttf').to_s,
          OpenSansSemibold: Rails.root.join('app', 'assets', 'fonts', 'OpenSans-Semibold.ttf').to_s,
        }.stringify_keys
      end
    end
  end
end
