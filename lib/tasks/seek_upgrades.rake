# frozen_string_literal: true

require 'rubygems'
require 'rake'

namespace :seek do
  # these are the tasks required for this version upgrade
  task upgrade_version_tasks: %i[
    environment
    update_samples_json
    set_version_visibility
    remove_old_project_join_logs
  ]

  # these are the tasks that are executes for each upgrade as standard, and rarely change
  task standard_upgrade_tasks: %i[
    environment
    clear_filestore_tmp
    repopulate_auth_lookup_tables
  ]

  desc('upgrades SEEK from the last released version to the latest released version')
  task(upgrade: [:environment]) do
    puts "Starting upgrade ..."
    puts "... trimming old session data ..."
    Rake::Task['db:sessions:trim'].invoke
    puts "... migrating database ..."
    Rake::Task['db:migrate'].invoke
    Rake::Task['tmp:clear'].invoke

    solr = Seek::Config.solr_enabled
    Seek::Config.solr_enabled = false

    begin
      puts "... performing upgrade tasks ..."
      Rake::Task['seek:standard_upgrade_tasks'].invoke
      Rake::Task['seek:upgrade_version_tasks'].invoke

      Seek::Config.solr_enabled = solr
      puts "... queuing search reindexing jobs ..."
      Rake::Task['seek:reindex_all'].invoke if solr

      puts 'Upgrade completed successfully'
    ensure
      Seek::Config.solr_enabled = solr
    end
  end

  task(update_samples_json: :environment) do
    puts '... converting stored sample JSON ...'
    SampleType.all.each do |sample_type|

      # gather the attributes that need updating
      attributes_for_update = sample_type.sample_attributes.select do |attr|
        attr.accessor_name != attr.original_accessor_name
      end

      if attributes_for_update.any?
        # work through each sample
        sample_type.samples.each do |sample|
          json = JSON.parse(sample.json_metadata)
          attributes_for_update.each do |attr|
            # replace the json key
            json[attr.accessor_name] = json.delete(attr.original_accessor_name)
          end
          sample.update_column(:json_metadata,json.to_json)
        end

        # update the original accessor name for each affected attribute
        attributes_for_update.each do |attr|
          attr.update_column(:original_accessor_name, attr.accessor_name)
        end
      end
    end
    puts " ... finished updating sample JSON"
  end

  task(set_version_visibility: :environment) do
    puts "... Setting version visibility..."
    disable_authorization_checks do
      [DataFile::Version, Document::Version, Model::Version, Node::Version, Presentation::Version, Sop::Version, Workflow::Version].each do |klass|
        scope = klass.where(visibility: nil)
        count = scope.count
        if count == 0
          puts "  No #{klass.name} with unset visibility found, skipping"
          next
        else
          print "  Updating #{count} #{klass.name}'s visibility"
        end

        check_doi = klass.attribute_method?(:doi)
        # Go through all versions and set the "latest" versions to publicly visible
        scope.find_each do |version|
          if version.latest_version? || check_doi && version.doi.present?
            version.update_column(:visibility, Seek::ExplicitVersioning::VISIBILITY_INV[:public])
          else
            version.update_column(:visibility, Seek::ExplicitVersioning::VISIBILITY_INV[:registered_users])
          end
        end
        puts " - done"
      end
    end

    puts "... Done"
  end

  task(remove_old_project_join_logs: :environment) do
    puts "... Removing redundant project join request logs ..."
    logs = MessageLog.project_membership_requests
    logs.each do |log|
      begin
        JSON.parse(log.details)
      rescue JSON::ParserError
        log.destroy
      end
    end
    puts "... Done"
  end
end
