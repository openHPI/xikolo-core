# frozen_string_literal: true

module Steps
  module Files
    def download_file(url)
      page.execute_script <<~JAVASCRIPT
        window.downloadXHR = function() { return getFile('#{url}'); }
        window.getFile = function(url) {
          var xhr = new XMLHttpRequest();
          xhr.open('GET', url, false);
          xhr.send(null);
          return xhr.responseText;
        };

        return downloadXHR();
      JAVASCRIPT
    end
  end
end

Gurke.configure {|c| c.include Steps::Files }
