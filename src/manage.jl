using TOML
const 缀="$(缀)"
include("tohtml.jl")
mutable struct Node
	par::Union{Node,Nothing}
	name::String
	toml::Dict
	dirs::Dict{String,Pair{Node,String}}
	files::Dict{String,Pair{String,String}} # mds,title
end
Node(par::Union{Node,Nothing},name::String,toml::Dict=Dict())=Node(par,name,toml,Dict{String,Pair{Node,String}}(),Dict{String,Pair{String,String}}())

const repo="https://github.com/JuliaRoadmap/zh/tree/master/"
function generate(srcdir::AbstractString,tardir::AbstractString)
	if !endswith(srcdir,"/")
		srcdir*="/"
	end
	if !endswith(tardir,"/")
		tardir*="/"
	end
	# 复制
	cd(@__DIR__)
	cd("..")
	cp("css",tardir*"css";force=true)
	cp("img",tardir*"img";force=true)
	cp("js",tardir*"js";force=true)
	cd(srcdir)
	cp("svg",tardir*"svg";force=true)
	# docs
	root=Node(nothing,"文档")
	cd(srcdir*"docs")
	_gen_rec(;current=root,outline=true,path="docs/",pathv=["docs"],srcdir=srcdir,tardir=tardir)
	# menu
	io=open(tardir*"js/menu.js","w")
	print(io,"const menu=`",makemenu(root;path="docs/"),"`")
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
	spath=srcdir*path
	tpath=tardir*path
	mkpath(tpath)
	# TOML
	vec=readdir(".";sort=false)
	toml = in("setting.toml",vec) ? TOML.parsefile("setting.toml") : Dict()
	current.toml=toml
	# 遍历
	for it in vec
		@info it
		if it=="setting.toml"
			continue
		elseif isfile(it)
			flag=true
			dot=findlast('.',it)
			pre=it[1:dot-1]
			suf=it[dot+1:end]
			io=open(spath*it,"r")
			if suf=="md"
				pair=md_withtitle(read(io,String))
			else
				cp(spath*it,tardir*path*it;force=true)
				flag=false
			end
			close(io)
			if flag
				current.files[pre]=pair
			end
		else # isdir
			if !haskey(current.toml,"names")
				@error "TOML: " path current.toml
				throw("KEY [NAMES] UNFOUND")
			end
			ns=@inbounds current.toml["names"]
			node=Node(current,it)
			current.dirs[it]=Pair(node,ns[it])
			push!(pathv,it)
			cd(it)
			o=outline || (haskey(toml,"outline") && in(it,@inbounds(toml["outline"])))
			_gen_rec(current=node,outline=o,path="$(path)$(it)/",pathv=pathv,srcdir=srcdir,tardir=tardir)
		end
	end
	# 生成文件
	for pa in current.files
		id=pa.first
		title=pa.second.second
		prevpage=""
		nextpage=""
		if outline && haskey(toml,"outline")
			vec=@inbounds toml["outline"]
			len=length(vec)
			for i in 1:len
				if vec[i]==id
					if i!=1
						previd=@inbounds(vec[i-1])
						ptitle=current.files[previd].second
						prevpage="<a class=\"docs-footer-prevpage\" href=\"$(previd)$(缀)\">« $ptitle</a>"
					else
						prevpage="<a class=\"docs-footer-prevpage\" href=\"index$(缀)\">« 索引</a>"
					end
					if i!=len
						nextid=@inbounds vec[i+1]
						ntitle=current.files[nextid].second
						nextpage="<a class=\"docs-footer-nextpage\" href=\"$(nextid)$(缀)\">$ntitle »</a>"
					end
				end
			end
		else
			prevpage="<a class=\"docs-footer-prevpage\" href=\"index$(缀)\">« 索引</a>"
		end
		html=makehtml(
			editpath=repo*path*id,
			mds=pa.second.first,
			navbar_title="$(current.par.dirs[current.name].second) / $title",
			nextpage=nextpage,
			prevpage=prevpage,
			title=title,
			tURL="../"^length(pathv))
		writehtml(tpath*pa.first,html)
	end
	writehtml(tpath*"index",makeindexhtml(current,path,pathv))
	# 消除影响
	current=current.par
	path=path[1:end-1-length(last(pathv))]
	pop!(pathv)
	cd("..")
end

function makemenu(rt::Node;path::String)
	html=""
	if haskey(rt.toml,"outline")
		outline=@inbounds rt.toml["outline"]
		for id in outline
			expath=path*id
			if haskey(rt.dirs,id)
				pair=@inbounds rt.dirs[id]
				html*="<li><a class=\"tocitem\" href=\"\$$(expath)/index$(缀)\">$(pair.second)</a><ul>$(makemenu(pair.first;path=expath*"/"))</ul><li>"
			else
				name=rt.files[id].second
				html*="<li><a class=\"tocitem\" href=\"\$$(expath)$(缀)\">$name</a></li>"
			end
		end
		return html
	end
end

function makeindexhtml(node::Node,path::String,pathv::Vector{String})
	mds="<ul>"
	for d in node.dirs
		mds*="<li><a href=\"$(d.first)/index$(缀)\" target=\"_blank\">$(d.second.second)/</a></li>"
	end
	for d in node.files
		mds*="<li><a href=\"$(d.first)$(缀)\">$(d.second.second)</a></li>"
	end
	mds*="</ul>"
	title = (node.par===nothing ? "主页" : node.par.dirs[node.name].second)*"索引"
	return makehtml(
		editpath=repo*path,
		mds=mds,
		navbar_title=title,
		nextpage="",
		prevpage="<a class=\"docs-footer-prevpage\" href=\"../index$(缀)\">« 上层索引</a>",
		title=title,
		tURL="../"^length(pathv))
end

function writehtml(path::String,html::String)
	io=open(path*缀,"w")
	print(io,html)
	close(io)
end
