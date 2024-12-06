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
        proctoring_image!
        transcript_of_records!
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

      def proctoring_image!
        return if @data.proctoring_image.blank?

        @pdf.image(
          @data.proctoring_image,
          at: [16.1, 754],
          width: 77.2
        )
      end

      def transcript_of_records!
        return if @data.transcript_of_records.blank?

        tor = @data.transcript_of_records
        config = Xikolo.config.certificate['transcript_of_records']

        @pdf.move_cursor_to(config['table_y'])
        @pdf.table(
          tor,
          position: config['table_x'],
          column_widths: [config['course_col_width'], config['score_col_width']],
          cell_style: {font: fonts.keys.first, size: config['font_size']}
        ) do
          # Reset all cell border
          cells.borders = []

          # Add vertical line between rows
          row(0..tor.length - 2).borders = [:bottom]

          # Thicker line after first and before last row
          row(0).border_width = 2
          row(tor.length - 2).border_width = 2

          columns(1).align = :right
        end
      end

      def fonts
        # fallback to default Open Sans if there are no brand-specific fonts
        return default_fonts unless Xikolo.config.certificate&.dig('fonts')

        Xikolo.config.certificate['fonts'].transform_values do |file|
          Rails.root.join('brand', Xikolo.brand, 'assets', 'fonts', file).to_s
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
