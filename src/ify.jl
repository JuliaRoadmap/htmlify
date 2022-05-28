using Markdown
using Markdown:Paragraph,Header,Code,Footnote,BlockQuote,Admonition,List,HorizontalRule
using Markdown:Italic,Bold,Image,Link,LineBreak
using Markdown:Table
using Markdown:LaTeX
include("jlcode.jl")
function ify_md(s::String)
	s=replace(s,"\r"=>"")
	md=Markdown.parse(s)
	return ify(md.content)
end
function md_withtitle(s::String)
	s=replace(s,"\r"=>"")
	md=Markdown.parse(s)
	if isempty(md.content)
		return Pair("<p></p>","未命名")
	end
	ti=md.content[1]
	typeassert(ti,Markdown.Header{1})
	con=""
	try
		con=ify(md.content)
	catch er
		@error er
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
	text=h.text[1]
	return "<h$lv id=\"header-$text\">$text</h$lv>"
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
		text=f.text[1].content[1]
		html= startswith(text,"https://") ? "<a href=\"$text\" target=\"_blank\">$text</a>" : ify(f.text)
		return "<br /><p id=\"footnote-$(f.id)\">$(f.id). </p>"*html
	end
end
function ify(b::BlockQuote)
	return "<blockquote>$(ify(b.content))</blockquote>"
end
function ify(a::Admonition)
	cat=a.category
	title=a.title
	if cat=="note" || cat=="tips"
		cat="info"
	elseif cat=="warn"
		cat="warning"
	end
	"<div class=\"admonition is-$cat\"><header class=\"admonition-header\">$title</header><div class=\"admonition-body\"><p>$(ify(a.content))</p></div></div>"
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
		return "<a href=\"#header-$(url[2:end])\">$htm</a>"
	end
	if !startswith(url,"https://")
		has=findlast('#',url)
		if has!==nothing
			ma=findfirst(r".md#.*$",url)
			if ma!==nothing
				url=url[1:ma.start-1]*缀*"#header-"*url[ma.start+4:ma.stop]
			else
				ma=findfirst(r".txt#.*$",url)
				if ma!==nothing
					url=url[1:ma.start-1]*缀*url[ma.start+4:ma.stop]
				end
			end
		else
			if findlast(".md",url)!==nothing
				url=url[1:sizeof(url)-3]*缀
			elseif findlast(".jl",url)!==nothing
				url=url[1:sizeof(url)-3]*缀
			elseif findlast(".txt",url)!==nothing
				url=url[1:sizeof(url)-4]*缀
			end
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
# latex
function ify(l::LaTeX)
	return "<p>$(l.formula)</p>"
end
