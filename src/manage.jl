using TOML
include("tohtml.jl")
mutable struct Node
	par::Union{Node,Nothing}
	name::String
	toml::Dict
	dirs::Dict{String,Pair{Node,String}}
	files::Dict{String,Pair{String,String}} # mds,title
end
Node(par::Union{Node,Nothing},name::String,toml::Dict=Dict())=Node(par,name,toml,Dict{String,Pair{Node,String}}(),Dict{String,Pair{String,String}}())
function generate_recursively(srcdir::AbstractString,tardir::AbstractString)
	endswith(srcdir,"/") || srcdir*="/"
	endswith(tardir,"/") || tardir*="/"
	# 复制
	cd(@__DIR__)
	cd("../")
	cp("css/dark.css",tardir*"css/dark.css")
	cp("css/light.css",tardir*"css/light.css")
	cp("img/logo.png",tardir*"img/logo.png")
	cp("js/main.js",tardir*"js/main.js")
	cd(srcdir)
	cp("svg",tardir*"svg")
	# docs
	root=Node(nothing,"")
	cd(srcdir*"docs")
	_gen_rec(;current=root,outline=true,path="",pathv=[""],srcdir=srcdir*"docs/",tardir=tardir*"docs/")
	# menu
	io=open(tardir*"js/menu.js")
	print(io,"const menu=`",makemenu(root),"`")
	close(io)
end
function _gen_rec(;
	current::Node,
	outline::Bool,
	path::String,
	pathv::Vector{String},
	srcdir::String,
	tardir::String,)
	# 准备
	mkpath(tardir*path)
	# TOML
	toml=TOML.tryparsefile("setting.toml")
	current.toml = isa(toml,Dict) ? toml : Dict()
	# 遍历
	vec=readdir(".";sort=false)
	for it in vec
		if it=="setting.toml"
			continue
		elseif isfile(it)
			flag=true
			dot=findlast(it,'.')
			pre=it[1:dot-1]
			suf=it[dot+1:end]
			io=open(spath*it,"r")
			if suf=="md"
				pair=md_withtitle(read(io,String))
			else
				cp(spath*it,tardir*path*it)
				flag=false
			end
			close(io)
			if flag
				current.files[pre]=pair
			end
		else # isdir
			node=Node(current,it)
			current.dirs[it]=Pair(node,current.toml["names"][it])
			push!(pathv,it)
			cd("it")
			o=outline || (haskey(toml,"outline") && in(it,@inbounds(toml["outline"])))
			_gen_rec(current=node,outline=o,path="$(path)$(it)/",pathv=pathv,srcdir=srcdir,tardir=tardir)
		end
	end
	# 生成文件
	for pa in current.files
		const repo="https://github.com/JuliaRoadmap/zh/"
		name=pa.first
		title=pa.second.second
		prevpage=""
		nextpage=""
		if ouline && haskey(toml,"outline")
			vec=@inbounds toml["outline"]
			len=length(vec)
			for i in 1:len
				if i==name
					if i!=1
						previd=@inbounds(vec[i-1])
						ptitle=current.files[previd].second
						prevpage="<a class=\"docs-footer-prevpage\" href=\"../$previd\">« $ptitle</a>"
					else
						prevpage="<a class=\"docs-footer-prevpage\" href=\"../index\">« 索引</a>"
					end
					if i!=len
						nextid=@inbounds vec[i+1]
						ptitle=current.files[nextid].second
						nextpage="<a class=\"docs-footer-nextpage\" href=\"../$nextid\">$ntitle »</a>"
					end
				end
			end
		else
			prevpage="<a class=\"docs-footer-prevpage\" href=\"../index\">« 索引</a>"
		end
		html=makehtml(
			editpath=repo*path*pa.second,
			mds=pa.second.first,
			navbar_title="$(current.name) / $title",
			nextpage=nextpage,
			prevpage=prevpage,
			title=title,
			tURL="../"^length(pathv))
		io=open(pa.first,"w")
		print(io,html)
		close(io)
	end
	io=open("index","w")
	print(io,makeindexhtml(current))
	close(io)
	# 消除影响
	current=current.par
	path=path[1:end-1-length(last(pathv))]
	pop!(pathv)
	cd("..")
end
