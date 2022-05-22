using TOML
include("tohtml.jl")
mutable struct Node
	par::Union{Node,Nothing}
	name::String
	toml::Dict
	dirs::Dict{String,Node}
	files::Dict{String,Pair{String,String}} # mds,title
end
Node(par::Union{Node,Nothing},name::String,toml::Dict=Dict())=Node(par,name,toml,Dict{String,Node}(),Dict{String,Pair{String,String}}())
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
	_gen_rec(;current=root,path="",pathv=[""],srcdir=srcdir*"docs/",tardir=tardir*"docs/")
end
function _gen_rec(;
	current::Node,
	path::String,
	pathv::Vector{String},
	srcdir::String,
	tardir::String)
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
				current.files[it]=pair
			end
		else # isdir
			node=Node(current,it)
			push!(pathv,it)
			cd("it")
			_gen_rec(current=node,path="$(path)$(it)/",pathv=pathv,srcdir=srcdir,tardir=tardir)
		end
	end
	# 生成文件
	for pa in current.files
	end
	io=open("index","w")
	# 消除影响
	pop!(pathv)
	cd("..")
end
