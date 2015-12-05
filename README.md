# Notice
A customisable tool for handling complex notices.  

## Use
```js
// from a jquery element
notice = $('#form1').notice({display_policy:'target'})
// by passing a jquery element
notice = new Notice($('#form1'), {display_policy:'header'})
// by passing a selecter
notice = new Notice('#form1')

// clear any previous notices (which don't exist at this point)
notice.clear()

// adding various notices
notice.add(['test this bob', {type:'error', message: 'weee', targets:['name']}, {type:'info', message: 'weee2', targets:['tags']}])

// remake the notice error class to use bootstrap
notice.make_notice_class = (function(notice){
	if(notice.type == 'error'){
		return 'alert alert-danger'
	}
}).bind(notice)


```
```html
<form id="form1">
	<div class="notice_header"></div>
	<input type="text" name="name"/>
	<input type="text" name="tags"/>
</form>
```

## Dependencies
-	[RegExp.quote](https://github.com/grithin/js_misc)
-	lodash
-	jquery

## Design Consideration
A notice contains a message, >=0 targets, and meta data
A notice can be displayed in a header area, or near its target.  Which is used is a policy of the Notice instance and special handling because:
-	the error return method generally does not care about the ui, and should not know about this policy
-	an error may not correspond to any field, and should therefore always appear in the header
-	a special field may require special highlighting, or special visual display of error

There should always be a header area for notices
This header should be identified with the class "notice_header"
The context of targets does not necessarily contain the notice header, since there may be a global header and a specific target context, so, the header is chosen based on
-	'.notice header' within context is used
-	the 'data-target_element' attribute value of a '.notice_header_pointer' classed element is used as the css selector to find the notice header
-	the first '.notice_header' on 'body' is used

With html, it makes sense that the targets are identified with css selectors
Since most message targets are form inputs with names, before a target is considered a css selector, it should be considered an input name

If the policy is near-target display, the particular location for the message still needs to be determined, and is so as follows:
-	target has attribute data-notice_target_element, which is used as a css selector
-	target element is contained in a ".target_container", and that parent element also contains a ".notice_container"
-	message is placed after the target element

It may be desired that highlights occur in some non-target element, perhaps a parent element.  Consequently, highlights are determined by:
-	target has a "data-highlight_target_element" attribute, which is used as a css selector
-	target has a parent of ".highlightable"
-	target is highlighted

A notice may include references to targets.  There are 2 types of references
-	single target references of '{{'target'}}'
-	multi-field reference of '{{targets}}'
The target display name is resolved according to:
-	target has data-display_name
-	target has parent of ".target_container" and a child within that parent of ".target_name"
-	target has a "name" attribute
