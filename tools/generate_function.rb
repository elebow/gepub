require_relative '../lib/gepub/item.rb'
attrs = GEPUB::Item::ATTRIBUTES.select do |attr|
  attr != 'href'
end.map do |attr|
  attr.sub('-', '_')
end
attrs << "toc_text"
attrs << "property"
attrs_arguments_string = attrs.map { |attr| "#{attr}: nil" }.join(',')
attrs_internal_string = "{ " + attrs.map { |attr| "#{attr}: #{attr}"}.join(',') + " }"
File.write(File.join(File.dirname(__FILE__), "../lib/gepub/book_add_item.rb"), <<EOF)
module GEPUB
  class Book
    # add an item(i.e. html, images, audios, etc)  to Book.
    # the added item will be referenced by the first argument in the EPUB container.
    def add_item(href, deprecated_content = nil, deprecated_id = nil, deprecated_attributes = nil, content: nil, 
                 #{attrs_arguments_string},
                 attributes: {})
      content, id, attributes = handle_deprecated_add_item_arguments(deprecated_content, deprecated_id, deprecated_attributes, content, id, attributes)
      add_item_internal(href, content: content, item_attributes: #{attrs_internal_string}, attributes: attributes, ordered: false)
    end

    # same as add_item, but the item will be added to spine of the EPUB.
    def add_ordered_item(href, deprecated_content = nil, deprecated_id = nil, deprecated_attributes = nil,  content:nil,
                         #{attrs_arguments_string},
                         attributes: {})
      content, id, attributes = handle_deprecated_add_item_arguments(deprecated_content, deprecated_id, deprecated_attributes, content, id, attributes)
      add_item_internal(href, content: content, item_attributes: #{attrs_internal_string}, attributes: attributes, ordered: true)
    end
  end
end
EOF

require_relative '../lib/gepub/dsl_util.rb'
require_relative '../lib/gepub/meta.rb'

refiners = GEPUB::Meta::REFINERS.map do |refiner|
	refiner.sub('-', '_')
end

refiners_arguments_string = refiners.map { |refiner| "#{refiner}: nil" }.join(',')
refiners_arguments_set_string = refiners.map { |refiner| "#{refiner}: #{refiner}" }.join(',')
refiners_string = "[" + GEPUB::Meta::REFINERS.map { |refiner| "{ value: #{refiner.sub('-', '_')}, name: '#{refiner}'}" }.join(",") + "]"

meta_attr_arguments_string = "lang: nil, alternates: {}"
meta_attr_arguments_set_string = "lang: lang, alternates: alternates"

File.write(File.join(File.dirname(__FILE__), "../lib/gepub/metadata_add.rb"), <<EOF)
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
                             #{refiners_arguments_string},
														 #{meta_attr_arguments_string}) {
                      if unassigned?(content)
                        get_first_node(node)
                      else
                        if deprecated_id
                          warn "secound argument is deprecated. use id: keyword argument"
                          id = deprecated_id
                        end
                        send(node + "_clear")
                        add_metadata(node, content, id: id, #{refiners_arguments_set_string}, #{meta_attr_arguments_set_string})
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
                  #{refiners_arguments_string},
									#{meta_attr_arguments_string})
      if deprecated_id
        warn 'second argument for add_title is deprecated. use id: instead'
        id = deprecated_id
      end
      if deprecated_title_type
        warn 'third argument for add_title is deprecated. use title_type: instead'
        title_type = deprecated_title_type
      end
      meta = add_metadata('title', content, id: id, 
			                    #{refiners_arguments_set_string},
													#{meta_attr_arguments_set_string})
      yield meta if block_given?
      meta
    end

    def add_person(name, content, deprecated_id = nil, deprecated_role = nil, id: nil,
                  #{refiners_arguments_string},
									#{meta_attr_arguments_string})
      if deprecated_id
        warn 'second argument for add_person is deprecated. use id: instead'
        id = deprecated_id
      end
      if deprecated_role
        warn 'third argument for add_person is deprecated. use role: instead'
        role = deprecated_role
      end
      meta = add_metadata(name, content, id: id,
			                    #{refiners_arguments_set_string},
													#{meta_attr_arguments_set_string})
      yield meta if block_given?
      meta
    end

    def add_creator(content, deprecated_id = nil, deprecated_role = nil, id: nil, 
                    #{refiners_arguments_string},
  									#{meta_attr_arguments_string}) 
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
			                    #{refiners_arguments_set_string},
													#{meta_attr_arguments_set_string})
      yield meta if block_given?
      meta
    end

    def add_contributor(content, deprecated_id = nil, deprecated_role = nil, id: nil,
                        #{refiners_arguments_string},
											  #{meta_attr_arguments_string}) 
      if deprecated_id
        warn 'second argument for add_contributor is deprecated. use id: instead'
        id = deprecated_id
      end
      if deprecated_role
        warn 'third argument for add_contributor is deprecated. use role: instead'
        role = deprecated_role
      end
      meta = add_person('contributor', content, id: id, 
			                  #{refiners_arguments_set_string},
												#{meta_attr_arguments_set_string})
      yield meta if block_given?
      meta
    end

		def add_metadata(name, content, id: nil, itemclass: Meta,
		#{refiners_arguments_string},
		#{meta_attr_arguments_string}
		)
			meta = add_metadata_internal(name, content, id: id, itemclass: itemclass)
      #{refiners_string}.each do |refiner|
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
EOF

