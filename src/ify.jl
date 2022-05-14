using Markdown:parse
using Markdown:Paragraph,Header,Code,Footnote,BlockQuote,Admonition,List,HorizontalRule
using Markdown:Italic,Bold,Image,Link,LineBreak
function ify_md(s::String)
	md=Markdown.parse(s)
	return ify(md.content)
end
function ify_s(s::String)
	t=replace(s,"<"=>"&lt;")
	replace!(t,">"=>"&gt;")
	replace!(t,"\""=>"&quot;")
	return t
end
# global
ify(s::String)="<p>$(ify_s(s))</p>"
function ify(content::Vector)
	s=""
	for el in content
		s*=ify(el)
	end
	return s
end
# block
function ify(p::Paragraph)
	return ify(p.content)
end
function ify(h::Header)
	lv=typeof(h).parameters[1]
	return "<h$lv>$(h.text[1])</h$lv>"
end
function ify(c::Code)
	la=c.language
	co=c.code
	if la=="" # 推测为行内
		return "<code>$co</code>"
	elseif la=="jl"
	else
		return "<pre class=\"language-$la\">$(replace(co,"\n"=>"<br />"))</pre>"
	end
end
function ify(f::Footnote)
	if f.text === nothing
		return "<sup><a href=\"#footnote-$(f.id)\">$(f.id)</a></sup>"
	else
		return "<p id=\"footnote-$(f.id)\">$(f.id)</p>"*ify(p.text)
	end
end
function ify(b::BlockQuote)
	return "<blockquote>$(ify(b))</blockquote>"
end
ify(a::Admonition)="<div class=\"admonition $(a.category)\"><p class=\"admonition-title\">$(ify_s(a.title))</p><p>$(ify(a.content))</p></div>"
function ify(l::List)
	if l.ordered==-1
		s="<ul>"
		for el in l.items
			s*=ify(el)
		end
		return s*"</ul>"
	else
		s="<ol>"
		for el in l.items
			s*=ify(el)
		end
		return s*"</ol>"
	end
end
ify(::HorizontalRule)="<hr />"
# inline
ify(b::Bold)="<strong>$(ify_s(b.text[1]))</strong>"
ify(i::Italic)="<em>$(ify_s(i.text[1]))</em>"
ify(i::Image)="<img src=\"$(i.url)\" alt=\"$(i.alt)\" />"
function ify(l::Link)
	htm=ify(l.text)
	url=l.url
	# 特殊处理
	if !startswith(url,"https://")
		ma=findfirst(r".md(#.*)?$",url)
		if ma!==nothing
			url=url[1:ma.stop-1]
		end
		ma=findfirst(r".txt$",url)
		if ma!==nothing
			url=url[1:ma.stop-1]
		end
	end
	return "<a href=\"$(url)\">$htm</a>"
end
ify(::LineBreak)="<br />"
