const keywords=[
	"end","if","for","else","elseif","function","return","while","using","try","catch",
	"const","struct","mutable","abstract","type","begin","macro","do","break","continue","finally","where","module","import","global","export","local","quote","let",
	"baremodule","primitive"
]
const specials=[
	"true","false","nothing","missing"
]
function col(content::String,co::String;br=true)
	if content=="" return "" end
	t=replace(content,"<"=>"&lt;")
	t=replace(t,">"=>"&gt;")
	return "<span class=\"$co\">$(br ? replace(t,"\n"=>"<br />") : t)</span>"
end
#= todo:
* 长转义
* 末尾处理
* 正则表达式
=#
function jlcode(co::String)
	co=replace(co,"\r"=>"")
	repl=false
	s=""
	stack=Vector{UInt8}()
	#=
	0	$(
	1	"
	2	`
	3	"""
	=#
	len=length(co)
	pre=1
	i=1
	emp=false
	dealf=(to::Int=i-1)->begin
		s*=col(co[pre:to],emp ? "plain" :
			last(stack)==0x0 ? "insert" : "string"
		)
	end
	try

	while i<=len
		ch=co[i]
		emp=isempty(stack)
		emp2=emp || last(stack)==0x0
		if emp && (ch=='\n' || i==1) # REPL特殊处理尝试
			if ch=='\n' i+=1 end
			if findnext("julia> ",co,i)!==nothing
				dealf()
				s*=col("julia> ","repl-code")
				repl=true
				i+=7
				pre=i
			elseif findnext("help?> ",co,i)!==nothing
				dealf()
				s*=col("help?> ","repl-help")
				i+=7
				pre=i
			elseif findnext("shell> ",co,i)!==nothing
				dealf()
				s*=col("shell> ","repl-shell")
				i+=7
				pre=i
			else
				f=findnext(r"\(@v[0-9]*\.[0-9]*\) pkg> ",co,i)
				if f!==nothing
					dealf()
					s*=col(co[f],"repl-pkg")
					i=f.stop+1
					pre=i
				elseif repl && findnext("ERROR:",co,i)!==nothing # "caused by:"
					dealf()
					s*=col("ERROR:","repl-error")
					i+=6
					pre=i
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
					break
				end
				j+=1
			end
			str=co[i:j-1]
			if in(str,keywords)
				dealf()
				s*=col(str,"keyword")
			elseif in(str,specials) || (repl && str=="ans")
				dealf()
				s*=col(str,"special")
			elseif j>len
				s*=col(co[pre:len],"plain")
				break
			elseif co[j]=='('
				dealf()
				s*=col(str,"function")
			else
				s*=col(co[pre:j-1],"plain")
			end
			i=j
			pre=j
		elseif emp2 && 'A'<=ch<='Z' # 推测是类型
			dealf()
			j=i+1
			st=0
			while j<=len
				if co[j]=='{' st+=1
				elseif co[j]=='}'
					st==0 ? break : st-=1
				elseif !Base.is_id_char(co[j])
					break
				end
				j+=1
			end
			if j>len
				s*=col(co[i:len],"type")
				break
			else
				s*=col(co[i:j-1],"type")
				i=j
				pre=j
			end
		elseif ch=='\"'
			la=last(stack)
			if emp || la==0x0 # 新字符串
				dealf()
				if co[i+1]=='"'
					if i+1==len # 末尾&空
						s*=col("\"\"","string")
						break
					elseif co[i+2]!='"' # 空字符串
						s*=col("\"\"","string")
						i+=2
						continue
					end
					# 多行字符串
					push!(stack,0x3)
					i+=3
				else
					push!(stack,0x1)
					i+=1
				end
			elseif la==0x1
				if i==len # 末尾
					s*=col(co[pre:len],"string")
					break
				else
					s*=col(co[pre:i],"string")
					i+=1
					pre=i
					pop!(stack)
				end
			elseif la==0x3
				if i>len-2 break end
				if co[i+1]=='"' && co[i+2]=='"'
					s*=col(co[pre:i+2],"string")
					i+=3
					pre=i
					pop!(stack)
				else
					i+=1
				end
			elseif la==0x2
				i+=1
			end
		elseif emp2 && ch=='\''
			dealf()
			if j>len-2 break end
			if ch[i+1]=='\\'
				s*=col(co[i:i+3],"string")
				i+=4
			else
				s*=col(co[i:i+2],"string")
				i+=3
			end
			pre=i
		elseif !emp2 && ch=='\\'
			dealf()
			s*=col(co[i:i+1],"escape")
			i+=2
			pre=i
		elseif ch=='$'
			j=i+1
			if ch[j]=='('
				dealf()
				pre=i
				push!(stack,0x0)
				i+=2
			elseif Base.is_id_start_char(ch[j])
				j+=1
				while j<=len
					if Base.is_id_char(ch[j])
						j+=1
					else
						break
					end
				end
				if j>len
					s*=col(co[i:len],"insert")
					break
				else
					s*=col(co[i:j-1],"insert")
					i=j
					pre=j
				end
			else
				i+=1
			end
		elseif emp2 && ch=='@'
			j=i+1
			if Base.is_id_start_char(ch[j])
				j+=1
				while j<=len
					if Base.is_id_char(ch[j])
						j+=1
					else
						break
					end
				end
				if j>len
					s*=col(co[i:len],"macro")
					break
				else
					s*=col(co[i:j-1],"macro")
					i=j
					pre=j
				end
			else
				i+=1
			end
		elseif emp2 && ch=='`'
			if emp || last(stack)!=0x2
				dealf()
				push!(stack,0x2)
			else
				s*=col(co[pre:i],"string")
				pop!(stack)
			end
			i+=1
			pre=i
		elseif emp2 && '0'<=ch<='9' # 推测是数字
			dealf()
			j=i+1
			if j!=len && (co[j]=='x' || co[j]=='o') j+=1 end
			while j<=len
				if '0'<=co[j]<='9' || 'a'<=co[j]<='f' || co[j]=='_'
					j+=1
				else
					break
				end
			end
			if j>len
				s*=col(co[i:len],"number")
				break
			else
				s*=col(co[i:j-1],"number")
				i=j
				pre=j
			end
		elseif emp2 && ch=='#'
			dealf()
			if i==len
				s*=col("#","comment")
				break
			elseif co[i+1]=='=' # 多行注释
				f=findnext("=#",co,i+2)
				if f===nothing s*=col(co[i:end],"comment")
				else
					s*=col(co[i:f.stop],"comment")
					i=f.stop+1
				end
			else
				f=findnext("\n",co,i+1)
				if f===nothing
					s*=col(co[i:end],"comment")
					break
				else
					s*=col(co[i:f.stop-1];br=false)
					s*="<br />"
					i=f.stop+1
				end
			end
			pre=i
		elseif !emp2 && ch==')'
			s*=col(co[pre:i],"insert")
			i+=1
			pre=i
			pop!(stack)
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
