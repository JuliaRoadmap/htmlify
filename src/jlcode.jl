const keywords=[
	"end","if","for","else","elseif","function","return","while","using","try","catch",
	"const","struct","mutable struct","abstract type","begin","macro","do","break","continue","finally","where","module","import","global","export","local","quote","let",
	"baremodule","primitive type"
]
const specials=[
	"true","false","nothing","missing"
]
function color!(s::String,content::String,co::String)
	s*="<span class=\"$co\">$(ify_s(content))</span>"
end
function jlcode(c::String)
	v=split(co,'\n';keepempty=true)
	repl=false
	s=""
	pre=1
	incomment=false
	instring=false
	string3=false
	for l in v
		if incomment
			f=findfirst(l,"=#")
			if f===nothing
				color!(s,l,"comment")
				s*="<br />"
				continue
			else
				color!(s,l[1:f.stop],"comment")
				pre=f.stop+1
				incomment=false
			end
		elseif instring
			if string3
				f=findall(r"(?!\\)\"\"\"",l)
				if isempty(f)
					color!(s,l,"string")
				end
			end
		elseif startswith(l,"julia>")
			color!(s,"julia>","repl-code")
			repl=true
			pre=7
		elseif startswith(l,"help?>")
			color!(s,"help?>","repl-help")
		else
			if startswith(l,r"")
			else
				pre=1
			end
		end
		s*="<br />"
	end
end
