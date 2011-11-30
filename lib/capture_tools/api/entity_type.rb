module CaptureTools::Api::EntityType
    # Entity Type management
    # DA
    def entity_type(arguments={})
      optional_arg(arguments, :remove_reserved)
      api_call(arguments, 'entityType')
    end

    # DA
    def entity_type_create(arguments={})
      required_arg(arguments, :attr_defs)
      api_call(arguments, 'entityType.create')
    end

    # DA
    def entity_type_add_attribute(arguments={})
      required_json_arg(arguments, :attr_def)
      api_call(arguments, 'entityType.addAttribute')
    end

    # DA
    def entity_type_remove_attribute(arguments={})
      required_arg(arguments, :attribute_name)
      api_call(arguments, 'entityType.removeAttribute')
    end

    # DA
    def entity_type_set_attribute_constraints(arguments={})
      required_arg(arguments, :attribute_name)
      required_json_arg(arguments, :constraints)
      api_call(arguments, 'entityType.setAttributeConstraints')
    end

    def entity_type_delete(arguments={})
      optional_arg(arguments, :pretend)
      api_call(arguments, 'entityType.delete')
    end

    # DA
    def entity_type_set_access_schema(arguments={})
      #TODO
    end

    def entity_type_list(arguments={})
      api_call(arguments, 'entityType.list')
    end
end
