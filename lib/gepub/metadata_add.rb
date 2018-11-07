module GEPUB
	class Metadata
    CONTENT_NODE_LIST = ['identifier', 'title', 'language', 'contributor', 'creator', 'coverage', 'date','description','format','publisher','relation','rights','source','subject','type'].each {
      |node|
      define_method(node + '_list') { @content_nodes[node].dup.sort_as_meta }
      define_method(node + '_clear') {
        if !@content_nodes[node].nil?
          @content_nodes[node].each { |x| unregister_meta(x) };
          @content_nodes[node] = []
        end
      }

      next if node == 'title'

      define_method(node, ->(content=UNASSIGNED, deprecated_id=nil, id:nil,
                             title_type: nil,identifier_type: nil,display_seq: nil,file_as: nil,group_position: nil,role: nil,
														 lang: nil, alternates: {}) {
                      if unassigned?(content)
                        get_first_node(node)
                      else
                        if deprecated_id
                          warn "secound argument is deprecated. use id: keyword argument"
                          id = deprecated_id
                        end
                        send(node + "_clear")
                        add_metadata(node, content, id: id, title_type: title_type,identifier_type: identifier_type,display_seq: display_seq,file_as: file_as,group_position: group_position,role: role, lang: lang, alternates: alternates)
                      end
                    })
      
      define_method(node+'=') {
        |content|
        send(node + "_clear")
        return if content.nil?
        if node == 'date'
          add_date(content)
        else
          add_metadata(node, content)
        end
      }

      next if ["identifier", "date", "creator", "contributor"].include?(node)

      define_method('add_' + node) {
        |content, id|
        add_metadata(node, content, id: id)
      }
    }

    def add_title(content, deprecated_id = nil, deprecated_title_type = nil, id: nil,
                  title_type: nil,identifier_type: nil,display_seq: nil,file_as: nil,group_position: nil,role: nil,
									lang: nil, alternates: {})
      if deprecated_id
        warn 'second argument for add_title is deprecated. use id: instead'
        id = deprecated_id
      end
      if deprecated_title_type
        warn 'third argument for add_title is deprecated. use title_type: instead'
        title_type = deprecated_title_type
      end
      meta = add_metadata('title', content, id: id, 
			                    title_type: title_type,identifier_type: identifier_type,display_seq: display_seq,file_as: file_as,group_position: group_position,role: role,
													lang: lang, alternates: alternates)
      yield meta if block_given?
      meta
    end

    def add_person(name, content, deprecated_id = nil, deprecated_role = nil, id: nil,
                  title_type: nil,identifier_type: nil,display_seq: nil,file_as: nil,group_position: nil,role: nil,
									lang: nil, alternates: {})
      if deprecated_id
        warn 'second argument for add_person is deprecated. use id: instead'
        id = deprecated_id
      end
      if deprecated_role
        warn 'third argument for add_person is deprecated. use role: instead'
        role = deprecated_role
      end
      meta = add_metadata(name, content, id: id,
			                    title_type: title_type,identifier_type: identifier_type,display_seq: display_seq,file_as: file_as,group_position: group_position,role: role,
													lang: lang, alternates: alternates)
      yield meta if block_given?
      meta
    end

    def add_creator(content, deprecated_id = nil, deprecated_role = nil, id: nil, 
                    title_type: nil,identifier_type: nil,display_seq: nil,file_as: nil,group_position: nil,role: nil,
  									lang: nil, alternates: {}) 
      if deprecated_id
        warn 'second argument for add_creator is deprecated. use id: instead'
        id = deprecated_id
      end
      if deprecated_role
        warn 'third argument for add_creator is deprecated. use role: instead'
        role = deprecated_role
      end
			role = 'aut' if role.nil?
      meta = add_person('creator', content, id: id,
			                    title_type: title_type,identifier_type: identifier_type,display_seq: display_seq,file_as: file_as,group_position: group_position,role: role,
													lang: lang, alternates: alternates)
      yield meta if block_given?
      meta
    end

    def add_contributor(content, deprecated_id = nil, deprecated_role = nil, id: nil,
                        title_type: nil,identifier_type: nil,display_seq: nil,file_as: nil,group_position: nil,role: nil,
											  lang: nil, alternates: {}) 
      if deprecated_id
        warn 'second argument for add_contributor is deprecated. use id: instead'
        id = deprecated_id
      end
      if deprecated_role
        warn 'third argument for add_contributor is deprecated. use role: instead'
        role = deprecated_role
      end
      meta = add_person('contributor', content, id: id, 
			                  title_type: title_type,identifier_type: identifier_type,display_seq: display_seq,file_as: file_as,group_position: group_position,role: role,
												lang: lang, alternates: alternates)
      yield meta if block_given?
      meta
    end

		def add_metadata(name, content, id: nil, itemclass: Meta,
		title_type: nil,identifier_type: nil,display_seq: nil,file_as: nil,group_position: nil,role: nil,
		lang: nil, alternates: {}
		)
			meta = add_metadata_internal(name, content, id: id, itemclass: itemclass)
      [{ value: title_type, name: 'title-type'},{ value: identifier_type, name: 'identifier-type'},{ value: display_seq, name: 'display-seq'},{ value: file_as, name: 'file-as'},{ value: group_position, name: 'group-position'},{ value: role, name: 'role'}].each do |refiner|
				if refiner[:value]
				  meta.refine(refiner[:name], refiner[:value])
				end
	    end	
			if lang
			  meta.lang = lang
			end
			if alternates
			  meta.add_alternates alternates
			end
      yield meta if block_given?
			meta
		end
	end
end
