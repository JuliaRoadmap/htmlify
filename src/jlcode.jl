const keywords=[
	"end","if","for","else","elseif","function","return","while","using","try","catch",
	"const","struct","mutable","abstract","type","begin","macro","do","break","continue","finally","where","module","import","global","export","local","quote","let",
	"baremodule","primitive"
]
const specials=[
	"true","false","nothing","missing"
]
function color!(s::String,content::String,co::String;br=true)
	if content=="" return end
	t=replace(content,"<"=>"&lt;")
	t=replace(t,">"=>"&gt;")
	s*="<span class=\"$co\">$(br ? replace(t,"\n"=>"<br />") : t)</span>"
end
function jlcode(co::String)
	co=replace(co,"\r"=>"")
	repl=false
	s=""
	stack=Vector{String}() # " """ ` $ $(
	len=length(co)
	pre=1
	i=1
	emp=false
	dealf=(to::Int)->begin
		color!(s,co[pre:to],emp ? "plain" :
			last(stack)[1]=='$' ? "insert" : "string"
		)
	end
	try

	while i<=len
		ch=co[i]
		emp=isempty(stack)
		emp2=emp || last(stack)[1]=='$'
		if emp && (ch=='\n' || i==1) # REPL特殊处理尝试
			if ch=='\n' i+=1 end
			if findnext("julia> ",co,i)!==nothing
				dealf(i-1)
				color!(s,"julia> ","repl-code")
				repl=true
				i+=7
			elseif findnext("help?> ",co,i)!==nothing
				dealf(i-1)
				color!(s,"help?> ","repl-help")
				i+=7
			elseif findnext("shell> ",co,i)!==nothing
				dealf(i-1)
				color!(s,"shell> ","repl-shell")
				i+=7
			else
				f=findnext(r"\(@v[0-9]*\.[0-9]*\) pkg> ",co,i)
				if f!==nothing
					color!(s,co[f],"repl-pkg")
					i=f.stop+1
					delaf(i-1)
				elseif repl && findnext("ERROR:",co,i) # "caused by:"
					dealf(i-1)
					color!(s,"ERROR:","repl-error")
					i+=6
				end
			end
		end
		while ch==' ' || ch=='\t'
			i+=1
			ch=co[i]
		end
		if emp2 && Base.is_id_start_char(ch) # 推测是变量等
			j=i+1
			while j<=len
				if !Base.is_id_char(co[j])
					return
				end
				j+=1
			end
			str=co[i:j-1]
			if j>len
				color!(s,co[pre:j-1],"plain")
				break
			elseif co[j]=='('
				color!(s,co[pre:i-1],"plain")
				color!(s,str,"function")
			elseif in(str,keywords)
				color!(s,co[pre:i-1],"plain")
				color!(s,str,"keyword")
			elseif in(str,specials) || (repl && str=="ans")
				color!(s,co[pre:i-1],"plain")
				color!(s,str,"special")
			else
				color!(s,co[pre:j-1],"plain")
			end
			i=j
			pre=j
		elseif 'A'<=ch<='Z' # 推测是类型
		elseif ch=='\"'
		elseif ch=='\''
		elseif ch=='\\'
			if emp2
				i+=1
			else
				# todo : \u ...
				dealf(i-1)
				color!(s,co[i:i+1],"escape")
				i+=2
				pre=i
			end
		elseif ch=='$'
		elseif ch=='@'
		elseif ch=='`'
		elseif '0'<=ch<='9' # 推测是数字
			dealf(i-1)
			j=i+1
			if j!=len && (co[j]=='x' || co[j]=='o') j+=1 end
			while j<=len
				if 0<=co[j]<=9 || 'a'<=co[j]<='f' || co[j]=='_'
					j+=1
				else
					break
				end
			end
			if j>len
				color!(s,co[i:len],"number")
				break
			else
				color!(s,co[i:j-1],"number")
				i=j
				pre=j
			end
		elseif ch=='#'
			dealf(i-1)
			if i==len
				color!(s,"#","comment")
				break
			elseif co[i+1]=='=' # 多行注释
				f=findnext("=#",co,i+2)
				if f===nothing color!(s,co[i:end],"comment")
				else
					color!(s,co[i:f.stop],"comment")
					i=f.stop+1
				end
			else
				f=findnext("\n",co,i+1)
				if f===nothing color!(s,co[i:end],"comment")
				else
					color!(s,co[i:f.stop-1];br=false)
					s*="<br />"
					i=f.stop+1
				end
			end
			pre=i
		else
			i+=1
		end
	end

	catch er
		if isa(er,BoundsError)
			dealf(len)
			return s
		else
			throw(er)
		end
	end
	return s
end
