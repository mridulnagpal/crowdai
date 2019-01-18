ActiveAdmin.register Challenge do
  #config.filters = false

  sidebar "Challenge Configuration", only: [:show, :edit] do
    ul do
      li link_to "Dataset Files", admin_challenge_dataset_files_path(challenge)
      li link_to "Submission File Definition", admin_challenge_submission_file_definitions_path(challenge)
    end
  end

  sidebar "Challenge Details", only: [:show, :edit] do
    ul do
      li link_to "Leaderboard",   admin_challenge_leaderboards_path(challenge)
      li link_to "Submissions",   admin_challenge_submissions_path(challenge)
      li link_to "Topics", admin_challenge_topics_path(challenge)
    end
  end

  filter :id
  filter :status_cd
  filter :challenge

  index do
    selectable_column
    column :id
    column :challenge
    column :status
    column :page_views
    column :participant_count
    column :submission_count
    actions
  end

  controller do
    actions :all, except: [:edit,:new]
    def find_resource
      scoped_collection.friendly.find(params[:id])
    end
    def permitted_params
      params.permit!
    end
  end

  member_action :purge, method: :delete do
    submissions = Submission.where(challenge_id: params[:id])
    submissions_count = submissions.count
    submissions.destroy_all
    redirect_to admin_challenge_path(params[:id]), flash: { notice: "#{submissions_count} submissions have been deleted." }
  end

  member_action :download_challenge, method: :get do
    challenge = Challenge.find(params[:id])
    json = challenge.as_json

    submissions = challenge.submissions.as_json
    submissions.each do |sub|
      sub['participant_email_sha'] = Digest::MD5.hexdigest(Participant.find(sub['participant_id']).email)
      delete_keys = ["participant_id", "participant"]
      delete_keys.each do |delete_key|
        sub.delete(delete_key)
      end
    end

    json['submissions'] = submissions

    leaderboards = challenge.leaderboards.as_json
    leaderboards.each do |lead|
      lead['participant_email_sha'] = Digest::MD5.hexdigest(Participant.find(lead['participant_id']).email)
      delete_keys = ["participant_id", "participant"]
      delete_keys.each do |delete_key|
        lead.delete(delete_key)
      end
    end

    json['leaderboards'] = leaderboards

    json['dataset_files'] = challenge.dataset_files.as_json
    json['submission_file_definitions'] = challenge.submission_file_definitions.as_json
    json['topics'] = challenge.topics.as_json

    json['organizer'] = Organizer.find(json['organizer_id']).as_json

    hashes = [json]

    column_names = hashes.first.keys
    csv = CSV.generate do |csv|
      csv << column_names
      hashes.each do |x|
        csv << x.values
      end
    end
    send_data csv.encode('Windows-1251'), type: 'text/csv; charset=windows-1251; header=present', disposition: "attachment; filename=challenge_export.csv"
  end

  action_item :delete_submissions, only: :show  do
    link_to 'Delete all submissions', purge_admin_challenge_path(resource.id), method: :delete, data: { confirm: "You are about to delete all submissions for #{resource.challenge} challenge. Are you sure?" }
  end

  action_item :export_csv, only: :show do
    link_to "Download Challenge", download_challenge_admin_challenge_path(resource.id), method: :get
  end

end
