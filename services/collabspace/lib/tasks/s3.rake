# frozen_string_literal: true

namespace :xikolo do
  desc <<-DESC.gsub(/\s+/, ' ')
    Migrate collab space files to S3
  DESC
  task migrate_collabspace_files: :environment do
    $stdout.sync = true

    # Tell the frontend to start uploading to S3
    Xikolo.api(:account).value!
      .rel(:group).get({id: 'all'}).value!
      .rel(:features).patch({collabspace_files_s3: true}).value!

    file_root = Xikolo.api(:file).value!
    bucket = Xikolo::S3.bucket_for(:collabspace)

    i = 0
    Xikolo.paginate file_root.rel(:uploaded_files).get do |upload, page|
      i += 1
      next if upload['collab_space_id'].blank?

      space = CollabSpace.find_by id: upload['collab_space_id']
      next unless space
      next if space.files.exists?(id: upload['id'])

      # Generate IDs
      cid = UUID4(space.id).to_s(format: :base62)
      fid = UUID4(upload['id']).to_s(format: :base62)
      vid = UUID4.new.to_s(format: :base62)

      # Show progress
      total = page.response.headers['X_TOTAL_COUNT'].to_i
      $stdout.print "\rFile #{i.to_s.rjust(3)}/#{total} ..."

      # Download file content
      contents = upload.rel(:file).get.value!

      # Upload to S3
      object = bucket.put_object(
        key: "collabspaces/#{cid}/files/#{fid}/#{vid}/#{upload['name']}",
        body: contents.response.body,
        acl: 'private',
        content_type: upload['mime_type'],
        content_disposition: "attachment; filename=\"#{upload['name']}\""
      )

      # Persist in database
      file = space.files.create!(
        id: upload['id'],
        creator_id: upload['user_id']
      )

      file.versions.create!(
        id: UUID4(vid).to_s,
        original_filename: upload['name'],
        size: upload['size'],
        blob_uri: object.storage_uri
      )
    rescue Errno::ENOENT => e
      $stdout.puts " ==> removed: #{e}"
    rescue => e
      $stdout.puts " ==> other error: #{e}"
    end

    puts
    puts 'finished'
  end
end
