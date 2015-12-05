###
@param	context	<anything wrappable in $()>
@param	options	{
	display_policy: <'header' or 'target'>,
	special_field_handlers: {<target_identifier>: <fn>, ...}
	default_type: <name of default notice type>
###
this.Notice = (context, options)->
	this.context = $(context)
	options = options || {}
	this.display_policy = options.display_policy || 'header'
	this.special_field_handlers = options.special_field_handlers
	this.default_type = 'error'

	this.find_notice_header = (context)=>
		this.context = context || this.context
		notice_header =  $('.notice_header', context)
		if !notice_header.size()
			notice_header_pointer =  $('.notice_header_pointer', context)
			if notice_header_pointer.size()
				selecter = notice_header_pointer.attr('data-target_element')
				notice_header = $(selecter)
			else
				notice_header = $('.notice_header')
			if !notice_header.size()
				notice_header = this.context
		notice_header

	this.notice_header = this.find_notice_header()
	if !this.notice_header.size()
		throw new Exception('No notice header found')

	# since a target may be a css selecter or a name, need to discover which
	this.resolve_target = (target)=>
		if target.match(/^[a-z0-9_\-.\[\]]+$/i)#< only match things that look like names
			element = $('[name="'+target+'"]')
			if element.size()
				return element
		return $(target)
	this.find_highlight_target = (target)=>
		selecter = target.attr('data-highlight_target_element')
		if selecter
			return $(selecter)
		else
			highlight_target = target.parents('.highlightable:first')
			if highlight_target.size()
				return highlight_target
			return target

	this.highlight = (notice)=>
		highlight_class = this.make_highlight_class(notice)
		for target, element of notice.highlight_elements
			element.addClass(highlight_class)
	this.unhighlight = (notice)=>
		highlight_class = this.make_highlight_class(notice)
		for target, element of notice.highlight_elements
			element.removeClass(highlight_class)
	this.make_highlight_class = (notice)->
		return notice.type + '_highlighted'

	this.target_reference_display_names = {}
	# resolve what a target's display name is
	this.target_display_name = (target, target_element)=>
		display_name = this.target_reference_display_names[target]
		if display_name
			return display_name

		display_name = target_element.attr('data-display_name')
		if !display_name
			container = target_element.parents('.target_container:first')
			if container.size()
				display_name = $('.display_name', container).text()
			if !display_name
				display_name = target_element.attr('name')
				if !display_name
					display_name = target

		this.target_reference_display_names[target] = display_name
		return display_name

	# parse message text to replace references (target reference in this case)
	this.make_notice_text = (notice)=>
		message = notice.message
		if notice.targets
			display_names = []
			for target, target_element of notice.target_elements
				display_name = this.target_display_name(target, target_element)
				display_names.push(display_name)

				# replace individual references
				pattern = new RegExp('\{\{' + RegExp.quote(target) + '\}\}', 'g')
				message = message.replace(pattern, display_name)

			# replace collective reference
			targets_reference = display_names.join(', ')
			message = message.replace(/\{\{targets\}\}/g, targets_reference)

		message

	this.make_notice_element = (notice)=>
		message = this.make_notice_text(notice)
		$('<div class="notice ' + this.make_notice_class(notice) + '">').text(message)

	# can be overwritten as desired (for instance, to use bootstrap classes)
	this.make_notice_class = (notice)->
		return notice.type + '_notice'

	this.notices = []
	this.add = (notice)=>
		if Array.isArray(notice)#< multiple passed, call individually
			for v in notice
				this.add(v)
		else if typeof(notice) == typeof({})
			notice = _.cloneDeep(notice) #< avoid altering passed data
			this.notices.push(notice)

			notice.type = notice.type || this.default_type
			notice.display_policy = notice.display_policy || this.display_policy

			if notice.targets
				# ensure targets is an array
				if !Array.isArray(notice.targets)
					notice.targets = [notice.targets]
				# resolve targets
				notice.target_elements = {}
				for target in notice.targets
					notice.target_elements[target] = this.resolve_target(target)

				# highlight
				notice.highlight_elements = {}
				for target, target_element of notice.target_elements
					highlight_element = this.find_highlight_target(target_element)
					notice.highlight_elements[target] = highlight_element
				this.highlight(notice)

			# message display
			notice.element = this.make_notice_element(notice)
			if notice.display_policy == 'header'
				this.add_to_header(notice)
			else
				this.add_to_target(notice)
		else if typeof(notice) == typeof('')#< lazy dev detected, reform correctly
			this.add({message: notice})
	this.add_to_header = (notice)=>
		this.notice_header.append(notice.element)
	this.add_to_target = (notice)=>
		if notice.targets
			for target in notice.targets
				notice.target_elements[target].after(notice.element)
		else
			this.add_to_header(notice)
	# make sure to compact this.notices afterwards
	this.remove = (offset)=>
		notice = this.notices[offset]
		this.unhighlight(notice)
		notice.element.remove()
		delete this.notices[offset]
	# clears any message that contains any of the  targets
	# if no targets, clears all
	this.clear = (targets)=>
		if !targets
			for notice, i in this.notices
				this.remove(i)
		else
			if typeof(targets) != typeof([])
				targets = [targets]

			for target in targets
				for notice, i in this.notices
					if notice.targets && notice.targets.indexOf(target) != -1
						this.remove(i)

		this.notices = _.compact(this.notices)

	# clears all messages of a specified type
	this.clear_type = (type)=>
		for notice, i in this.notices
			if notice.type == type
				this.remove(i)
		# might want to remake highlights (rare case of overlap)

	return this
if this.$
	$.fn.notice = (options)->
		return new Notice(this, options)