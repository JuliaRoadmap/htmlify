using Markdown
using Markdown:Paragraph,Header,Code,Footnote,BlockQuote,Admonition,List,HorizontalRule
using Markdown:Italic,Bold,Image,Link,LineBreak
using Markdown:Table
include("jlcode.jl")
function ify_md(s::String)
	s=replace(s,"\r"=>"")
	md=Markdown.parse(s)
	return ify(md.content)
end
function md_withtitle(s::String)
	s=replace(s,"\r"=>"")
	md=Markdown.parse(s)
	ti=md.content[1]
	typeassert(ti,Markdown.Header{1})
	con=""
	try
		con=ify(md.content)
	catch er
		buf=IOBuffer()
		showerror(buf,er)
		con="<p>ERROR: $(ify_s(String(take!(buf))))</p>"
	end
	return Pair(con,ti.text[1])
end
function ify_s(s::String)
	t=replace(s,"<"=>"&lt;")
	t=replace(t,">"=>"&gt;")
	return replace(t,"\""=>"&quot;")
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
		return "<pre class=\"language-julia\">$(jlcode(co))</pre>"
	else
		return "<pre class=\"language-$la\">$(replace(co,"\n"=>"<br />"))</pre>"
	end
end
function ify(f::Footnote)
	if f.text === nothing
		return "<sup><a href=\"#footnote-$(f.id)\">$(f.id)</a></sup>"
	else
		return "<p id=\"footnote-$(f.id)\">$(f.id)</p>"*ify(f.text)
	end
end
function ify(b::BlockQuote)
	return "<blockquote>$(ify(b.content))</blockquote>"
end
function ify(a::Admonition)
	cat=a.category
	title=a.title
	if cat=="note"
		cat="info"
		title=="" && title="关于"
	elseif cat=="warn"
		cat="warning"
		title=="" && title="注意"
	end
	"<div class=\"admonition is-$cat\"><header class=\"admonition-header\">$title</header><div class=\"admonition-content\">$(ify(a.content))</div></div>"
end
function ify(l::List)
	if l.ordered==-1
		s="<ul>"
		for el in l.items
			s*="<li>$(ify(el))</li>"
		end
		return s*"</ul>"
	else
		s="<ol>"
		for el in l.items
			s*="<li>$(ify(el))</li>"
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
	if startswith(url,"#")
		return "<a href=\"$url\">$htm</a>"
	end
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
	return "<a href=\"$(url)\" target=\"_blank\">$htm</a>"
end
ify(::LineBreak)="<br />"
# table
function ify(t::Table)
	s="<table>"
	fi=true
	for v in t.rows
		s*="<tr>"
		if fi
			fi=false
			for st in v
				s*="<th>$(ify(st))</th>"
			end
		else
			for st in v
				s*="<td>$(ify(st))</td>"
			end
		end
		s*="</tr>"
	end
	return s*"</table>"
end
