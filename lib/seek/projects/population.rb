module Seek
  module Projects
    module Population

      def populate_from_spreadsheet_impl
        datafile = DataFile.find(params[:spreadsheet_id])
        csv = nil;
        if (datafile.contains_extractable_spreadsheet?)
          spreadsheet = datafile.spreadsheet
          csv = CSV.new (spreadsheet.to_csv)
        else
          csv = CSV.new(datafile.content_blob.data_io_object, :headers => true)
        end

        rows = csv.read

        # if investigation_index.nil? || study_index.nil? || assay_index.nil? || assignee_indices.empty?
        #   flash[:notice]= 'indices missing'
        # end

        @investigation = nil
        @study = nil
        @assay = nil

        @investigation_position = 1
        @study_position = 1
        @assay_position = 1

        rows.each do |r|

          if (title = r.fetch "Investigation")
            title = title.strip
            @investigation = @project.investigations.select { |i| i.title == title }.first
            if @investigation.nil?
              @investigation = Investigation.new(title: title, projects: [@project])
            end
            @investigation.position = @investigation_position
            @investigation_position += 1
            @study_position = 1
            @study = nil
            @assay = nil
            @assay_position = 1
            @investigation.save!
          end

          if (title = r.fetch "Study")
            @title = title.strip
            @study = nil
            @investigation.studies.each do |s|
              if s.title == @title
                @study = s
                break
              end
            end
            if @study.nil?
              @study = Study.new(title: @title, investigation: @investigation)
            end
            @study.position = @study_position
            @study_position += 1
            @assay = nil
            @assay_position = 1
            @study.save!
          end

          if (title = r.fetch "Assay")
            title = title.strip
            @assay = Assay.find_by title: title, study: @study
            if @assay.nil?
              @assay = Assay.new(title: title, study: @study)
            end
            @assay.position = @assay_position
            @assay_position += 1
            @assay.assay_class = AssayClass.for_type('experimental')
            # assignees = []
            # assignee_indices.each do |x|
            #   unless r.cell(x).nil?
            #     assignees += r.cell(x).value.split(';')
            #   end
            # end
            # known_creators = []
            # other_creators = []
            # assignees.each do |a|
            #   creator = Person.find_by email: a
            #   if creator.nil?
            #     other_creators += [a]
            #   else
            #     known_creators += [creator]
            #   end
            # end
            # @assay.creators = known_creators
            # @assay.other_creators = other_creators.join(';')
            # unless r.cell(protocol_index).nil?
            #   protocol_string = r.cell(protocol_index).value.to_s.strip
            #   protocol_id = protocol_string.split(/\//)[-1].to_i
            #   if protocol_string.starts_with?(Seek::Config.site_base_host)
            #     protocol = @project.sops.select { |p| p.id == protocol_id }.first
            #     unless protocol.nil?
            #       @assay.sops = [protocol]
            #     end
            #   end
            # end
            @assay.save!
          end
        end

      end


    end
  end

end
